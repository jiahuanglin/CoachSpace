//
//  CoachSpaceApp.swift
//  CoachSpace
//
//  Created by Lin, Jacob on 2024-12-07.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import Network

class AppDelegate: NSObject, UIApplicationDelegate {
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "NetworkMonitor")
    
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true // Enable offline persistence
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited // Unlimited cache size
        
        #if DEBUG
        // Configure to use emulators
        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
        settings.host = "localhost:8080"
        settings.isPersistenceEnabled = false
        settings.isSSLEnabled = false
        #endif
        
        // Apply Firestore settings
        Firestore.firestore().settings = settings
        
        // Start monitoring network
        startNetworkMonitoring()
        
        return true
    }
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("Internet connection is available")
                // Reconnect to Firestore if needed
                Firestore.firestore().enableNetwork { error in
                    if let error = error {
                        print("Error enabling Firestore network: \(error)")
                    }
                }
            } else {
                print("No internet connection")
                // Disable network operations to use cache
                Firestore.firestore().disableNetwork { error in
                    if let error = error {
                        print("Error disabling Firestore network: \(error)")
                    }
                }
            }
        }
        monitor.start(queue: queue)
    }
}

@main
struct CoachSpaceApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
