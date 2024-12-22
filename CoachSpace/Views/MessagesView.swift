import SwiftUI

struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @State private var searchText = ""
    @State private var selectedFilter: MessageFilter = .all
    @State private var showNewChatSheet = false
    
    enum MessageFilter: String, CaseIterable {
        case all = "All"
        case instructors = "Instructors"
        case classmates = "Classmates"
        case schools = "Schools"
    }
    
    var searchSection: some View {
        SearchBar(
            text: $searchText,
            placeholder: "Search messages",
            onSearch: {
                // Implement search
            },
            onCancel: {
                // Clear search
                searchText = ""
            }
        )
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Search and Filter
                VStack(spacing: 16) {
                    // Search
                    searchSection
                    
                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(MessageFilter.allCases, id: \.self) { filter in
                                FilterPill(
                                    title: filter.rawValue,
                                    isSelected: selectedFilter == filter
                                ) {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            let filteredRooms = viewModel.filterChatRooms(by: selectedFilter, searchText: searchText)
                            
                            // Upcoming Class Chats
                            if selectedFilter == .all || selectedFilter == .schools {
                                let classChats = filteredRooms.filter { $0.type == .classGroup }
                                if !classChats.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Upcoming Classes")
                                            .font(.headline)
                                            .padding(.horizontal)
                                        
                                        ForEach(classChats) { room in
                                            NavigationLink(destination: ChatDetailView(chatRoom: room)) {
                                                UpcomingClassChatRow(chatRoom: room)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Recent Conversations
                            let directChats = filteredRooms.filter { $0.type == .direct }
                            if !directChats.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Recent")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    ForEach(directChats) { room in
                                        NavigationLink(destination: ChatDetailView(chatRoom: room)) {
                                            ConversationRow(chatRoom: room)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewChatSheet = true }) {
                        Image(systemName: "plus.message")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showNewChatSheet) {
                NewChatView(viewModel: viewModel)
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "")
            }
        }
    }
}

struct UpcomingClassChatRow: View {
    let chatRoom: ChatRoom
    @State private var participants: [User] = []
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Class Image
                AsyncImage(url: URL(string: chatRoom.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 60, height: 60)
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(chatRoom.name ?? "Class Chat")
                        .font(.headline)
                    if let classId = chatRoom.classId {
                        Text("Class ID: \(classId)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("\(participants.count) participants")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                
                // Unread indicator
                if let lastMessage = chatRoom.lastMessage, lastMessage.status != .read {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Preview of last message
            if let lastMessage = chatRoom.lastMessage {
                HStack {
                    if lastMessage.senderId == "system" {
                        Text(lastMessage.content)
                            .foregroundColor(.gray)
                    } else {
                        Text("\(participants.first(where: { $0.id == lastMessage.senderId })?.displayName ?? "Unknown"):")
                            .fontWeight(.medium)
                        Text(lastMessage.content)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text(formatDate(lastMessage.timestamp))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
            }
        }
        .cornerRadius(16)
        .padding(.horizontal)
        .onAppear {
            loadParticipants()
        }
    }
    
    private func loadParticipants() {
        Task {
            do {
                participants = try await UserService.shared.getUsers(ids: chatRoom.participants)
            } catch {
                print("Error loading participants: \(error)")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ConversationRow: View {
    let chatRoom: ChatRoom
    @State private var participant: User?
    @State private var isOnline = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Image with status
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: URL(string: participant?.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                
                if isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(participant?.displayName ?? "Loading...")
                        .font(.headline)
                    if let role = participant?.role {
                        Text("• \(role)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                
                if let lastMessage = chatRoom.lastMessage {
                    Text(lastMessage.content)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if let lastMessage = chatRoom.lastMessage {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatDate(lastMessage.timestamp))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if lastMessage.status != .read {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
        .onAppear {
            loadParticipant()
        }
    }
    
    private func loadParticipant() {
        // For direct chats, get the other participant
        Task {
            do {
                let otherParticipantId = chatRoom.participants.first { $0 != AuthService.shared.currentUser?.id }
                if let id = otherParticipantId {
                    participant = try await UserService.shared.getUser(id: id)
                    
                    // Observe online status
                    MessagingService.shared.observeUserPresence(userId: id)
                        .receive(on: DispatchQueue.main)
                        .sink { _ in
                        } receiveValue: { status in
                            isOnline = status
                        }
                }
            } catch {
                print("Error loading participant: \(error)")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct NewChatView: View {
    @ObservedObject var viewModel: MessagesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedUsers: Set<String> = []
    @State private var isGroupChat = false
    @State private var groupName = ""
    @State private var users: [User] = []
    @State private var isLoading = false
    @State private var error: Error?
    
    var body: some View {
        NavigationView {
            VStack {
                if isGroupChat {
                    TextField("Group Name", text: $groupName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }
                
                SearchBar(
                    text: $searchText,
                    placeholder: "Search users",
                    onSearch: {
                        // Implement search
                    },
                    onCancel: {
                        searchText = ""
                    }
                )
                
                if isLoading {
                    ProgressView()
                } else {
                    let filteredUsers = users.filter {
                        searchText.isEmpty || $0.displayName.localizedCaseInsensitiveContains(searchText)
                    }
                    List(filteredUsers) { user in
                        HStack {
                            AsyncImage(url: URL(string: user.imageURL ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                Text(user.displayName)
                                    .font(.headline)
                                Text(user.role.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedUsers.contains(user.id) {
                                selectedUsers.remove(user.id)
                            } else {
                                selectedUsers.insert(user.id)
                            }
                        }
                        .background(
                            selectedUsers.contains(user.id) ?
                            Color.blue.opacity(0.2) : Color.clear
                        )
                    }
                }
            }
            .navigationTitle(isGroupChat ? "New Group" : "New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isGroupChat {
                        Button("Create") {
                            createGroupChat()
                        }
                        .disabled(selectedUsers.isEmpty || groupName.isEmpty)
                    } else {
                        Button("Group") {
                            isGroupChat = true
                        }
                    }
                }
            }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") { error = nil }
            } message: {
                Text(error?.localizedDescription ?? "")
            }
            .onAppear {
                loadUsers()
            }
        }
    }
    
    private func loadUsers() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                users = try await UserService.shared.getAllUsers()
            } catch {
                self.error = error
            }
        }
    }
    
    private func createGroupChat() {
        Task {
            do {
                let chatRoom = try await viewModel.createGroupChat(
                    participants: Array(selectedUsers),
                    name: groupName,
                    imageURL: nil
                )
                dismiss()
            } catch {
                self.error = error
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSearch: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            Button(action: onCancel) {
                Text("Cancel")
                    .foregroundColor(.blue)
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView()
    }
} 