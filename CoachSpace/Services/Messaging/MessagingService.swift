import Foundation
import FirebaseFirestore
import FirebaseMessaging
import Combine

protocol MessagingServiceProtocol {
    // Chat Room Operations
    func getChatRoom(id: String) async throws -> ChatRoom?
    func createChatRoom(participants: [String], type: ChatRoom.ChatRoomType, name: String?, imageURL: String?) async throws -> ChatRoom
    func getChatRooms(for userId: String) async throws -> [ChatRoom]
    func deleteChatRoom(_ chatRoomId: String) async throws
    func addParticipants(_ userIds: [String], to chatRoomId: String) async throws
    func removeParticipants(_ userIds: [String], from chatRoomId: String) async throws
    func updateChatRoom(_ chatRoomId: String, name: String?, imageURL: String?) async throws
    
    // Message Operations
    func sendMessage(_ message: Message, to chatRoomId: String) async throws
    func getMessages(for chatRoomId: String, limit: Int, before: Date?) async throws -> [Message]
    func markMessagesAsRead(in chatRoomId: String, for userId: String) async throws
    func deleteMessage(_ messageId: String, from chatRoomId: String) async throws
    
    // Real-time Subscriptions
    func observeChatRooms(for userId: String) -> AnyPublisher<[ChatRoom], Error>
    func observeMessages(in chatRoomId: String) -> AnyPublisher<[Message], Error>
    func observeUnreadCount(for userId: String) -> AnyPublisher<Int, Error>
    func observeParticipants(in chatRoomId: String) -> AnyPublisher<[User], Error>
    
    // Presence
    func updateUserPresence(userId: String, isOnline: Bool) async throws
    func observeUserPresence(userId: String) -> AnyPublisher<Bool, Error>
}

final class MessagingService: MessagingServiceProtocol {
    static let shared = MessagingService()
    private let db = Firestore.firestore()
    private let storage = StorageService.shared
    
    private init() {
        setupPresenceMonitoring()
    }
    
    // MARK: - Chat Room Operations
    
    func getChatRoom(id: String) async throws -> ChatRoom? {
        do {
            let doc = try await db.collection("chatRooms").document(id).getDocument()
            return ChatRoom.from(doc)
        } catch {
            throw MessagingError.fetchFailed(error)
        }
    }
    
    func createChatRoom(participants: [String], type: ChatRoom.ChatRoomType, name: String?, imageURL: String?) async throws -> ChatRoom {
        do {
            let chatRoomId = UUID().uuidString
            let chatRoom = ChatRoom(
                id: chatRoomId,
                participants: participants,
                lastMessage: nil,
                classId: nil,
                type: type,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await db.collection("chatRooms")
                .document(chatRoomId)
                .setData(chatRoom.toFirestore)
            
            // Create user-specific metadata for each participant
            for userId in participants {
                try await db.collection("userChatRooms")
                    .document(userId)
                    .collection("rooms")
                    .document(chatRoomId)
                    .setData([
                        "chatRoomId": chatRoomId,
                        "unreadCount": 0,
                        "lastReadTimestamp": Date(),
                        "isArchived": false,
                        "isPinned": false,
                        "updatedAt": FieldValue.serverTimestamp()
                    ])
            }
            
            return chatRoom
        } catch {
            throw MessagingError.createFailed(error)
        }
    }
    
    func getChatRooms(for userId: String) async throws -> [ChatRoom] {
        do {
            let userRooms = try await db.collection("userChatRooms")
                .document(userId)
                .collection("rooms")
                .order(by: "updatedAt", descending: true)
                .getDocuments()
            
            var chatRooms: [ChatRoom] = []
            for doc in userRooms.documents {
                if let chatRoomId = doc.data()["chatRoomId"] as? String,
                   let chatRoom = try await getChatRoom(id: chatRoomId) {
                    chatRooms.append(chatRoom)
                }
            }
            return chatRooms
        } catch {
            throw MessagingError.fetchFailed(error)
        }
    }
    
    func deleteChatRoom(_ chatRoomId: String) async throws {
        do {
            guard let chatRoom = try await getChatRoom(id: chatRoomId) else {
                throw MessagingError.chatRoomNotFound
            }
            
            let batch = db.batch()
            
            // Delete messages
            let messages = try await db.collection("chatRooms")
                .document(chatRoomId)
                .collection("messages")
                .getDocuments()
            
            for message in messages.documents {
                batch.deleteDocument(message.reference)
                
                // Delete message attachments if any
                if let message = Message.from(message),
                   let metadata = message.metadata,
                   let attachmentURL = metadata.imageURL {
                    try await storage.deleteImage(at: attachmentURL)
                }
            }
            
            // Delete user-specific metadata
            for userId in chatRoom.participants {
                let userRoomRef = db.collection("userChatRooms")
                    .document(userId)
                    .collection("rooms")
                    .document(chatRoomId)
                batch.deleteDocument(userRoomRef)
            }
            
            // Delete chat room
            batch.deleteDocument(db.collection("chatRooms").document(chatRoomId))
            
            try await batch.commit()
        } catch {
            throw MessagingError.deleteFailed(error)
        }
    }
    
    func addParticipants(_ userIds: [String], to chatRoomId: String) async throws {
        do {
            guard let chatRoom = try await getChatRoom(id: chatRoomId) else {
                throw MessagingError.chatRoomNotFound
            }
            
            // Validate group chat
            guard chatRoom.type == .classGroup else {
                throw MessagingError.invalidOperation("Cannot add participants to a direct chat")
            }
            
            // Update chat room participants
            let updatedParticipants = Array(Set(chatRoom.participants + userIds))
            try await db.collection("chatRooms")
                .document(chatRoomId)
                .updateData(["participants": updatedParticipants])
            
            // Create user-specific metadata for new participants
            let batch = db.batch()
            for userId in userIds {
                let userRoomRef = db.collection("userChatRooms")
                    .document(userId)
                    .collection("rooms")
                    .document(chatRoomId)
                
                batch.setData([
                    "chatRoomId": chatRoomId,
                    "unreadCount": 0,
                    "lastReadTimestamp": Date(),
                    "isArchived": false,
                    "isPinned": false,
                    "updatedAt": FieldValue.serverTimestamp()
                ], forDocument: userRoomRef)
            }
            
            try await batch.commit()
            
            // Add system message
            let systemMessage = Message(
                id: UUID().uuidString,
                senderId: "system",
                receiverId: chatRoomId,
                content: "New members added to the group",
                timestamp: Date(),
                type: .system,
                status: .delivered,
                metadata: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            try await sendMessage(systemMessage, to: chatRoomId)
        } catch {
            throw MessagingError.updateFailed(error)
        }
    }
    
    func removeParticipants(_ userIds: [String], from chatRoomId: String) async throws {
        do {
            guard let chatRoom = try await getChatRoom(id: chatRoomId) else {
                throw MessagingError.chatRoomNotFound
            }
            
            // Validate group chat
            guard chatRoom.type == .classGroup else {
                throw MessagingError.invalidOperation("Cannot remove participants from a direct chat")
            }
            
            // Update chat room participants
            let updatedParticipants = chatRoom.participants.filter { !userIds.contains($0) }
            try await db.collection("chatRooms")
                .document(chatRoomId)
                .updateData(["participants": updatedParticipants])
            
            // Remove user-specific metadata
            let batch = db.batch()
            for userId in userIds {
                let userRoomRef = db.collection("userChatRooms")
                    .document(userId)
                    .collection("rooms")
                    .document(chatRoomId)
                batch.deleteDocument(userRoomRef)
            }
            
            try await batch.commit()
            
            // Add system message
            let systemMessage = Message(
                id: UUID().uuidString,
                senderId: "system",
                receiverId: chatRoomId,
                content: "Members removed from the group",
                timestamp: Date(),
                type: .system,
                status: .delivered,
                metadata: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            try await sendMessage(systemMessage, to: chatRoomId)
        } catch {
            throw MessagingError.updateFailed(error)
        }
    }
    
    func updateChatRoom(_ chatRoomId: String, name: String?, imageURL: String?) async throws {
        do {
            guard let chatRoom = try await getChatRoom(id: chatRoomId) else {
                throw MessagingError.chatRoomNotFound
            }
            
            // Validate group chat
            guard chatRoom.type == .classGroup else {
                throw MessagingError.invalidOperation("Cannot update name/image for a direct chat")
            }
            
            var updateData: [String: Any] = [:]
            if let name = name {
                updateData["name"] = name
            }
            if let imageURL = imageURL {
                updateData["imageURL"] = imageURL
            }
            
            try await db.collection("chatRooms")
                .document(chatRoomId)
                .updateData(updateData)
            
            // Add system message
            let content = name != nil ? "Group name updated" : "Group image updated"
            let systemMessage = Message(
                id: UUID().uuidString,
                senderId: "system",
                receiverId: chatRoomId,
                content: content,
                timestamp: Date(),
                type: .system,
                status: .delivered,
                metadata: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            try await sendMessage(systemMessage, to: chatRoomId)
        } catch {
            throw MessagingError.updateFailed(error)
        }
    }
    
    func observeParticipants(in chatRoomId: String) -> AnyPublisher<[User], Error> {
        let ref = db.collection("chatRooms").document(chatRoomId)
        
        return Publishers.DocumentSnapshotPublisher(reference: ref)
            .flatMap { [weak self] snapshot -> AnyPublisher<[User], Error> in
                guard let self = self,
                      let data = snapshot.data(),
                      let participants = data["participants"] as? [String] else {
                    return Just([])
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                
                return self.fetchUsers(ids: participants)
            }
            .eraseToAnyPublisher()
    }
    
    private func fetchUsers(ids: [String]) -> AnyPublisher<[User], Error> {
        let publishers = ids.map { id in
            Future<User?, Error> { promise in
                Task {
                    do {
                        let user = try await UserService.shared.getUser(id: id)
                        promise(.success(user))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
        
        return Publishers.MergeMany(publishers)
            .compactMap { $0 }
            .collect()
            .eraseToAnyPublisher()
    }
    
    // MARK: - Message Operations
    
    func sendMessage(_ message: Message, to chatRoomId: String) async throws {
        do {
            guard let chatRoom = try await getChatRoom(id: chatRoomId) else {
                throw MessagingError.chatRoomNotFound
            }
            
            // Upload attachment if message contains one
            var finalMessage = message
            if case .image = message.type,
               let metadata = message.metadata,
               let imageURL = metadata.imageURL {
                let storagePath = storage.getStoragePath(for: .messageImage, id: message.id)
                if let image = try? await storage.downloadImage(from: imageURL) {
                    let uploadedURL = try await storage.uploadImage(image, path: storagePath)
                    finalMessage = message.updateImageURL(uploadedURL)
                }
            }
            
            // Save message
            try await db.collection("chatRooms")
                .document(chatRoomId)
                .collection("messages")
                .document(finalMessage.id)
                .setData(finalMessage.toFirestore)
            
            // Update chat room's last message
            try await db.collection("chatRooms")
                .document(chatRoomId)
                .updateData([
                    "lastMessage": finalMessage.toFirestore,
                    "updatedAt": FieldValue.serverTimestamp()
                ])
            
            // Update user-specific metadata for all participants except sender
            let batch = db.batch()
            for userId in chatRoom.participants where userId != finalMessage.senderId {
                let userRoomRef = db.collection("userChatRooms")
                    .document(userId)
                    .collection("rooms")
                    .document(chatRoomId)
                
                batch.updateData([
                    "unreadCount": FieldValue.increment(Int64(1)),
                    "updatedAt": FieldValue.serverTimestamp()
                ], forDocument: userRoomRef)
            }
            
            try await batch.commit()
        } catch {
            throw MessagingError.sendFailed(error)
        }
    }
    
    func getMessages(for chatRoomId: String, limit: Int = 50, before: Date? = nil) async throws -> [Message] {
        do {
            var query = db.collection("chatRooms")
                .document(chatRoomId)
                .collection("messages")
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
            
            if let before = before {
                query = query.whereField("timestamp", isLessThan: before)
            }
            
            let snapshot = try await query.getDocuments()
            return snapshot.documents.compactMap { Message.from($0) }
        } catch {
            throw MessagingError.fetchFailed(error)
        }
    }
    
    func markMessagesAsRead(in chatRoomId: String, for userId: String) async throws {
        do {
            let batch = db.batch()
            
            // Update message status
            let messages = try await db.collection("chatRooms")
                .document(chatRoomId)
                .collection("messages")
                .whereField("status", isEqualTo: Message.MessageStatus.delivered.rawValue)
                .whereField("receiverId", isEqualTo: userId)
                .getDocuments()
            
            for message in messages.documents {
                batch.updateData([
                    "status": Message.MessageStatus.read.rawValue
                ], forDocument: message.reference)
            }
            
            // Reset unread count
            let userRoomRef = db.collection("userChatRooms")
                .document(userId)
                .collection("rooms")
                .document(chatRoomId)
            
            batch.updateData([
                "unreadCount": 0,
                "lastReadTimestamp": FieldValue.serverTimestamp()
            ], forDocument: userRoomRef)
            
            try await batch.commit()
        } catch {
            throw MessagingError.updateFailed(error)
        }
    }
    
    func deleteMessage(_ messageId: String, from chatRoomId: String) async throws {
        do {
            let ref = db.collection("chatRooms")
                .document(chatRoomId)
                .collection("messages")
                .document(messageId)
            
            // Delete message attachment if exists
            if let message = Message.from(try await ref.getDocument()),
               let metadata = message.metadata,
               let attachmentURL = metadata.imageURL {
                try await storage.deleteImage(at: attachmentURL)
            }
            
            try await ref.delete()
        } catch {
            throw MessagingError.deleteFailed(error)
        }
    }
    
    // MARK: - Real-time Subscriptions
    
    func observeChatRooms(for userId: String) -> AnyPublisher<[ChatRoom], Error> {
        let query = db.collection("userChatRooms")
            .document(userId)
            .collection("rooms")
            .order(by: "updatedAt", descending: true)
        
        return Publishers.QuerySnapshotPublisher(query: query)
            .flatMap { [weak self] snapshot -> AnyPublisher<[ChatRoom], Error> in
                guard let self = self else {
                    return Just([])
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                
                let chatRoomIds = snapshot.documents.compactMap { doc in
                    doc.data()["chatRoomId"] as? String
                }
                
                return self.fetchChatRooms(ids: chatRoomIds)
            }
            .eraseToAnyPublisher()
    }
    
    func observeMessages(in chatRoomId: String) -> AnyPublisher<[Message], Error> {
        let query = db.collection("chatRooms")
            .document(chatRoomId)
            .collection("messages")
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
        
        return Publishers.QuerySnapshotPublisher(query: query)
            .map { snapshot in
                snapshot.documents.compactMap { Message.from($0) }
            }
            .eraseToAnyPublisher()
    }
    
    func observeUnreadCount(for userId: String) -> AnyPublisher<Int, Error> {
        let query = db.collection("userChatRooms")
            .document(userId)
            .collection("rooms")
            .whereField("unreadCount", isGreaterThan: 0)
        
        return Publishers.QuerySnapshotPublisher(query: query)
            .map { snapshot in
                snapshot.documents.reduce(0) { count, doc in
                    count + (doc.data()["unreadCount"] as? Int ?? 0)
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Presence
    
    func updateUserPresence(userId: String, isOnline: Bool) async throws {
        do {
            let presenceRef = db.collection("presence").document(userId)
            try await presenceRef.setData([
                "isOnline": isOnline,
                "lastSeen": FieldValue.serverTimestamp()
            ])
        } catch {
            throw MessagingError.updateFailed(error)
        }
    }
    
    func observeUserPresence(userId: String) -> AnyPublisher<Bool, Error> {
        let ref = db.collection("presence").document(userId)
        
        return Publishers.DocumentSnapshotPublisher(reference: ref)
            .map { snapshot -> Bool in
                guard let data = snapshot.data(),
                      let isOnline = data["isOnline"] as? Bool else {
                    return false
                }
                return isOnline
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func setupPresenceMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    @objc private func handleAppDidBecomeActive() {
        Task {
            if let userId = AuthService.shared.getCurrentUser()?.id {
                try? await updateUserPresence(userId: userId, isOnline: true)
            }
        }
    }
    
    @objc private func handleAppWillResignActive() {
        Task {
            if let userId = AuthService.shared.getCurrentUser()?.id {
                try? await updateUserPresence(userId: userId, isOnline: false)
            }
        }
    }
    
    private func fetchChatRooms(ids: [String]) -> AnyPublisher<[ChatRoom], Error> {
        let publishers = ids.map { id in
            Future<ChatRoom?, Error> { [weak self] promise in
                Task {
                    do {
                        let chatRoom = try await self?.getChatRoom(id: id)
                        promise(.success(chatRoom))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
        
        return Publishers.MergeMany(publishers)
            .compactMap { $0 }
            .collect()
            .eraseToAnyPublisher()
    }
}

// MARK: - Errors

enum MessagingError: LocalizedError {
    case sendFailed(Error)
    case fetchFailed(Error)
    case createFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case chatRoomNotFound
    case invalidOperation(String)
    
    var errorDescription: String? {
        switch self {
        case .sendFailed(let error): return "Failed to send message: \(error.localizedDescription)"
        case .fetchFailed(let error): return "Failed to fetch data: \(error.localizedDescription)"
        case .createFailed(let error): return "Failed to create chat room: \(error.localizedDescription)"
        case .updateFailed(let error): return "Failed to update data: \(error.localizedDescription)"
        case .deleteFailed(let error): return "Failed to delete data: \(error.localizedDescription)"
        case .chatRoomNotFound: return "Chat room not found"
        case .invalidOperation(let reason): return "Invalid operation: \(reason)"
        }
    }
}

// MARK: - Firebase Publishers

extension Publishers {
    struct DocumentSnapshotPublisher: Publisher {
        typealias Output = DocumentSnapshot
        typealias Failure = Error
        
        private let reference: DocumentReference
        
        init(reference: DocumentReference) {
            self.reference = reference
        }
        
        func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
            let listener = reference.addSnapshotListener { snapshot, error in
                if let error = error {
                    subscriber.receive(completion: .failure(error))
                    return
                }
                
                guard let snapshot = snapshot else {
                    subscriber.receive(completion: .failure(MessagingError.fetchFailed(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Snapshot is nil"]))))
                    return
                }
                
                _ = subscriber.receive(snapshot)
            }
            
            subscriber.receive(subscription: FirebaseSubscription(listener: listener))
        }
    }
    
    struct QuerySnapshotPublisher: Publisher {
        typealias Output = QuerySnapshot
        typealias Failure = Error
        
        private let query: Query
        
        init(query: Query) {
            self.query = query
        }
        
        func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
            let listener = query.addSnapshotListener { snapshot, error in
                if let error = error {
                    subscriber.receive(completion: .failure(error))
                    return
                }
                
                guard let snapshot = snapshot else {
                    subscriber.receive(completion: .failure(MessagingError.fetchFailed(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Snapshot is nil"]))))
                    return
                }
                
                _ = subscriber.receive(snapshot)
            }
            
            subscriber.receive(subscription: FirebaseSubscription(listener: listener))
        }
    }
}

private class FirebaseSubscription: Subscription {
    private var listener: ListenerRegistration?
    
    init(listener: ListenerRegistration) {
        self.listener = listener
    }
    
    func request(_ demand: Subscribers.Demand) {}
    
    func cancel() {
        listener?.remove()
        listener = nil
    }
}

// MARK: - Message Extensions

private extension Message {
    func updateImageURL(_ url: String) -> Message {
        var updatedMetadata = metadata ?? MessageMetadata(classId: nil, imageURL: nil, latitude: nil, longitude: nil, rating: nil, review: nil)
        updatedMetadata = MessageMetadata(
            classId: updatedMetadata.classId,
            imageURL: url,
            latitude: updatedMetadata.latitude,
            longitude: updatedMetadata.longitude,
            rating: updatedMetadata.rating,
            review: updatedMetadata.review
        )
        return Message(
            id: id,
            senderId: senderId,
            receiverId: receiverId,
            content: content,
            timestamp: timestamp,
            type: type,
            status: status,
            metadata: updatedMetadata,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
} 