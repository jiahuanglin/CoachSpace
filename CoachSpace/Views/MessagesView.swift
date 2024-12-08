import SwiftUI

struct MessagesView: View {
    @State private var searchText = ""
    @State private var selectedFilter: MessageFilter = .all
    
    enum MessageFilter: String, CaseIterable {
        case all = "All"
        case instructors = "Instructors"
        case classmates = "Classmates"
        case schools = "Schools"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Search and Filter
                VStack(spacing: 16) {
                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search conversations", text: $searchText)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
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
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Upcoming Class Chats
                        if selectedFilter == .all || selectedFilter == .instructors {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Upcoming Classes")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(0..<2) { _ in
                                    NavigationLink(destination: ChatDetailView()) {
                                        UpcomingClassChatRow()
                                    }
                                }
                            }
                        }
                        
                        // Recent Conversations
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(0..<5) { _ in
                                NavigationLink(destination: ChatDetailView()) {
                                    ConversationRow()
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus.message")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
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
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct UpcomingClassChatRow: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Class Image
                Image("class_image")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Advanced Snowboarding")
                        .font(.headline)
                    Text("Whistler Blackcomb School")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    HStack {
                        Text("Tomorrow, 9:00 AM")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("•")
                            .foregroundColor(.gray)
                        Text("3 participants")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                
                // Unread indicator
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Preview of last message
            HStack {
                Text("Instructor:")
                    .fontWeight(.medium)
                Text("Don't forget to bring your gear!")
                    .foregroundColor(.gray)
                Spacer()
                Text("5m")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
        }
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct ConversationRow: View {
    var body: some View {
        HStack(spacing: 16) {
            // Profile Image with status
            ZStack(alignment: .bottomTrailing) {
                Image("instructor_image")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                
                Circle()
                    .fill(Color.green)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 2)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Mike Wilson")
                        .font(.headline)
                    Text("• Instructor")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Text("Let's review your progress from last class")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("2m")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct ChatDetailView: View {
    @State private var messageText = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat header with class info
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    Image("class_image")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Advanced Snowboarding")
                            .font(.headline)
                        Text("Whistler Blackcomb School")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button(action: {}) {
                            Label("View Class Details", systemImage: "info.circle")
                        }
                        Button(action: {}) {
                            Label("Share Location", systemImage: "location")
                        }
                        Button(action: {}) {
                            Label("Clear Chat", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title3)
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                }
                
                // Class time indicator
                HStack {
                    Image(systemName: "clock")
                    Text("Class starts in 14 hours")
                    Spacer()
                    Button("View Details") {}
                }
                .font(.caption)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Messages
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(0..<10) { index in
                        MessageBubble(
                            message: "Hey everyone! Looking forward to tomorrow's class. Make sure to check the weather and dress appropriately!",
                            isFromCurrentUser: index % 3 == 0,
                            senderName: index % 3 == 0 ? "You" : "Mike Wilson",
                            senderRole: index % 3 == 0 ? "" : "Instructor"
                        )
                    }
                }
                .padding()
            }
            
            // Message input
            HStack(spacing: 12) {
                Button(action: {}) {
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                
                Button(action: {}) {
                    Image(systemName: "location")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                
                TextField("Type a message", text: $messageText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                
                Button(action: {}) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MessageBubble: View {
    let message: String
    let isFromCurrentUser: Bool
    let senderName: String
    let senderRole: String
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                HStack {
                    if !isFromCurrentUser {
                        Text(senderName)
                            .fontWeight(.medium)
                        if !senderRole.isEmpty {
                            Text("• \(senderRole)")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(.gray)
                
                Text(message)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(isFromCurrentUser ? Color.blue : Color(.systemGray6))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .cornerRadius(20)
            }
            
            if !isFromCurrentUser { Spacer() }
        }
    }
}

struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView()
    }
} 