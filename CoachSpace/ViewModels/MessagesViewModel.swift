import Foundation
import Combine

@MainActor
class MessagesViewModel: ObservableObject {
    @Published var chatRooms: [ChatRoom] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var error: Error?
    
    private let messagingService = MessagingService.shared
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("MessagesViewModel: Initializing")
        print("MessagesViewModel: AuthService initialized: \(authService != nil)")
        print("MessagesViewModel: MessagingService initialized: \(messagingService != nil)")
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        print("MessagesViewModel: Starting setupSubscriptions function")
        isLoading = true
        
        Task {
            print("MessagesViewModel: Inside Task")
            do {
                print("MessagesViewModel: Getting current user")
                guard let currentUser = await authService.getCurrentUser() else {
                    print("MessagesViewModel: No current user found")
                    await MainActor.run {
                        self.isLoading = false
                    }
                    return
                }
                print("MessagesViewModel: Current user ID: \(currentUser.id)")
                
                // Observe chat rooms
                print("MessagesViewModel: Setting up chat rooms observation")
                messagingService.observeChatRooms(for: currentUser.id)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] completion in
                        print("MessagesViewModel: Chat rooms observation completed")
                        if case .failure(let error) = completion {
                            print("MessagesViewModel: Error observing chat rooms: \(error)")
                            self?.error = error
                        }
                        self?.isLoading = false
                    } receiveValue: { [weak self] rooms in
                        print("MessagesViewModel: Received \(rooms.count) chat rooms")
                        for room in rooms {
                            print("MessagesViewModel: Room ID: \(room.id), Type: \(room.type), Participants: \(room.participants)")
                        }
                        self?.chatRooms = rooms.sorted { $0.updatedAt > $1.updatedAt }
                        self?.isLoading = false
                    }
                    .store(in: &cancellables)
                
                // Observe unread count
                print("MessagesViewModel: Setting up unread count observation")
                messagingService.observeUnreadCount(for: currentUser.id)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] completion in
                        print("MessagesViewModel: Unread count observation completed")
                        if case .failure(let error) = completion {
                            print("MessagesViewModel: Error observing unread count: \(error)")
                            self?.error = error
                        }
                    } receiveValue: { [weak self] count in
                        print("MessagesViewModel: Unread count: \(count)")
                        self?.unreadCount = count
                    }
                    .store(in: &cancellables)
                
                // Update presence
                print("MessagesViewModel: Updating presence")
                do {
                    try await messagingService.updateUserPresence(userId: currentUser.id, isOnline: true)
                    print("MessagesViewModel: Updated presence to online")
                } catch {
                    print("MessagesViewModel: Error updating presence: \(error)")
                }
            } catch {
                print("MessagesViewModel: Error in setupSubscriptions: \(error)")
                self.error = error
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    func createDirectChat(with userId: String) async throws -> ChatRoom {
        guard let currentUser = await authService.getCurrentUser() else {
            throw MessagingError.invalidOperation("No current user")
        }
        
        // Check if chat already exists
        let existingRoom = chatRooms.first { room in
            room.type == .direct && 
            room.participants.count == 2 &&
            room.participants.contains(currentUser.id) &&
            room.participants.contains(userId)
        }
        
        if let existingRoom = existingRoom {
            return existingRoom
        }
        
        // Create new chat room
        return try await messagingService.createChatRoom(
            participants: [currentUser.id, userId],
            type: .direct,
            name: nil,
            imageURL: nil
        )
    }
    
    func createGroupChat(participants: [String], name: String, imageURL: String?) async throws -> ChatRoom {
        guard let currentUser = await authService.getCurrentUser() else {
            throw MessagingError.invalidOperation("No current user")
        }
        
        var allParticipants = participants
        if !allParticipants.contains(currentUser.id) {
            allParticipants.append(currentUser.id)
        }
        
        return try await messagingService.createChatRoom(
            participants: allParticipants,
            type: .classGroup,
            name: name,
            imageURL: imageURL
        )
    }
    
    func deleteChatRoom(_ chatRoom: ChatRoom) async throws {
        try await messagingService.deleteChatRoom(chatRoom.id)
    }
    
    func filterChatRooms(by filter: MessagesView.MessageFilter, searchText: String = "") -> [ChatRoom] {
        var filtered = chatRooms
        
        // Apply type filter
        switch filter {
        case .instructors:
            filtered = filtered.filter { $0.type == .direct }
        case .classmates:
            filtered = filtered.filter { $0.type == .direct }
        case .schools:
            filtered = filtered.filter { $0.type == .classGroup }
        case .all:
            break
        }
        
        // Apply search filter if needed
        if !searchText.isEmpty {
            filtered = filtered.filter { room in
                if let lastMessage = room.lastMessage {
                    return lastMessage.content.localizedCaseInsensitiveContains(searchText)
                }
                return false
            }
        }
        
        return filtered
    }
} 