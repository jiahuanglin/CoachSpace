import Foundation

struct Class: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let instructor: Instructor
    let venue: Venue
    let category: Category
    let level: Level
    let duration: Int // in minutes
    let price: Double
    let startTime: Date
    let maxParticipants: Int
    let currentParticipants: Int
    let imageURL: String
    let tags: [String]
    
    var isAvailable: Bool {
        currentParticipants < maxParticipants
    }
    
    enum Category: String, CaseIterable {
        case snowboard = "Snowboard"
        case ski = "Ski"
        case surf = "Surf"
        case tennis = "Tennis"
        case golf = "Golf"
        case swimming = "Swimming"
        case dance = "Dance"
        case martialArts = "Martial Arts"
        case yoga = "Yoga"
        case groupFitness = "Group Fitness"
        case personalTraining = "Personal Training"
        
        var icon: String {
            switch self {
            case .snowboard: return "snowflake"
            case .ski: return "figure.skiing"
            case .surf: return "water.waves"
            case .tennis: return "figure.tennis"
            case .golf: return "figure.golf"
            case .swimming: return "figure.pool.swim"
            case .dance: return "music.note"
            case .martialArts: return "figure.martial.arts"
            case .yoga: return "figure.mind.and.body"
            case .groupFitness: return "person.3"
            case .personalTraining: return "figure.strengthtraining.traditional"
            }
        }
    }
    
    enum Level: String, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"
        case allLevels = "All Levels"
    }
}

struct Instructor: Identifiable {
    let id: UUID
    let name: String
    let bio: String
    let specialties: [String]
    let rating: Double
    let imageURL: String
    let certifications: [String]
    let yearsOfExperience: Int
}

struct Venue: Identifiable {
    let id: UUID
    let name: String
    let address: String
    let rating: Double
    let imageURL: String
    let latitude: Double
    let longitude: Double
    let amenities: [String]
    let type: VenueType
    
    enum VenueType: String {
        case skiResort = "Ski Resort"
        case beach = "Beach"
        case studio = "Studio"
        case gym = "Gym"
        case pool = "Pool"
        case court = "Court"
        case outdoorSpace = "Outdoor Space"
    }
}

struct Message: Identifiable {
    let id: UUID
    let senderId: UUID
    let receiverId: UUID
    let content: String
    let timestamp: Date
    let type: MessageType
    
    enum MessageType {
        case text
        case image
        case location
        case classInvite(Class)
    }
} 