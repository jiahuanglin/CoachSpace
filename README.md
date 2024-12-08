# CoachSpace

CoachSpace is an iOS application that connects students with instructors for sports classes, featuring real-time messaging, class scheduling, and progress tracking.

## Prerequisites

- Xcode 14.0+
- iOS 15.0+
- Swift 5.5+
- CocoaPods or Swift Package Manager
- Firebase CLI tools
- Node.js 14+ (for Firebase Emulator)

## Local Development Setup

1. Clone the repository:

```bash
git clone https://github.com/yourusername/CoachSpace.git
cd CoachSpace
```

2. Install dependencies:

```bash
pod install
# or if using SPM, Xcode will handle this automatically
```

3. Set up Firebase:
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Download `GoogleService-Info.plist` and add it to your Xcode project
   - Enable Authentication, Firestore, and Storage in Firebase Console

4. Install and configure Firebase emulators:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase project
firebase init

# Select the following features:
# - Firestore Emulator
# - Authentication Emulator
# - Storage Emulator

# Start emulators
firebase emulators:start
```

5. Configure local environment:
   - Create a new scheme in Xcode for local development
   - Add environment variables:
     ```
     FIRESTORE_EMULATOR_HOST=localhost:8080
     FIREBASE_AUTH_EMULATOR_HOST=localhost:9099
     FIREBASE_STORAGE_EMULATOR_HOST=localhost:9199
     ```

## Development Workflow

### Running the App Locally

1. Start Firebase emulators:

```bash
firebase emulators:start
```

2. In Xcode:
   - Select the "Local Development" scheme
   - Choose your target device/simulator
   - Run the app (⌘R)

3. Verify emulator connection:
   - Check Xcode console for emulator connection messages
   - Use Firebase Emulator UI (http://localhost:4000) to monitor requests

### Database Setup

1. Initialize Firestore with test data:

```bash
# From project root
./scripts/init-test-data.sh
```

2. Monitor database:
   - Open Firebase Emulator UI: http://localhost:4000
   - Navigate to Firestore tab
   - View real-time updates

## Testing

### Setting Up Test Environment

1. Configure test Firebase project:
   - Create a separate Firebase project for testing
   - Update `FirebaseTestSetup.swift` with test credentials:
   ```swift
   let options = FirebaseOptions(
       googleAppID: "test-app-id",
       gcmSenderID: "test-sender-id"
   )
   options.projectID = "test-project-id"
   options.apiKey = "test-api-key"
   ```

2. Start emulators in test mode:

```bash
firebase emulators:start --only firestore,auth,storage
```

### Running Tests

1. Unit Tests in Xcode:
   ```
   # Run all tests
   ⌘U

   # Run specific test
   Control + Option + ⌘U (select test)
   ```

2. Command Line Testing:

```bash
# Run all tests
xcodebuild test \
  -workspace CoachSpace.xcworkspace \
  -scheme CoachSpace \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -enableCodeCoverage YES

# Run specific test class
xcodebuild test \
  -workspace CoachSpace.xcworkspace \
  -scheme CoachSpace \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -only-testing:CoachSpaceTests/MessagingServiceTests
```

3. Continuous Integration:

```bash
# Install dependencies
bundle install

# Run tests with Fastlane
bundle exec fastlane test
```

### Test Coverage

1. Generate coverage report:

```bash
xcodebuild test \
  -workspace CoachSpace.xcworkspace \
  -scheme CoachSpace \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult

# Convert to HTML report
xcrun xccov view --report TestResults.xcresult
```

2. View in Xcode:
   - Open Report navigator (⌘9)
   - Select latest test run
   - Click Coverage tab

## Deployment

### Development

1. Configure development environment:
   - Update `GoogleService-Info.plist` with dev credentials
   - Set up dev provisioning profile
   - Use dev Firebase instance

2. Deploy to TestFlight:

```bash
bundle exec fastlane beta
```

### Production

1. Pre-deployment checklist:
   - Update version/build numbers
   - Run full test suite
   - Check analytics integration
   - Verify production credentials

2. Deploy to App Store:

```bash
bundle exec fastlane release
```

3. Post-deployment:
   - Monitor crash reports
   - Check analytics
   - Verify production database

## Project Structure

```
CoachSpace/
├── App/                # App entry point and configuration
├── Services/           # Core services and API clients
│   ├── Messaging/     # Real-time messaging
│   ├── Class/         # Class management
│   └── User/          # User management
├── Models/            # Data models
├── Views/             # SwiftUI views
├── ViewModels/        # View models
├── Tests/             # Test files
│   ├── Unit/         # Unit tests
│   ├── Integration/  # Integration tests
│   └── Mocks/        # Test mocks and stubs
└── Resources/         # Assets and configuration files
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Troubleshooting

### Common Issues

1. Emulator Connection:

```bash
# Reset emulator
firebase emulators:stop
firebase emulators:start --clear-data

# Check ports
lsof -i :8080  # Firestore
lsof -i :9099  # Auth
lsof -i :9199  # Storage
```

2. Test Failures:

```bash
# Clean build
xcodebuild clean

# Reset simulator
xcrun simctl erase all
```

### Getting Help

- Check Firebase logs in Emulator UI
- Review Xcode Console output
- File an issue on GitHub

## License

This project is licensed under the MIT License - see the LICENSE file for details 