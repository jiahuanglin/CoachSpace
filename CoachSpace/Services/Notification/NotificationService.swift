import Foundation
import FirebaseFirestore
import FirebaseMessaging
import Combine

enum NotificationType: String, Codable {
    case classReminder
    case bookingUpdate
    case bookingConfirmed
    case bookingCancelled
    case bookingWaitlisted
    case message
    case promotion
    case achievement
    case skillLevelUpdate
    case systemAlert
}

struct NotificationPayload: Codable {
    let title: String
    let body: String
    let type: NotificationType
    let data: [String: String]
}

protocol NotificationServiceProtocol {
    func updateFCMToken(_ token: String, for userId: String) async throws
    func sendNotification(_ payload: NotificationPayload, to userIds: [String]) async throws
    func sendNotificationToTopic(_ payload: NotificationPayload, topic: String) async throws
    func subscribeToTopic(_ topic: String, userId: String) async throws
    func unsubscribeFromTopic(_ topic: String, userId: String) async throws
    func getNotificationHistory(for userId: String, limit: Int) async throws -> [NotificationHistory]
}

struct NotificationHistory: Identifiable, Codable {
    let id: String
    let userId: String
    let title: String
    let body: String
    let type: NotificationType
    let data: [String: String]
    let isRead: Bool
    let createdAt: Date
}

final class NotificationService: NotificationServiceProtocol {
    static let shared = NotificationService()
    private let db = Firestore.firestore()
    private let messaging = Messaging.messaging()
    
    private init() {
        setupNotificationHandlers()
        #if DEBUG
        FirebaseConfig.validateConfiguration()
        #endif
    }
    
    func updateFCMToken(_ token: String, for userId: String) async throws {
        do {
            try await db.collection("users").document(userId).updateData([
                "fcmToken": token,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        } catch {
            throw NotificationError.updateTokenFailed(error)
        }
    }
    
    func sendNotification(_ payload: NotificationPayload, to userIds: [String]) async throws {
        do {
            // Get FCM tokens for users
            let snapshot = try await db.collection("users")
                .whereField("id", in: userIds)
                .getDocuments()
            
            let tokens = snapshot.documents.compactMap { doc -> String? in
                guard let user = User.from(doc),
                      let token = user.fcmToken,
                      user.preferences.notifications.push else {
                    return nil
                }
                return token
            }
            
            // Send to FCM using HTTP v1 API
            for token in tokens {
                try await sendFCMMessage(
                    token: token,
                    title: payload.title,
                    body: payload.body,
                    data: payload.data
                )
            }
            
            // Store notification history
            let batch = db.batch()
            for userId in userIds {
                let notificationRef = db.collection("notifications").document()
                let notification = NotificationHistory(
                    id: notificationRef.documentID,
                    userId: userId,
                    title: payload.title,
                    body: payload.body,
                    type: payload.type,
                    data: payload.data,
                    isRead: false,
                    createdAt: Date()
                )
                batch.setData(try Firestore.Encoder().encode(notification), forDocument: notificationRef)
            }
            try await batch.commit()
            
        } catch {
            throw NotificationError.sendFailed(error)
        }
    }
    
    func sendNotificationToTopic(_ payload: NotificationPayload, topic: String) async throws {
        do {
            try await sendFCMMessage(
                topic: topic,
                title: payload.title,
                body: payload.body,
                data: payload.data
            )
        } catch {
            throw NotificationError.sendFailed(error)
        }
    }
    
    private func sendFCMMessage(
        token: String? = nil,
        topic: String? = nil,
        title: String,
        body: String,
        data: [String: String]
    ) async throws {
        guard let url = URL(string: FirebaseConfig.fcmApiUrl) else {
            throw NotificationError.invalidConfiguration("Invalid FCM API URL")
        }
        
        var message: [String: Any] = [
            "notification": [
                "title": title,
                "body": body
            ],
            "data": data
        ]
        
        if let token = token {
            message["token"] = token
        } else if let topic = topic {
            message["topic"] = topic
        }
        
        let payload: [String: Any] = ["message": message]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(FirebaseConfig.fcmServerKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NotificationError.sendFailed(NSError(domain: "", code: -1))
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw NotificationError.sendFailed(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message]))
            }
            throw NotificationError.sendFailed(NSError(domain: "", code: httpResponse.statusCode))
        }
        
        #if DEBUG
        if let responseJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("📬 FCM Response:", responseJson)
        }
        #endif
    }
    
    func subscribeToTopic(_ topic: String, userId: String) async throws {
        guard let user = try await UserService.shared.getUser(id: userId),
              let token = user.fcmToken else {
            throw NotificationError.userNotFound
        }
        
        try await messaging.subscribe(toTopic: topic)
    }
    
    func unsubscribeFromTopic(_ topic: String, userId: String) async throws {
        guard let user = try await UserService.shared.getUser(id: userId),
              let token = user.fcmToken else {
            throw NotificationError.userNotFound
        }
        
        try await messaging.unsubscribe(fromTopic: topic)
    }
    
    func getNotificationHistory(for userId: String, limit: Int = 50) async throws -> [NotificationHistory] {
        do {
            let snapshot = try await db.collection("notifications")
                .whereField("userId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            return try snapshot.documents.compactMap { doc in
                try doc.data(as: NotificationHistory.self)
            }
        } catch {
            throw NotificationError.fetchFailed(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationHandlers() {
        // Listen for FCM token updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFCMTokenRefresh(_:)),
            name: NotificationNames.FCMTokenRefreshed,
            object: nil
        )
        
        // Listen for various events that require notifications
        setupEventHandlers()
    }
    
    private func setupEventHandlers() {
        // Class booking notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClassBooked(_:)),
            name: NotificationNames.ClassBooked,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBookingStatusChanged(_:)),
            name: NotificationNames.BookingStatusChanged,
            object: nil
        )
        
        // Achievement notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAchievementAdded(_:)),
            name: NotificationNames.UserAchievementAdded,
            object: nil
        )
        
        // Skill level update notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSkillLevelUpdated(_:)),
            name: NotificationNames.UserSkillLevelUpdated,
            object: nil
        )
    }
    
    @objc private func handleFCMTokenRefresh(_ notification: Notification) {
        guard let token = notification.userInfo?["token"] as? String else { return }
        
        Task {
            if let userId = await AuthService.shared.getCurrentUser()?.id {
                try? await updateFCMToken(token, for: userId)
            }
        }
    }
    
    @objc private func handleClassBooked(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let classId = userInfo["classId"] as? String,
              let userId = userInfo["userId"] as? String else { return }
        
        Task {
            do {
                guard let classData = try await ClassService.shared.getClass(id: classId),
                      let user = try await UserService.shared.getUser(id: userId) else { return }
                
                let payload = NotificationPayload(
                    title: "Class Booking Confirmed",
                    body: "Your booking for \(classData.name) has been confirmed!",
                    type: .bookingUpdate,
                    data: [
                        "classId": classId,
                        "action": "booking_confirmed"
                    ]
                )
                
                try await sendNotification(payload, to: [userId])
            } catch {
                print("Failed to send class booking notification: \(error)")
            }
        }
    }
    
    @objc private func handleBookingStatusChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let classId = userInfo["classId"] as? String,
              let userId = userInfo["userId"] as? String,
              let status = userInfo["status"] as? String else { return }
        
        Task {
            do {
                guard let classData = try await ClassService.shared.getClass(id: classId),
                      let user = try await UserService.shared.getUser(id: userId) else { return }
                
                // Prepare notifications for both student and instructor
                var studentPayload: NotificationPayload
                var instructorPayload: NotificationPayload
                
                switch status {
                case "confirmed":
                    studentPayload = NotificationPayload(
                        title: "Booking Confirmed! 🎉",
                        body: "Your booking for \(classData.name) has been confirmed!",
                        type: .bookingConfirmed,
                        data: [
                            "classId": classId,
                            "action": "booking_confirmed"
                        ]
                    )
                    
                    instructorPayload = NotificationPayload(
                        title: "New Student Booked! 📚",
                        body: "\(user.displayName) has booked your class \(classData.name)",
                        type: .bookingConfirmed,
                        data: [
                            "classId": classId,
                            "studentId": userId,
                            "action": "student_booked"
                        ]
                    )
                    
                case "waitlisted":
                    studentPayload = NotificationPayload(
                        title: "Added to Waitlist ⏳",
                        body: "You've been added to the waitlist for \(classData.name)",
                        type: .bookingWaitlisted,
                        data: [
                            "classId": classId,
                            "action": "booking_waitlisted"
                        ]
                    )
                    
                    instructorPayload = NotificationPayload(
                        title: "New Waitlist Entry",
                        body: "\(user.displayName) is waitlisted for \(classData.name)",
                        type: .bookingWaitlisted,
                        data: [
                            "classId": classId,
                            "studentId": userId,
                            "action": "student_waitlisted"
                        ]
                    )
                    
                case "cancelled":
                    studentPayload = NotificationPayload(
                        title: "Booking Cancelled",
                        body: "Your booking for \(classData.name) has been cancelled",
                        type: .bookingCancelled,
                        data: [
                            "classId": classId,
                            "action": "booking_cancelled"
                        ]
                    )
                    
                    instructorPayload = NotificationPayload(
                        title: "Booking Cancelled",
                        body: "\(user.displayName) has cancelled their booking for \(classData.name)",
                        type: .bookingCancelled,
                        data: [
                            "classId": classId,
                            "studentId": userId,
                            "action": "student_cancelled"
                        ]
                    )
                    
                default:
                    return
                }
                
                // Send notifications
                try await sendNotification(studentPayload, to: [userId])
                try await sendNotification(instructorPayload, to: [classData.instructorId])
                
                #if DEBUG
                debugSendNotification(studentPayload, to: [userId])
                debugSendNotification(instructorPayload, to: [classData.instructorId])
                #endif
            } catch {
                print("Failed to send booking update notifications: \(error)")
            }
        }
    }
    
    @objc private func handleAchievementAdded(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let userId = userInfo["userId"] as? String,
              let achievement = userInfo["achievement"] as? User.UserStats.Achievement else { return }
        
        Task {
            do {
                let payload = NotificationPayload(
                    title: "New Achievement Unlocked! 🏆",
                    body: "Congratulations! You've earned the '\(achievement.title)' achievement!",
                    type: .achievement,
                    data: [
                        "achievementId": achievement.id,
                        "action": "achievement_unlocked"
                    ]
                )
                
                try await sendNotification(payload, to: [userId])
            } catch {
                print("Failed to send achievement notification: \(error)")
            }
        }
    }
    
    @objc private func handleSkillLevelUpdated(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let userId = userInfo["userId"] as? String,
              let skillLevel = userInfo["skillLevel"] as? User.UserStats.SkillLevel else { return }
        
        Task {
            do {
                let payload = NotificationPayload(
                    title: "Skill Level Updated! 🎯",
                    body: "Your \(skillLevel.category.rawValue) skill level has been updated to \(skillLevel.level.rawValue)!",
                    type: .skillLevelUpdate,
                    data: [
                        "category": skillLevel.category.rawValue,
                        "level": skillLevel.level.rawValue,
                        "action": "skill_level_updated"
                    ]
                )
                
                try await sendNotification(payload, to: [userId])
            } catch {
                print("Failed to send skill level update notification: \(error)")
            }
        }
    }
    
    #if DEBUG
    func debugSendNotification(_ payload: NotificationPayload, to userIds: [String]) {
        print("🔔 Debug Notification:")
        print("To Users:", userIds)
        print("Title:", payload.title)
        print("Body:", payload.body)
        print("Type:", payload.type)
        print("Data:", payload.data)
    }
    #endif
}

// MARK: - Errors

enum NotificationError: LocalizedError {
    case updateTokenFailed(Error)
    case sendFailed(Error)
    case fetchFailed(Error)
    case userNotFound
    case invalidConfiguration(String)
    
    var errorDescription: String? {
        switch self {
        case .updateTokenFailed(let error):
            return "Failed to update FCM token: \(error.localizedDescription)"
        case .sendFailed(let error):
            return "Failed to send notification: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch notifications: \(error.localizedDescription)"
        case .userNotFound:
            return "User not found or has no FCM token"
        case .invalidConfiguration(let reason):
            return "Invalid configuration: \(reason)"
        }
    }
} 