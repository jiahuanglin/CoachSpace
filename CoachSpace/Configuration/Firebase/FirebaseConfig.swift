import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseMessaging

enum FirebaseError: Error {
    case configurationError
    case authenticationError
    case databaseError
    case storageError
    case messagingError
    case unknown
    
    var description: String {
        switch self {
        case .configurationError: return "Failed to configure Firebase"
        case .authenticationError: return "Authentication error occurred"
        case .databaseError: return "Database error occurred"
        case .storageError: return "Storage error occurred"
        case .messagingError: return "Messaging error occurred"
        case .unknown: return "An unknown error occurred"
        }
    }
}

final class FirebaseConfig: NSObject {
    static let shared = FirebaseConfig()
    private override init() {
        super.init()
    }
    
    func configure() throws {
        guard let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: filePath) else {
            throw FirebaseError.configurationError
        }
        
        FirebaseApp.configure(options: options)
        
        #if DEBUG
        setupEmulators()
        #endif
        
        configureAuth()
        configureMessaging()
    }
    
    private func configureAuth() {
        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
    }
    
    private func configureMessaging() {
        #if !targetEnvironment(simulator)
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        
        Messaging.messaging().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
        #endif
    }
    
    private func setupEmulators() {
        let settings = Firestore.firestore().settings
        settings.host = "localhost:8080"
        settings.cacheSettings = MemoryCacheSettings()
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings
        
        Storage.storage().useEmulator(withHost: "localhost", port: 9199)
    }
}

// MARK: - Messaging Delegate
extension FirebaseConfig: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        #if DEBUG
        print("Firebase registration token: \(String(describing: fcmToken))")
        #endif
        
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
}

// MARK: - UNUserNotificationCenter Delegate
extension FirebaseConfig: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([[.banner, .badge, .sound]])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let messageID = userInfo["gcm.message_id"] as? String {
            print("Message ID: \(messageID)")
        }
        
        completionHandler()
    }
}

// MARK: - Environment
extension FirebaseConfig {
    enum Environment {
        case development
        case staging
        case production
        
        static var current: Environment {
            #if DEBUG
            return .development
            #else
            if let configuration = Bundle.main.object(forInfoDictionaryKey: "Configuration") as? String {
                switch configuration.lowercased() {
                case "staging": return .staging
                case "production": return .production
                default: return .development
                }
            }
            return .production
            #endif
        }
    }
} 