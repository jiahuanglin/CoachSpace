//
//  CoachSpaceApp.swift
//  CoachSpace
//
//  Created by Lin, Jacob on 2024-12-07.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

@main
struct CoachSpaceApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
