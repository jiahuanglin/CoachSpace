import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
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
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.password)
                    
                    Button(action: login) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign In")
                                .fontWeight(.medium)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(isLoading)
                }
                .padding(.horizontal)
                
                // Test Credentials
                #if DEBUG
                VStack(spacing: 12) {
                    Text("Test Credentials")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
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
                
                Spacer()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func login() {
        isLoading = true
        showError = false
        
        Task {
            do {
                try await authService.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
} 