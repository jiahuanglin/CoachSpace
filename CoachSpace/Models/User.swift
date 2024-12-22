import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let displayName: String
    let phoneNumber: String?
    let imageURL: String?
    let role: UserRole
    let preferences: UserPreferences
    let stats: UserStats
    let settings: UserSettings
    let status: UserStatus
    let fcmToken: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum UserRole: String, Codable {
        case student
        case instructor
        case admin
    }
    
    enum UserStatus: String, Codable {
        case active
        case inactive
        case suspended
        case deleted
    }
    
    struct UserPreferences: Codable {
        let preferredCategories: [Class.Category]
        let preferredLevels: [Class.Level]
        let preferredInstructors: [String] // Instructor IDs
        let preferredVenues: [String] // Venue IDs
        let notifications: NotificationPreferences
        
        struct NotificationPreferences: Codable {
            let classReminders: Bool
            let promotions: Bool
            let messages: Bool
            let bookingUpdates: Bool
            let achievementAlerts: Bool
            let skillLevelUpdates: Bool
            let email: Bool
            let push: Bool
            let sms: Bool
        }
    }
    
    struct UserStats: Codable {
        let totalClasses: Int
        let totalHours: Int
        let averageRating: Double
        let skillLevels: [SkillLevel]
        let achievements: [Achievement]
        
        struct SkillLevel: Codable {
            let category: Class.Category
            let level: Class.Level
            let progress: Double // 0 to 1
            let updatedAt: Date
        }
        
        struct Achievement: Codable {
            let id: String
            let title: String
            let description: String
            let category: String
            let progress: Double // 0 to 1
            let isCompleted: Bool
            let completedAt: Date?
            let icon: String
        }
    }
    
    struct UserSettings: Codable {
        let language: String
        let timezone: String
        let currency: String
        let measurementSystem: MeasurementSystem
        
        enum MeasurementSystem: String, Codable {
            case metric
            case imperial
        }
    }
}

// Firestore Extensions
extension User {
    static func from(_ document: DocumentSnapshot) -> User? {
        try? document.data(as: User.self)
    }
    
    var toFirestore: [String: Any] {
        guard let data = try? Firestore.Encoder().encode(self) else { return [:] }
        return data
    }
}

// User Session
struct UserSession {
    let user: User
    let authToken: String
    let refreshToken: String
    let expiresAt: Date
    
    var isValid: Bool {
        expiresAt > Date()
    }
} 