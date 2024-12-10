import Foundation
import FirebaseAuth
import Combine

protocol AuthServiceProtocol {
    func signIn(email: String, password: String) async throws -> User
    func signUp(email: String, password: String, displayName: String) async throws -> User
    func signOut() throws
    func resetPassword(email: String) async throws
    func updatePassword(currentPassword: String, newPassword: String) async throws
    func deleteAccount() async throws
    func getCurrentUser() -> User?
    var authStatePublisher: AnyPublisher<User?, Never> { get }
}

@MainActor
final class AuthService: ObservableObject, AuthServiceProtocol {
    static let shared = AuthService()
    private let auth = Auth.auth()
    private let userService = UserService.shared
    
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = true
    
    private init() {
        setupAuthStateListener()
        checkInitialAuthState()
    }
    
    private func checkInitialAuthState() {
        if let firebaseUser = auth.currentUser {
            Task {
                isLoading = true
                if let user = try? await userService.getUser(id: firebaseUser.uid) {
                    currentUser = user
                    isAuthenticated = true
                }
                isLoading = false
            }
        } else {
            isLoading = false
        }
    }
    
    private func setupAuthStateListener() {
        auth.addStateDidChangeListener { [weak self] _, user in
            Task {
                if let user = user {
                    self?.isLoading = true
                    if let userData = try? await self?.userService.getUser(id: user.uid) {
                        self?.currentUser = userData
                        self?.isAuthenticated = true
                    } else {
                        // If we can't get user data, create a placeholder
                        self?.currentUser = self?.createPlaceholderUser(from: user)
                        self?.isAuthenticated = true
                    }
                    self?.isLoading = false
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                    self?.isLoading = false
                }
            }
        }
    }
    
    private func createPlaceholderUser(from firebaseUser: FirebaseAuth.User) -> User {
        User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            displayName: firebaseUser.displayName ?? "User",
            phoneNumber: firebaseUser.phoneNumber,
            imageURL: firebaseUser.photoURL?.absoluteString,
            role: .student,
            preferences: .init(
                preferredCategories: [],
                preferredLevels: [],
                preferredInstructors: [],
                preferredVenues: [],
                equipment: .init(
                    hasOwnEquipment: false,
                    equipmentDetails: [],
                    preferredRentalLocation: nil
                ),
                notifications: .init(
                    classReminders: true,
                    promotions: true,
                    messages: true,
                    email: true,
                    push: true,
                    sms: false
                )
            ),
            stats: .init(
                totalClasses: 0,
                totalHours: 0,
                averageRating: 0,
                skillLevels: [],
                achievements: []
            ),
            settings: .init(
                language: Locale.current.language.languageCode?.identifier ?? "en",
                timezone: TimeZone.current.identifier,
                currency: Locale.current.currency?.identifier ?? "USD",
                measurementSystem: .metric
            ),
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    var authStatePublisher: AnyPublisher<User?, Never> {
        NotificationCenter.default.publisher(for: .AuthStateDidChange)
            .compactMap { [weak self] _ in
                self?.getCurrentUser()
            }
            .eraseToAnyPublisher()
    }
    
    func signIn(email: String, password: String) async throws -> User {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            guard let user = try await userService.getUser(id: result.user.uid) else {
                throw AuthError.userNotFound
            }
            NotificationCenter.default.post(name: .AuthStateDidChange, object: nil)
            return user
        } catch {
            throw AuthError.signInFailed(error)
        }
    }
    
    func signUp(email: String, password: String, displayName: String) async throws -> User {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let user = User(
                id: result.user.uid,
                email: email,
                displayName: displayName,
                phoneNumber: nil,
                imageURL: nil,
                role: .student,
                preferences: User.UserPreferences(
                    preferredCategories: [],
                    preferredLevels: [],
                    preferredInstructors: [],
                    preferredVenues: [],
                    equipment: .init(
                        hasOwnEquipment: false,
                        equipmentDetails: [],
                        preferredRentalLocation: nil
                    ),
                    notifications: .init(
                        classReminders: true,
                        promotions: true,
                        messages: true,
                        email: true,
                        push: true,
                        sms: false
                    )
                ),
                stats: User.UserStats(
                    totalClasses: 0,
                    totalHours: 0,
                    averageRating: 0,
                    skillLevels: [],
                    achievements: []
                ),
                settings: User.UserSettings(
                    language: Locale.current.language.languageCode?.identifier ?? "en",
                    timezone: TimeZone.current.identifier,
                    currency: Locale.current.currency?.identifier ?? "USD",
                    measurementSystem: .metric
                ),
                status: .active,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await userService.createUser(user)
            NotificationCenter.default.post(name: .AuthStateDidChange, object: nil)
            return user
        } catch {
            throw AuthError.signUpFailed(error)
        }
    }
    
    func signOut() throws {
        do {
            try auth.signOut()
            NotificationCenter.default.post(name: .AuthStateDidChange, object: nil)
        } catch {
            throw AuthError.signOutFailed(error)
        }
    }
    
    func resetPassword(email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch {
            throw AuthError.resetPasswordFailed(error)
        }
    }
    
    func updatePassword(currentPassword: String, newPassword: String) async throws {
        guard let email = auth.currentUser?.email else {
            throw AuthError.userNotFound
        }
        
        do {
            // Reauthenticate user
            let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
            try await auth.currentUser?.reauthenticate(with: credential)
            
            // Update password
            try await auth.currentUser?.updatePassword(to: newPassword)
        } catch {
            throw AuthError.updatePasswordFailed(error)
        }
    }
    
    func deleteAccount() async throws {
        do {
            try await auth.currentUser?.delete()
            NotificationCenter.default.post(name: .AuthStateDidChange, object: nil)
        } catch {
            throw AuthError.deleteAccountFailed(error)
        }
    }
    
    func getCurrentUser() -> User? {
        guard let firebaseUser = auth.currentUser else { return nil }
        // Since we can't use async here, we'll return a placeholder user
        // The actual user data should be fetched separately when needed
        return User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            displayName: firebaseUser.displayName ?? "",
            phoneNumber: firebaseUser.phoneNumber,
            imageURL: firebaseUser.photoURL?.absoluteString,
            role: .student,
            preferences: .init(
                preferredCategories: [],
                preferredLevels: [],
                preferredInstructors: [],
                preferredVenues: [],
                equipment: .init(
                    hasOwnEquipment: false,
                    equipmentDetails: [],
                    preferredRentalLocation: nil
                ),
                notifications: .init(
                    classReminders: true,
                    promotions: true,
                    messages: true,
                    email: true,
                    push: true,
                    sms: false
                )
            ),
            stats: .init(
                totalClasses: 0,
                totalHours: 0,
                averageRating: 0,
                skillLevels: [],
                achievements: []
            ),
            settings: .init(
                language: Locale.current.language.languageCode?.identifier ?? "en",
                timezone: TimeZone.current.identifier,
                currency: Locale.current.currency?.identifier ?? "USD",
                measurementSystem: .metric
            ),
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Errors
enum AuthError: LocalizedError {
    case signInFailed(Error)
    case signUpFailed(Error)
    case signOutFailed(Error)
    case resetPasswordFailed(Error)
    case updatePasswordFailed(Error)
    case deleteAccountFailed(Error)
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .signInFailed(let error): return "Failed to sign in: \(error.localizedDescription)"
        case .signUpFailed(let error): return "Failed to sign up: \(error.localizedDescription)"
        case .signOutFailed(let error): return "Failed to sign out: \(error.localizedDescription)"
        case .resetPasswordFailed(let error): return "Failed to reset password: \(error.localizedDescription)"
        case .updatePasswordFailed(let error): return "Failed to update password: \(error.localizedDescription)"
        case .deleteAccountFailed(let error): return "Failed to delete account: \(error.localizedDescription)"
        case .userNotFound: return "User not found"
        }
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let AuthStateDidChange = Notification.Name("AuthStateDidChange")
} 