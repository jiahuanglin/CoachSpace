import Foundation
import FirebaseFirestore

struct Instructor: Identifiable, Codable {
    let id: String
    let name: String
    let bio: String
    let specialties: [String]
    let rating: Double
    let imageURL: String
    let certifications: [String]
    let yearsOfExperience: Int
    let categories: [Class.Category]
    let levels: [Class.Level]
    let availability: [WeeklyAvailability]
    let createdAt: Date
    let updatedAt: Date
    
    struct WeeklyAvailability: Codable {
        let dayOfWeek: Int // 1 (Sunday) to 7 (Saturday)
        let startTime: String // 24-hour format "HH:mm"
        let endTime: String // 24-hour format "HH:mm"
        let isAvailable: Bool
    }
    
    var formattedSpecialties: String {
        specialties.joined(separator: " • ")
    }
    
    var formattedCertifications: String {
        certifications.joined(separator: " • ")
    }
}

// Firestore Extensions
extension Instructor {
    static func from(_ document: DocumentSnapshot) -> Instructor? {
        try? document.data(as: Instructor.self)
    }
    
    var toFirestore: [String: Any] {
        guard let data = try? Firestore.Encoder().encode(self) else { return [:] }
        return data
    }
} 