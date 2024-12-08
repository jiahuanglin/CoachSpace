import SwiftUI

struct ProfileView: View {
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                AuthenticatedProfileView()
            } else {
                LoginView()
            }
        }
    }
}

struct AuthenticatedProfileView: View {
    @StateObject private var authService = AuthService.shared
    
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
                            authService.signOut()
                        } label: {
                            Label("Sign Out", systemImage: "arrow.right.square")
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
} 