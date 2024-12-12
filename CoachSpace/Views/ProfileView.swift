import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        Group {
            if authService.isLoading {
                LoadingView()
            } else if authService.isAuthenticated {
                NavigationView {
                    AuthenticatedProfileView()
                }
            } else {
                SignInView()
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
            Text("Please wait...")
                .foregroundColor(.gray)
        }
    }
}

struct SignInView: View {
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSignUp = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Logo and Title
                    VStack(spacing: 8) {
                        Image(systemName: "snow")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        Text("CoachSpace")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                    
                    // Login Form
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .disabled(isLoading)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.password)
                            .disabled(isLoading)
                        
                        Button(action: signIn) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isLoading ? Color.gray : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        
                        Button("Forgot Password?") {
                            resetPassword()
                        }
                        .foregroundColor(.accentColor)
                        .disabled(isLoading)
                        
                        Divider()
                            .padding(.vertical)
                        
                        Button(action: { showSignUp = true }) {
                            Text("Create Account")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isLoading ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(isLoading)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Demo Accounts Info
                    #if DEBUG
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Demo Accounts:")
                            .font(.caption)
                            .fontWeight(.bold)
                        Group {
                            Text("Student: student@example.com")
                            Text("Instructor: instructor@example.com")
                            Text("Password for all: password123")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding()
                    #endif
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func signIn() {
        guard !email.isEmpty && !password.isEmpty else { return }
        
        isLoading = true
        showError = false
        
        Task {
            do {
                print("Attempting to sign in with email: \(email)")
                _ = try await authService.signIn(email: email, password: password)
                print("Sign in successful")
            } catch let error as NSError {
                print("Sign in failed: \(error)")
                if error.domain == AuthErrorDomain {
                    switch error.code {
                    case AuthErrorCode.wrongPassword.rawValue:
                        errorMessage = "Incorrect password. Please try again."
                    case AuthErrorCode.invalidEmail.rawValue:
                        errorMessage = "Invalid email address."
                    case AuthErrorCode.userNotFound.rawValue:
                        errorMessage = "No account found with this email."
                    default:
                        errorMessage = error.localizedDescription
                    }
                } else {
                    errorMessage = error.localizedDescription
                }
                showError = true
            }
            isLoading = false
        }
    }
    
    private func resetPassword() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            showError = true
            return
        }
        
        Task {
            do {
                try await authService.resetPassword(email: email)
                errorMessage = "Password reset email sent. Please check your inbox."
                showError = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct AuthenticatedProfileView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                if let user = authService.currentUser {
                    VStack(spacing: 0) {
                        statsSection(user)
                        Divider()
                        skillsSection(user)
                        Divider()
                        preferencesSection(user)
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditProfile = true }) {
                        Label("Edit Profile", systemImage: "person.crop.circle")
                    }
                    Button(action: { showingSettings = true }) {
                        Label("Settings", systemImage: "gear")
                    }
                    Button(role: .destructive, action: signOut) {
                        Label("Sign Out", systemImage: "arrow.right.square")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            if let user = authService.currentUser {
                ProfileImageView(imageURL: user.imageURL, size: 120)
                    .overlay(
                        Circle()
                            .stroke(Color.accentColor, lineWidth: 4)
                    )
                    .shadow(radius: 10)
                
                VStack(spacing: 8) {
                    Text(user.displayName)
                        .font(.title.bold())
                    
                    HStack {
                        Image(systemName: user.role == .instructor ? "star.circle.fill" : "person.circle.fill")
                        Text(user.role.rawValue.capitalized)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical)
    }
    
    private func statsSection(_ user: User) -> some View {
        VStack(spacing: 16) {
            ProfileSectionHeader(title: "Stats", icon: "chart.bar.fill")
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                StatCard(
                    title: "Classes",
                    value: "\(user.stats.totalClasses)",
                    icon: "heart.fill"
                )
                StatCard(
                    title: "Hours",
                    value: "\(user.stats.totalHours)",
                    icon: "clock.fill"
                )
                StatCard(
                    title: "Rating",
                    value: String(format: "%.1f", user.stats.averageRating),
                    icon: "star.fill"
                )
            }
        }
        .padding(.vertical)
        .background(Color(UIColor.systemBackground))
    }
    
    private func preferencesSection(_ user: User) -> some View {
        VStack(spacing: 16) {
            ProfileSectionHeader(title: "Preferences", icon: "heart.fill")
            
            VStack(spacing: 16) {
                // Categories
                VStack(spacing: 8) {
                    Text("Categories")
                        .font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(user.preferences.preferredCategories, id: \.self) { category in
                                Text(category.rawValue)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.accentColor.opacity(0.1))
                                    .foregroundColor(.accentColor)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // Levels
                VStack(spacing: 8) {
                    Text("Preferred Levels")
                        .font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(user.preferences.preferredLevels, id: \.self) { level in
                                Text(level.rawValue)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.accentColor.opacity(0.1))
                                    .foregroundColor(.accentColor)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // Notifications
                VStack(spacing: 8) {
                    Text("Notifications")
                        .font(.headline)
                    HStack(spacing: 16) {
                        if user.preferences.notifications.classReminders {
                            Label("Classes", systemImage: "bell.fill")
                                .font(.subheadline)
                        }
                        if user.preferences.notifications.messages {
                            Label("Messages", systemImage: "message.fill")
                                .font(.subheadline)
                        }
                        if user.preferences.notifications.email {
                            Label("Email", systemImage: "envelope.fill")
                                .font(.subheadline)
                        }
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical)
        .background(Color(UIColor.systemBackground))
    }
    
    private func skillsSection(_ user: User) -> some View {
        VStack(spacing: 16) {
            ProfileSectionHeader(title: "Skills", icon: "star.fill")
            
            VStack(spacing: 12) {
                ForEach(user.stats.skillLevels, id: \.category) { skill in
                    HStack {
                        Image(systemName: skill.category == .snowboard ? "snowflake" : "figure.skiing")
                            .foregroundColor(.accentColor)
                        Text(skill.category.rawValue)
                            .font(.headline)
                        Spacer()
                        Text(skill.level.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(12)
                }
            }
        }
        .padding(.vertical)
        .background(Color(UIColor.systemBackground))
    }
    
    private func signOut() {
        do {
            try authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Supporting Views

struct ProfileImageView: View {
    let imageURL: String?
    let size: CGFloat
    
    var body: some View {
        if let urlString = imageURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .foregroundColor(.gray)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.title2.bold())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ProfileSectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(title)
                .font(.title2.bold())
        }
    }
}
