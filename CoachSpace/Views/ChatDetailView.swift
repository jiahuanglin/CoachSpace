import SwiftUI
import CoreLocation

struct ChatDetailView: View {
    @StateObject private var viewModel: ChatDetailViewModel
    @State private var messageText = ""
    @State private var showImagePicker = false
    @State private var showLocationPicker = false
    @State private var selectedImage: UIImage?
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var shouldSendLocation = false
    @Environment(\.dismiss) private var dismiss
    
    init(chatRoom: ChatRoom) {
        _viewModel = StateObject(wrappedValue: ChatDetailViewModel(chatRoom: chatRoom))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat header with class info
            if viewModel.currentChatRoom.type == .classGroup {
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        AsyncImage(url: URL(string: viewModel.currentChatRoom.imageURL ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 40, height: 40)
                        .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.currentChatRoom.name ?? "Class Chat")
                                .font(.headline)
                            if let classId = viewModel.currentChatRoom.classId {
                                Text("Class ID: \(classId)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
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
                }
                .padding()
                .background(Color(.systemBackground))
            }
            
            // Messages
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(
                            message: message,
                            sender: viewModel.participants.first { $0.id == message.senderId }
                        )
                    }
                }
                .padding()
            }
            
            // Message input
            HStack(spacing: 12) {
                Button(action: { showImagePicker = true }) {
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                
                Button(action: { showLocationPicker = true }) {
                    Image(systemName: "location")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                
                TextField("Type a message", text: $messageText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 24))
                        .foregroundColor(!messageText.isEmpty ? .blue : .gray)
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPicker(coordinate: $selectedLocation)
                .onDisappear {
                    if let location = selectedLocation {
                        shouldSendLocation = true
                    }
                }
        }
        .onChange(of: selectedImage) { image in
            if let image = image {
                sendImage(image)
            }
        }
        .onChange(of: shouldSendLocation) { shouldSend in
            if shouldSend {
                if let location = selectedLocation {
                    sendLocation(location)
                }
                shouldSendLocation = false
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        let text = messageText
        messageText = ""
        
        Task {
            try? await viewModel.sendTextMessage(text)
        }
    }
    
    private func sendImage(_ image: UIImage) {
        Task {
            do {
                // First upload image to storage
                let url = try await StorageService.shared.uploadImage(
                    image,
                    path: "chat_images/\(UUID().uuidString).jpg"
                )
                try await viewModel.sendImageMessage(url)
                selectedImage = nil
            } catch {
                viewModel.error = error
            }
        }
    }
    
    private func sendLocation(_ coordinate: CLLocationCoordinate2D) {
        Task {
            try? await viewModel.sendLocationMessage(coordinate: coordinate)
            selectedLocation = nil
        }
    }
}

struct MessageBubble: View {
    let message: Message
    let sender: User?
    @State private var isOnline = false
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isFromCurrentUser {
                    HStack {
                        Text(sender?.displayName ?? "Unknown")
                            .fontWeight(.medium)
                        if let role = sender?.role {
                            Text("• \(role)")
                                .foregroundColor(.blue)
                        }
                        if isOnline {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                
                Group {
                    switch message.type {
                    case .text:
                        Text(message.content)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    case .image:
                        if let imageURL = message.metadata?.imageURL {
                            AsyncImage(url: URL(string: imageURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(maxWidth: 200, maxHeight: 200)
                        }
                    case .location:
                        if let lat = message.metadata?.latitude,
                           let lon = message.metadata?.longitude {
                            MapThumbnail(coordinate: CLLocationCoordinate2D(
                                latitude: lat,
                                longitude: lon
                            ))
                            .frame(width: 200, height: 150)
                            .cornerRadius(12)
                        }
                    case .system:
                        Text(message.content)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    default:
                        Text(message.content)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                }
                .background(isFromCurrentUser ? Color.blue : Color(.systemGray6))
                .foregroundColor(isFromCurrentUser ? .white : .primary)
                .cornerRadius(20)
            }
            
            if !isFromCurrentUser { Spacer() }
        }
        .onAppear {
            if let senderId = sender?.id {
                observePresence(for: senderId)
            }
        }
    }
    
    private var isFromCurrentUser: Bool {
        message.senderId == AuthService.shared.currentUser?.id
    }
    
    private func observePresence(for userId: String) {
        MessagingService.shared.observeUserPresence(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { _ in
            } receiveValue: { status in
                isOnline = status
            }
    }
}

struct MapThumbnail: View {
    let coordinate: CLLocationCoordinate2D
    
    var body: some View {
        // Implement map view here using MapKit
        Color.gray // Placeholder
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct LocationPicker: View {
    @Binding var coordinate: CLLocationCoordinate2D?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // Implement location picker using MapKit
        Text("Location Picker")
            .onTapGesture {
                // For testing, set a dummy location
                coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
                dismiss()
            }
    }
} 