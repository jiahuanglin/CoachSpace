# CoachSpace

A winter sports class booking application that connects students with instructors for snowboarding and skiing lessons.

## Features

- Browse and book snowboard/ski classes
- Real-time messaging with instructors
- Track learning progress
- View class schedules and instructor details
- Manage bookings and payments
- Progress tracking and achievements

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.0+
- CocoaPods or Swift Package Manager
- Firebase project

## Setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/CoachSpace.git
cd CoachSpace
```

### 2. Firebase Setup

#### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project or select an existing one
3. Add an iOS app:
   - Bundle ID: `com.yourcompany.CoachSpace`
   - App nickname: `CoachSpace`
   - App Store ID: (optional)

#### 2. Configure Firebase in Xcode

1. Download `GoogleService-Info.plist`:
   - Download from Firebase Console
   - Add to Xcode project (drag & drop)
   - Make sure "Copy items if needed" is checked
   - Add to all targets that need Firebase

2. Add Firebase SDK using Swift Package Manager:
   ```
   File > Add Packages...
   Search: https://github.com/firebase/firebase-ios-sdk.git
   ```

3. Select the following Firebase products:
   - FirebaseAnalytics
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseStorage
   - FirebaseMessaging

4. Update your target's minimum deployment target to iOS 13.0 or later

5. Initialize Firebase in your app:
   ```swift
   import FirebaseCore
   
   class AppDelegate: NSObject, UIApplicationDelegate {
       func application(_ application: UIApplication,
                      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
           do {
               try FirebaseConfig.shared.configure()
           } catch {
               print("Firebase configuration failed: \(error)")
           }
           return true
       }
   }
   ```

#### 3. Enable Firebase Services

1. Authentication:
   - Go to Authentication > Sign-in method
   - Enable Email/Password
   - Add other providers as needed

2. Firestore Database:
   - Create database in test mode
   - Set up security rules
   - Create indexes for queries

3. Storage:
   - Set up security rules
   - Configure CORS if needed

#### 4. Local Development

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Login and initialize:
   ```bash
   firebase login
   firebase init
   ```

3. Start emulators:
   ```bash
   firebase emulators:start
   ```

#### 5. Database Schema Setup

Run the following commands in your terminal to set up the Firestore security rules and indexes:

```bash
firebase login
firebase init firestore
firebase deploy --only firestore:rules,firestore:indexes
```

## Development

### Building the Project

1. Open `CoachSpace.xcodeproj` in Xcode
2. Select your target device/simulator
3. Build (⌘B) and Run (⌘R)

### Testing

1. Unit Tests: ⌘U to run all tests
2. UI Tests: Select the UI Test target and run ⌘U

### Deployment

1. Configure your signing certificate in Xcode
2. Update version and build numbers
3. Archive and upload to App Store Connect

## Architecture

The app follows the MVVM (Model-View-ViewModel) architecture pattern with the following components:

- **Models**: Data structures and business logic
- **Views**: SwiftUI views and UI components
- **ViewModels**: Business logic and data transformation
- **Services**: Firebase and API integrations

### Directory Structure

```
CoachSpace/
├── Models/
│   ├── Class.swift
│   ├── Instructor.swift
│   ├── Venue.swift
│   ├── Message.swift
│   └── User.swift
├── Views/
│   ├── Home/
│   ├── Schedule/
│   ├── Progress/
│   ├── Messages/
│   └── Profile/
├── ViewModels/
├── Services/
│   ├── Auth/
│   │   └── AuthService.swift
│   ├── User/
│   │   └── UserService.swift
│   ├── Storage/
│   │   └── StorageService.swift
│   ├── Class/
│   │   └── ClassService.swift
│   ├── Messaging/
│   │   └── MessagingService.swift
│   └── Venue/
│       └── VenueService.swift
└── Configuration/
    └── Firebase/
```

## Firebase Collections

### Users
```json
{
  "users": {
    "userId": {
      "email": "string",
      "displayName": "string",
      "role": "string",
      "preferences": {
        "categories": ["string"],
        "levels": ["string"]
      }
    }
  }
}
```

### Classes
```json
{
  "classes": {
    "classId": {
      "name": "string",
      "instructorId": "string",
      "category": "string",
      "level": "string",
      "startTime": "timestamp",
      "duration": "number"
    }
  }
}
```

## License

This project is available under the MIT license. 