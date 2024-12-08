import Foundation
import FirebaseFirestore
import Combine

protocol UserServiceProtocol {
    func getUser(id: String) async throws -> User?
    func createUser(_ user: User) async throws
    func updateUser(_ user: User) async throws
    func deleteUser(_ userId: String) async throws
    func updateUserPreferences(_ preferences: User.UserPreferences, for userId: String) async throws
    func updateUserStats(_ stats: User.UserStats, for userId: String) async throws
    func updateUserSettings(_ settings: User.UserSettings, for userId: String) async throws
    func getUsersByRole(_ role: User.UserRole) async throws -> [User]
    func searchUsers(query: String) async throws -> [User]
    func addAchievement(_ achievement: User.UserStats.Achievement, for userId: String) async throws
    func updateSkillLevel(_ skillLevel: User.UserStats.SkillLevel, for userId: String) async throws
}

final class UserService: UserServiceProtocol {
    static let shared = UserService()
    private let db = Firestore.firestore()
    private let storage = StorageService.shared
    
    private init() {}
    
    func getUser(id: String) async throws -> User? {
        do {
            let doc = try await db.collection("users").document(id).getDocument()
            return User.from(doc)
        } catch {
            throw UserError.fetchFailed(error)
        }
    }
    
    func createUser(_ user: User) async throws {
        do {
            try await db.collection("users").document(user.id).setData(user.toFirestore)
        } catch {
            throw UserError.createFailed(error)
        }
    }
    
    func updateUser(_ user: User) async throws {
        do {
            try await db.collection("users").document(user.id).updateData(user.toFirestore)
        } catch {
            throw UserError.updateFailed(error)
        }
    }
    
    func deleteUser(_ userId: String) async throws {
        do {
            // Delete user data
            try await db.collection("users").document(userId).delete()
            
            // Delete user profile image if exists
            if let user = try await getUser(id: userId),
               let imageURL = user.imageURL {
                try await storage.deleteImage(at: imageURL)
            }
            
            // Delete related data (bookings, messages, etc.)
            try await cleanupUserData(userId)
        } catch {
            throw UserError.deleteFailed(error)
        }
    }
    
    func updateUserPreferences(_ preferences: User.UserPreferences, for userId: String) async throws {
        do {
            let data = try Firestore.Encoder().encode(preferences)
            try await db.collection("users").document(userId).updateData(["preferences": data])
        } catch {
            throw UserError.updatePreferencesFailed(error)
        }
    }
    
    func updateUserStats(_ stats: User.UserStats, for userId: String) async throws {
        do {
            let data = try Firestore.Encoder().encode(stats)
            try await db.collection("users").document(userId).updateData(["stats": data])
        } catch {
            throw UserError.updateStatsFailed(error)
        }
    }
    
    func updateUserSettings(_ settings: User.UserSettings, for userId: String) async throws {
        do {
            let data = try Firestore.Encoder().encode(settings)
            try await db.collection("users").document(userId).updateData(["settings": data])
        } catch {
            throw UserError.updateSettingsFailed(error)
        }
    }
    
    func getUsersByRole(_ role: User.UserRole) async throws -> [User] {
        do {
            let snapshot = try await db.collection("users")
                .whereField("role", isEqualTo: role.rawValue)
                .getDocuments()
            return snapshot.documents.compactMap { User.from($0) }
        } catch {
            throw UserError.fetchFailed(error)
        }
    }
    
    func searchUsers(query: String) async throws -> [User] {
        do {
            let snapshot = try await db.collection("users")
                .whereField("displayName", isGreaterThanOrEqualTo: query)
                .whereField("displayName", isLessThanOrEqualTo: query + "\u{f8ff}")
                .getDocuments()
            return snapshot.documents.compactMap { User.from($0) }
        } catch {
            throw UserError.searchFailed(error)
        }
    }
    
    func addAchievement(_ achievement: User.UserStats.Achievement, for userId: String) async throws {
        do {
            guard let user = try await getUser(id: userId) else {
                throw UserError.userNotFound
            }
            
            // Create new stats with updated achievements
            let updatedStats = User.UserStats(
                totalClasses: user.stats.totalClasses,
                totalHours: user.stats.totalHours,
                averageRating: user.stats.averageRating,
                skillLevels: user.stats.skillLevels,
                achievements: user.stats.achievements + [achievement]
            )
            
            try await updateUserStats(updatedStats, for: userId)
            
            NotificationCenter.default.post(
                name: .UserAchievementAdded,
                object: nil,
                userInfo: ["userId": userId, "achievement": achievement]
            )
        } catch {
            throw UserError.updateAchievementFailed(error)
        }
    }
    
    func updateSkillLevel(_ skillLevel: User.UserStats.SkillLevel, for userId: String) async throws {
        do {
            guard let user = try await getUser(id: userId) else {
                throw UserError.userNotFound
            }
            
            // Create new skill levels array with updated level
            var updatedSkillLevels = user.stats.skillLevels
            if let index = updatedSkillLevels.firstIndex(where: { $0.category == skillLevel.category }) {
                updatedSkillLevels[index] = skillLevel
            } else {
                updatedSkillLevels.append(skillLevel)
            }
            
            // Create new stats with updated skill levels
            let updatedStats = User.UserStats(
                totalClasses: user.stats.totalClasses,
                totalHours: user.stats.totalHours,
                averageRating: user.stats.averageRating,
                skillLevels: updatedSkillLevels,
                achievements: user.stats.achievements
            )
            
            try await updateUserStats(updatedStats, for: userId)
            
            NotificationCenter.default.post(
                name: .UserSkillLevelUpdated,
                object: nil,
                userInfo: ["userId": userId, "skillLevel": skillLevel]
            )
        } catch {
            throw UserError.updateSkillLevelFailed(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func cleanupUserData(_ userId: String) async throws {
        // Delete user's bookings
        let bookings = try await db.collection("bookings")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        for booking in bookings.documents {
            try await booking.reference.delete()
        }
        
        // Delete user's chat rooms and messages
        let chatRooms = try await db.collection("chatRooms")
            .whereField("participants", arrayContains: userId)
            .getDocuments()
        
        for chatRoom in chatRooms.documents {
            let messages = try await chatRoom.reference.collection("messages").getDocuments()
            for message in messages.documents {
                try await message.reference.delete()
            }
            try await chatRoom.reference.delete()
        }
    }
}

// MARK: - Errors
enum UserError: LocalizedError {
    case fetchFailed(Error)
    case createFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case updatePreferencesFailed(Error)
    case updateStatsFailed(Error)
    case updateSettingsFailed(Error)
    case updateAchievementFailed(Error)
    case updateSkillLevelFailed(Error)
    case searchFailed(Error)
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error): return "Failed to fetch user: \(error.localizedDescription)"
        case .createFailed(let error): return "Failed to create user: \(error.localizedDescription)"
        case .updateFailed(let error): return "Failed to update user: \(error.localizedDescription)"
        case .deleteFailed(let error): return "Failed to delete user: \(error.localizedDescription)"
        case .updatePreferencesFailed(let error): return "Failed to update preferences: \(error.localizedDescription)"
        case .updateStatsFailed(let error): return "Failed to update stats: \(error.localizedDescription)"
        case .updateSettingsFailed(let error): return "Failed to update settings: \(error.localizedDescription)"
        case .updateAchievementFailed(let error): return "Failed to update achievement: \(error.localizedDescription)"
        case .updateSkillLevelFailed(let error): return "Failed to update skill level: \(error.localizedDescription)"
        case .searchFailed(let error): return "Failed to search users: \(error.localizedDescription)"
        case .userNotFound: return "User not found"
        }
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let UserAchievementAdded = Notification.Name("UserAchievementAdded")
    static let UserSkillLevelUpdated = Notification.Name("UserSkillLevelUpdated")
} 