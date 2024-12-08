import Foundation
import FirebaseFirestore

struct Review: Identifiable, Codable {
    let id: String
    let classId: String
    let userId: String
    let rating: Int
    let comment: String
    let createdAt: Date
}

// Firestore Extensions
extension Review {
    static func from(_ document: DocumentSnapshot) -> Review? {
        try? document.data(as: Review.self)
    }
    
    var toFirestore: [String: Any] {
        guard let data = try? Firestore.Encoder().encode(self) else { return [:] }
        return data
    }
}
