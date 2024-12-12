import Foundation
import FirebaseFirestore

struct Booking: Identifiable, Codable, Equatable {
    let id: String
    let classId: String
    let userId: String
    let status: BookingStatus
    let createdAt: Date
    
    enum BookingStatus: String, Codable, Equatable {
        case confirmed
        case cancelled
        case waitlisted
    }
    
    static func == (lhs: Booking, rhs: Booking) -> Bool {
        return lhs.id == rhs.id &&
               lhs.classId == rhs.classId &&
               lhs.userId == rhs.userId &&
               lhs.status == rhs.status &&
               lhs.createdAt == rhs.createdAt
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