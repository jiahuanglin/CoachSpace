import Foundation
import FirebaseFirestore

struct Message: Identifiable, Codable {
    let id: String
    let senderId: String
    let receiverId: String
    let content: String
    let timestamp: Date
    let type: MessageType
    let status: MessageStatus
    let metadata: MessageMetadata?
    let createdAt: Date
    let updatedAt: Date
    
    enum MessageType: String, Codable {
        case text
        case image
        case location
        case classInvite
        case classConfirmation
        case classReminder
        case classReview
        case system
    }
    
    enum MessageStatus: String, Codable {
        case sent
        case delivered
        case read
        case failed
    }
    
    struct MessageMetadata: Codable {
        let classId: String?
        let imageURL: String?
        let latitude: Double?
        let longitude: Double?
        let rating: Int?
        let review: String?
    }
}

// Firestore Extensions
extension Message {
    static func from(_ document: DocumentSnapshot) -> Message? {
        try? document.data(as: Message.self)
    }
    
    var toFirestore: [String: Any] {
        guard let data = try? Firestore.Encoder().encode(self) else { return [:] }
        return data
    }
}

// Chat Room
struct ChatRoom: Identifiable, Codable {
    let id: String
    let participants: [String] // User IDs
    let lastMessage: Message?
    let classId: String?
    let type: ChatRoomType
    let createdAt: Date
    let updatedAt: Date
    
    enum ChatRoomType: String, Codable {
        case direct // One-on-one chat
        case classGroup // Group chat for a class
        case support // Support chat
    }
}

// Firestore Extensions
extension ChatRoom {
    static func from(_ document: DocumentSnapshot) -> ChatRoom? {
        try? document.data(as: ChatRoom.self)
    }
    
    var toFirestore: [String: Any] {
        guard let data = try? Firestore.Encoder().encode(self) else { return [:] }
        return data
    }
} 