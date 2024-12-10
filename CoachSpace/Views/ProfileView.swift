import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        Group {
            if authService.isLoading {
                LoadingView()
            } else if authService.isAuthenticated {
                AuthenticatedProfileView()
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
                .progressViewStyle(CircularProgressViewStyle())
            Text("Loading...")
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
                            .foregroundColor(.blue)
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
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isLoading ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        
                        Button("Forgot Password?") {
                            resetPassword()
                        }
                        .foregroundColor(.blue)
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
                        .cornerRadius(10)
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
                            Text("Admin: admin@example.com")
                            Text("Password for all: password123")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
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
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                if let user = authService.currentUser {
                    Section {
                        VStack(alignment: .center, spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text(user.displayName)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text(user.role.rawValue.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    }
                    
                    Section("Account") {
                        NavigationLink(destination: Text("Edit Profile")) {
                            Label("Edit Profile", systemImage: "person")
                        }
                        
                        NavigationLink(destination: Text("Settings")) {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            signOut()
                        } label: {
                            Label("Sign Out", systemImage: "arrow.right.square")
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Profile")
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
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

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
} 