import Foundation
import FirebaseFirestore

struct Booking: Identifiable, Codable {
    let id: String
    let classId: String
    let userId: String
    let status: BookingStatus
    let createdAt: Date
    
    enum BookingStatus: String, Codable {
        case confirmed
        case cancelled
        case waitlisted
    }
}

// Firestore Extensions
extension Booking {
    static func from(_ document: DocumentSnapshot) -> Booking? {
        try? document.data(as: Booking.self)
    }
    
    var toFirestore: [String: Any] {
        guard let data = try? Firestore.Encoder().encode(self) else { return [:] }
        return data
    }
} 