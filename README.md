# KnockLogs

A visitor management and access control system built with Flutter and Firebase. Provides real-time visitor tracking, role-based access control, and QR code verification across multiple platforms.

## Overview

KnockLogs streamlines security operations for residential and commercial properties through intelligent visitor logging, automated QR code verification, and role-based access management. The system supports three primary roles: administrators for system management, guards for on-site verification, and residents for history tracking.

## Core Features

- **Multi-Role Access Control** - Admin, Guard, and Resident roles with Firebase Authentication
- **QR Code Integration** - Generate, distribute, and verify visitor access codes
- **Real-Time Visitor Tracking** - Firestore-powered logging and query system
- **Analytics Dashboard** - Visitor statistics, activity tracking, and trend analysis
- **Cross-Platform Support** - Android, iOS, Web, Windows, macOS, and Linux
- **Google Authentication** - Seamless sign-in integration

## Role-Based Capabilities

### Admin
- QR code generation and distribution
- Complete visitor log access
- User and resident management
- Analytics and reporting dashboard

### Guard
- QR code verification and scanning
- Visitor entry/exit logging
- Real-time access decisions

### Resident
- Visitor history and log access
- Real-time event notifications

## Technical Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.9.2+ |
| Backend | Firebase (Auth, Firestore, Storage) |
| State Management | Provider |
| Authentication | Google Sign-In |
| Integration | QR code generation and scanning |

## Prerequisites

- Flutter SDK 3.9.2 or higher
- Active Firebase project with Firestore database
- Android Studio or Xcode (for native development)
- Git for version control

## Getting Started

1. Clone the repository
   ```bash
   git clone <repository-url>
   cd knocklogs
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Configure Firebase
   ```bash
   flutterfire configure
   ```

4. Run the application
   ```bash
   flutter run -d chrome      # Web
   flutter run -d android     # Android
   flutter run -d ios         # iOS
   ```

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── screens/                  # UI layers
│   ├── admin/                # Admin dashboard and management
│   ├── guard/                # Guard verification interface
│   ├── resident/             # Resident access screens
│   └── auth/                 # Authentication flows
├── services/                 # Business logic and data access
│   ├── admin_service.dart    # Admin operations
│   ├── auth_service.dart     # Authentication
│   └── guard_service.dart    # Guard operations
├── providers/                # State management
│   ├── theme_provider.dart   # Theme and UI state
│   └── analytics_provider.dart # Analytics data
└── firebase_options.dart     # Firebase configuration
```

## Database Schema

The application uses Firestore collections for:
- **users** - User accounts and role assignments
- **access_logs** - Visitor entry and exit records
- **qr_codes** - Generated QR codes and metadata
- **scan_logs** - QR code scan history

## Development Documentation

- [Firebase Setup Guide](MD-files/Firebase.google_setup.md)
- [Android Studio Configuration](MD-files/androidstudio_setup.md)
- [Project Progress](MD-files/Project_progress.md)

## Build & Deployment

### Web Build
```bash
flutter build web --release
```

### Android Build
```bash
flutter build apk --release
```

### iOS Build
```bash
flutter build ios --release
```

## Troubleshooting

### Common Issues
- **Firebase Configuration**: Ensure `google-services.json` is present in `android/app/` and `GoogleService-Info.plist` in iOS
- **Dependency Conflicts**: Run `flutter pub get` and `flutter pub upgrade` as needed
- **Firestore Indexes**: Composite indexes may be required for complex queries; check Firebase console for suggestions

## Contributions

All contributions must follow the existing code structure and testing guidelines. See Contributing.md for details.

## Credits

Crafted with precision and passion by Anu, Mannat, and Manvi.🌸👾

## License

Proprietary - All rights reserved. This project and its contents are owned by Kalvium Community. Unauthorized distribution, modification, or use is prohibited.

## Deploy :
