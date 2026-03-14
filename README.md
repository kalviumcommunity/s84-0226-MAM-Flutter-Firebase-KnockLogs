# KnockLogs

A modern visitor log management application built with Flutter and Firebase. Streamline security and access control for residential and commercial properties.

## Features

- **Multi-role Authentication** - Admin, Resident, and Guard roles with Firebase Auth
- **Google Sign-In** - Seamless authentication via Google
- **QR Code Management** - Generate and scan QR codes for visitor verification
- **Visitor Logs** - Real-time tracking and management of visitor entries
- **Cloud Storage** - Secure file storage with Firebase Storage
- **Cross-Platform** - Native support for Android, iOS, Web, Windows, macOS, and Linux

## Tech Stack

- **Frontend**: Flutter 3.9.2+
- **Backend**: Firebase (Auth, Firestore, Storage)
- **State Management**: Provider
- **Additional**: Google Sign-In, QR Flutter, Mobile Scanner

## Quick Start

### Prerequisites

- Flutter SDK: ^3.9.2
- Firebase project configured
- Android/iOS development environment

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd knocklogs
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   ```bash
   flutterfire configure
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart              # App entry point
├── screens/               # UI screens (admin, auth, guard, landing, resident)
├── services/              # Business logic (auth, admin, guard, resident)
├── providers/             # State management (theme, etc.)
└── firebase_options.dart  # Firebase configuration
```

## Documentation

- [Firebase Setup](MD-files/Firebase.google_setup.md)
- [Android Studio Setup](MD-files/androidstudio_setup.md)
- [Project Progress](MD-files/Project_progress.md)

## License

Proprietary - All rights reserved
