import Foundation

// MARK: - Notification Names
// Centralized declaration of notification names to avoid conflicts
enum NotificationNames {
    // Class-related notifications
    static let ClassBooked = Notification.Name("com.coachspace.notifications.classBooked")
    static let ClassCancelled = Notification.Name("com.coachspace.notifications.classCancelled")
    static let ClassReviewAdded = Notification.Name("com.coachspace.notifications.classReviewAdded")
    static let BookingStatusChanged = Notification.Name("com.coachspace.notifications.bookingStatusChanged")
    
    // User achievement notifications
    static let UserAchievementAdded = Notification.Name("com.coachspace.notifications.achievementAdded")
    static let UserSkillLevelUpdated = Notification.Name("com.coachspace.notifications.skillLevelUpdated")
    
    // System notifications
    static let FCMTokenRefreshed = Notification.Name("com.coachspace.notifications.fcmTokenRefreshed")
} 