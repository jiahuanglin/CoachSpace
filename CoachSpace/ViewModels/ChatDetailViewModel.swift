import Foundation
import Combine
import CoreLocation

@MainActor
class ChatDetailViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var participants: [User] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let chatRoom: ChatRoom
    private let messagingService = MessagingService.shared
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var currentChatRoom: ChatRoom { chatRoom }
    
    init(chatRoom: ChatRoom) {
        self.chatRoom = chatRoom
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Observe messages
        messagingService.observeMessages(in: chatRoom.id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] messages in
                self?.messages = messages.sorted { $0.timestamp < $1.timestamp }
                self?.markMessagesAsRead()
            }
            .store(in: &cancellables)
        
        // Observe participants
        messagingService.observeParticipants(in: chatRoom.id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] users in
                self?.participants = users
            }
            .store(in: &cancellables)
    }
    
    func sendTextMessage(_ text: String) async throws {
        guard let currentUser = await authService.getCurrentUser() else {
            throw MessagingError.invalidOperation("No current user")
        }
        
        let message = Message(
            id: UUID().uuidString,
            senderId: currentUser.id,
            receiverId: chatRoom.id,
            content: text,
            timestamp: Date(),
            type: .text,
            status: .sent,
            metadata: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await messagingService.sendMessage(message, to: chatRoom.id)
    }
    
    func sendImageMessage(_ imageURL: String) async throws {
        guard let currentUser = await authService.getCurrentUser() else {
            throw MessagingError.invalidOperation("No current user")
        }
        
        let metadata = Message.MessageMetadata(
            classId: nil,
            imageURL: imageURL,
            latitude: nil,
            longitude: nil,
            rating: nil,
            review: nil
        )
        
        let message = Message(
            id: UUID().uuidString,
            senderId: currentUser.id,
            receiverId: chatRoom.id,
            content: "Sent an image",
            timestamp: Date(),
            type: .image,
            status: .sent,
            metadata: metadata,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await messagingService.sendMessage(message, to: chatRoom.id)
    }
    
    func sendLocationMessage(coordinate: CLLocationCoordinate2D) async throws {
        guard let currentUser = await authService.getCurrentUser() else {
            throw MessagingError.invalidOperation("No current user")
        }
        
        let metadata = Message.MessageMetadata(
            classId: nil,
            imageURL: nil,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            rating: nil,
            review: nil
        )
        
        let message = Message(
            id: UUID().uuidString,
            senderId: currentUser.id,
            receiverId: chatRoom.id,
            content: "Shared a location",
            timestamp: Date(),
            type: .location,
            status: .sent,
            metadata: metadata,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await messagingService.sendMessage(message, to: chatRoom.id)
    }
    
    func deleteMessage(_ message: Message) async throws {
        try await messagingService.deleteMessage(message.id, from: chatRoom.id)
    }
    
    private func markMessagesAsRead() {
        Task {
            guard let currentUser = await authService.getCurrentUser() else { return }
            try? await messagingService.markMessagesAsRead(in: chatRoom.id, for: currentUser.id)
        }
    }
    
    func loadMoreMessages(before date: Date) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let oldMessages = try await messagingService.getMessages(for: chatRoom.id, limit: 50, before: date)
        messages.append(contentsOf: oldMessages)
        messages.sort { $0.timestamp < $1.timestamp }
    }
    
    func isParticipantOnline(_ userId: String) -> AnyPublisher<Bool, Error> {
        messagingService.observeUserPresence(userId: userId)
    }
} 