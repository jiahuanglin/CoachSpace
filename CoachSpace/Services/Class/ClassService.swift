import Foundation
import FirebaseFirestore
import Combine

protocol ClassServiceProtocol {
    func getClass(id: String) async throws -> Class?
    func createClass(_ class: Class) async throws
    func updateClass(_ class: Class) async throws
    func deleteClass(_ classId: String) async throws
    func getClasses(category: Class.Category?, level: Class.Level?, venue: String?) async throws -> [Class]
    func searchClasses(query: String) async throws -> [Class]
    func getUpcomingClasses(for userId: String) async throws -> [Class]
    func getPastClasses(for userId: String) async throws -> [Class]
    func getInstructorClasses(instructorId: String) async throws -> [Class]
    func getVenueClasses(venueId: String) async throws -> [Class]
    func bookClass(_ classId: String, userId: String) async throws
    func cancelBooking(classId: String, userId: String) async throws
    func getClassParticipants(classId: String) async throws -> [User]
    func addClassReview(classId: String, userId: String, rating: Int, comment: String) async throws
    func getClassReviews(classId: String) async throws -> [Review]
}

final class ClassService: ClassServiceProtocol {
    static let shared = ClassService()
    private let db = Firestore.firestore()
    private let storage = StorageService.shared
    
    private init() {}
    
    func getClass(id: String) async throws -> Class? {
        do {
            let doc = try await db.collection("classes").document(id).getDocument()
            return Class.from(doc)
        } catch {
            throw ClassError.fetchFailed(error)
        }
    }
    
    func createClass(_ class: Class) async throws {
        do {
            try await db.collection("classes").document(`class`.id).setData(`class`.toFirestore)
        } catch {
            throw ClassError.createFailed(error)
        }
    }
    
    func updateClass(_ class: Class) async throws {
        do {
            try await db.collection("classes").document(`class`.id).updateData(`class`.toFirestore)
        } catch {
            throw ClassError.updateFailed(error)
        }
    }
    
    func deleteClass(_ classId: String) async throws {
        do {
            try await db.collection("classes").document(classId).delete()
            
            if let classData = try await getClass(id: classId),
               !classData.imageURL.isEmpty {
                try await storage.deleteImage(at: classData.imageURL)
            }
            
            try await cleanupClassData(classId)
        } catch {
            throw ClassError.deleteFailed(error)
        }
    }
    
    func getClasses(category: Class.Category? = nil, level: Class.Level? = nil, venue: String? = nil) async throws -> [Class] {
        do {
            var query = db.collection("classes").order(by: "startTime")
            
            if let category = category {
                query = query.whereField("category", isEqualTo: category.rawValue)
            }
            if let level = level {
                query = query.whereField("level", isEqualTo: level.rawValue)
            }
            if let venue = venue {
                query = query.whereField("venueId", isEqualTo: venue)
            }
            
            let snapshot = try await query.getDocuments()
            return snapshot.documents.compactMap { Class.from($0) }
        } catch {
            throw ClassError.fetchFailed(error)
        }
    }
    
    func searchClasses(query: String) async throws -> [Class] {
        do {
            let snapshot = try await db.collection("classes")
                .whereField("name", isGreaterThanOrEqualTo: query)
                .whereField("name", isLessThanOrEqualTo: query + "\u{f8ff}")
                .getDocuments()
            return snapshot.documents.compactMap { Class.from($0) }
        } catch {
            throw ClassError.searchFailed(error)
        }
    }
    
    func getUpcomingClasses(for userId: String) async throws -> [Class] {
        do {
            print("🔍 [ClassService] Getting upcoming classes for user: \(userId)")
            
            let bookings = try await db.collection("bookings")
                .whereField("userId", isEqualTo: userId)
                .whereField("status", isEqualTo: Booking.BookingStatus.confirmed.rawValue)
                .getDocuments()
            
            print("📚 [ClassService] Found \(bookings.documents.count) confirmed bookings")
            
            let classIds = bookings.documents.compactMap { $0.data()["classId"] as? String }
            print("🎯 [ClassService] Class IDs from bookings: \(classIds)")
            
            let classes = try await getClassesById(classIds)
            let upcomingClasses = classes.filter { $0.startTime > Date() }
            
            print("📈 [ClassService] Found \(upcomingClasses.count) upcoming classes out of \(classes.count) total")
            upcomingClasses.forEach { classItem in
                print("   - Class: id=\(classItem.id), name=\(classItem.name), time=\(classItem.startTime)")
            }
            
            return upcomingClasses
        } catch {
            print("❌ [ClassService] Error getting upcoming classes: \(error.localizedDescription)")
            throw ClassError.fetchFailed(error)
        }
    }
    
    func getPastClasses(for userId: String) async throws -> [Class] {
        do {
            print("🔍 [ClassService] Getting past classes for user: \(userId)")
            
            let bookings = try await db.collection("bookings")
                .whereField("userId", isEqualTo: userId)
                .whereField("status", isEqualTo: Booking.BookingStatus.confirmed.rawValue)
                .getDocuments()
            
            print("📚 [ClassService] Found \(bookings.documents.count) confirmed bookings")
            
            let classIds = bookings.documents.compactMap { $0.data()["classId"] as? String }
            print("🎯 [ClassService] Class IDs from bookings: \(classIds)")
            
            let classes = try await getClassesById(classIds)
            let pastClasses = classes.filter { $0.startTime < Date() }
            
            print("📉 [ClassService] Found \(pastClasses.count) past classes out of \(classes.count) total")
            pastClasses.forEach { classItem in
                print("   - Class: id=\(classItem.id), name=\(classItem.name), time=\(classItem.startTime)")
            }
            
            return pastClasses
        } catch {
            print("❌ [ClassService] Error getting past classes: \(error.localizedDescription)")
            throw ClassError.fetchFailed(error)
        }
    }
    
    func getInstructorClasses(instructorId: String) async throws -> [Class] {
        do {
            let snapshot = try await db.collection("classes")
                .whereField("instructorId", isEqualTo: instructorId)
                .getDocuments()
            return snapshot.documents.compactMap { Class.from($0) }
        } catch {
            throw ClassError.fetchFailed(error)
        }
    }
    
    func getVenueClasses(venueId: String) async throws -> [Class] {
        do {
            let snapshot = try await db.collection("classes")
                .whereField("venueId", isEqualTo: venueId)
                .getDocuments()
            return snapshot.documents.compactMap { Class.from($0) }
        } catch {
            throw ClassError.fetchFailed(error)
        }
    }
    
    func bookClass(_ classId: String, userId: String) async throws {
        do {
            guard let classData = try await getClass(id: classId) else {
                throw ClassError.classNotFound
            }
            
            if !classData.isAvailable {
                throw ClassError.classFull
            }
            
            let booking = Booking(
                id: UUID().uuidString,
                classId: classId,
                userId: userId,
                status: .confirmed,
                createdAt: Date()
            )
            
            try await db.collection("bookings").document(booking.id).setData(booking.toFirestore)
            
            try await db.collection("classes").document(classId).updateData([
                "currentParticipants": FieldValue.increment(Int64(1))
            ])
            
            NotificationCenter.default.post(
                name: .ClassBooked,
                object: nil,
                userInfo: ["classId": classId, "userId": userId]
            )
        } catch {
            throw ClassError.bookingFailed(error)
        }
    }
    
    func cancelBooking(classId: String, userId: String) async throws {
        do {
            let bookings = try await db.collection("bookings")
                .whereField("classId", isEqualTo: classId)
                .whereField("userId", isEqualTo: userId)
                .whereField("status", isEqualTo: Booking.BookingStatus.confirmed.rawValue)
                .getDocuments()
            
            guard let booking = bookings.documents.first else {
                throw ClassError.bookingNotFound
            }
            
            try await booking.reference.delete()
            
            try await db.collection("classes").document(classId).updateData([
                "currentParticipants": FieldValue.increment(Int64(-1))
            ])
            
            NotificationCenter.default.post(
                name: .ClassCancelled,
                object: nil,
                userInfo: ["classId": classId, "userId": userId]
            )
        } catch {
            throw ClassError.cancellationFailed(error)
        }
    }
    
    func getClassParticipants(classId: String) async throws -> [User] {
        do {
            let bookings = try await db.collection("bookings")
                .whereField("classId", isEqualTo: classId)
                .whereField("status", isEqualTo: Booking.BookingStatus.confirmed.rawValue)
                .getDocuments()
            
            let userIds = bookings.documents.compactMap { $0.data()["userId"] as? String }
            return try await getUsersById(userIds)
        } catch {
            throw ClassError.fetchFailed(error)
        }
    }
    
    func addClassReview(classId: String, userId: String, rating: Int, comment: String) async throws {
        do {
            let review = Review(
                id: UUID().uuidString,
                classId: classId,
                userId: userId,
                rating: rating,
                comment: comment,
                createdAt: Date()
            )
            
            try await db.collection("reviews").document(review.id).setData(review.toFirestore)
            
            NotificationCenter.default.post(
                name: .ClassReviewAdded,
                object: nil,
                userInfo: ["classId": classId, "userId": userId, "review": review]
            )
        } catch {
            throw ClassError.reviewFailed(error)
        }
    }
    
    func getClassReviews(classId: String) async throws -> [Review] {
        do {
            let snapshot = try await db.collection("reviews")
                .whereField("classId", isEqualTo: classId)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            return snapshot.documents.compactMap { Review.from($0) }
        } catch {
            throw ClassError.fetchFailed(error)
        }
    }
    
    private func getClassesById(_ ids: [String]) async throws -> [Class] {
        print("🔍 [ClassService] Getting classes by IDs: \(ids)")
        
        guard !ids.isEmpty else {
            print("ℹ️ [ClassService] No class IDs provided")
            return []
        }
        
        do {
            let snapshot = try await db.collection("classes")
                .whereField(FieldPath.documentID(), in: ids)
                .getDocuments()
            
            let classes = snapshot.documents.compactMap { Class.from($0) }
            print("📚 [ClassService] Retrieved \(classes.count) classes")
            return classes
        } catch {
            print("❌ [ClassService] Error getting classes by IDs: \(error.localizedDescription)")
            throw ClassError.fetchFailed(error)
        }
    }
    
    private func getUsersById(_ ids: [String]) async throws -> [User] {
        var users: [User] = []
        for id in ids {
            if let user = try await UserService.shared.getUser(id: id) {
                users.append(user)
            }
        }
        return users
    }
    
    private func cleanupClassData(_ classId: String) async throws {
        let bookings = try await db.collection("bookings")
            .whereField("classId", isEqualTo: classId)
            .getDocuments()
        
        for booking in bookings.documents {
            try await booking.reference.delete()
        }
        
        let reviews = try await db.collection("reviews")
            .whereField("classId", isEqualTo: classId)
            .getDocuments()
        
        for review in reviews.documents {
            try await review.reference.delete()
        }
    }
}

// MARK: - Errors
enum ClassError: LocalizedError {
    case fetchFailed(Error)
    case createFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case bookingFailed(Error)
    case cancellationFailed(Error)
    case reviewFailed(Error)
    case searchFailed(Error)
    case classNotFound
    case bookingNotFound
    case classFull
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error): return "Failed to fetch class: \(error.localizedDescription)"
        case .createFailed(let error): return "Failed to create class: \(error.localizedDescription)"
        case .updateFailed(let error): return "Failed to update class: \(error.localizedDescription)"
        case .deleteFailed(let error): return "Failed to delete class: \(error.localizedDescription)"
        case .bookingFailed(let error): return "Failed to book class: \(error.localizedDescription)"
        case .cancellationFailed(let error): return "Failed to cancel booking: \(error.localizedDescription)"
        case .reviewFailed(let error): return "Failed to add review: \(error.localizedDescription)"
        case .searchFailed(let error): return "Failed to search classes: \(error.localizedDescription)"
        case .classNotFound: return "Class not found"
        case .bookingNotFound: return "Booking not found"
        case .classFull: return "Class is full"
        }
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let ClassBooked = Notification.Name("ClassBooked")
    static let ClassCancelled = Notification.Name("ClassCancelled")
    static let ClassReviewAdded = Notification.Name("ClassReviewAdded")
} 