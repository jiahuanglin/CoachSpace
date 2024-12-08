import Foundation
import FirebaseFirestore

struct Class: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let instructorId: String
    let venueId: String
    let category: Category
    let level: Level
    let duration: Int // in minutes
    let price: Double
    let startTime: Date
    let maxParticipants: Int
    let currentParticipants: Int
    let imageURL: String
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date
    
    var isAvailable: Bool {
        currentParticipants < maxParticipants
    }
    
    enum Category: String, Codable, CaseIterable {
        case snowboard = "Snowboard"
        case ski = "Ski"
        
        var icon: String {
            switch self {
            case .snowboard: return "snowflake"
            case .ski: return "figure.skiing"
            }
        }
    }
    
    enum Level: String, Codable, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"
        case allLevels = "All Levels"
        
        var description: String {
            switch self {
            case .beginner: return "Perfect for first-timers and those with basic skills"
            case .intermediate: return "For those comfortable with basic techniques"
            case .advanced: return "For experienced riders looking to master advanced skills"
            case .expert: return "For highly skilled riders seeking expert-level challenges"
            case .allLevels: return "Suitable for all skill levels"
            }
        }
    }
}

// Firestore Extensions
extension Class {
    static func from(_ document: DocumentSnapshot) -> Class? {
        try? document.data(as: Class.self)
    }
    
    var toFirestore: [String: Any] {
        guard let data = try? Firestore.Encoder().encode(self) else { return [:] }
        return data
    }
} 