# KnockLogs - Daily Progress Log

A day-by-day log of what we built and how we built it.

---

## Day 1 — Project Setup & Firebase Integration

### 1. Created Flutter Project
- Created a new Flutter project called `knocklogs`.
- Cleaned up default boilerplate code.

### 2. Set Up Firebase
- Created a new Firebase project on [Firebase Console](https://console.firebase.google.com/).
- Installed the FlutterFire CLI:
  ```
  dart pub global activate flutterfire_cli
  ```
- Ran the following command to connect Firebase to the Flutter app:
  ```
  flutterfire configure
  ```
- This auto-generated `lib/firebase_options.dart` with platform-specific Firebase config.

### 3. Added Firebase Dependencies
Added the following packages in `pubspec.yaml`:
```yaml
firebase_core: ^2.25.4
firebase_auth: ^4.17.4
cloud_firestore: ^4.15.4
firebase_storage: ^11.6.5
google_sign_in: ^6.2.1
```
Then ran:
```
flutter pub get
```

### 4. Initialized Firebase in `main.dart`
- Called `WidgetsFlutterBinding.ensureInitialized()` before `runApp`.
- Initialized Firebase using `Firebase.initializeApp()` with options from `firebase_options.dart`.
- Set `LoginScreen` as the home screen.

---

## Day 2 — Authentication

### 5. Email & Password Login (`AuthService`)
- Created `lib/services/auth_service.dart`.
- Used `FirebaseAuth` to sign in with email and password.
- After login, fetched the user's document from Firestore (`users` collection) using their `uid`.
- Returned the user's `role` field (e.g., `admin`, `guard`, `resident`) to navigate to the correct screen.

### 6. Login Screen UI
- Created `lib/screens/auth/login_screen.dart` with:
  - Email and password text fields.
  - A **Login** button that calls `AuthService.login()`.
  - A **Sign in with Google** button.
  - Error handling with `SnackBar` messages.

### 7. Register Screen
- Created `lib/screens/auth/register_screen.dart` for new user sign-up.

---

## Day 3 — Google Authentication

### 8. Set Up Google Sign-In
- Enabled **Google** as a sign-in provider in Firebase Console → Authentication → Sign-in methods.
- Added the `google_sign_in` package.

### 9. Created `GoogleAuthService`
- Created `lib/services/google_auth_service.dart`.
- Handles two cases:
  - **Web**: Uses `clientId` (Web Client ID from Google Cloud Console).
  - **Mobile**: No `clientId` needed, uses `google-services.json` / `GoogleService-Info.plist`.
- Flow:
  1. Opens Google Sign-In popup/sheet.
  2. Gets `accessToken` and `idToken` from Google.
  3. Creates a Firebase credential and signs in via `FirebaseAuth`.
  4. Checks Firestore if the user already exists — if not, creates a new doc with default role `resident`.

### 10. Firestore User Document Structure
When a new Google user signs in for the first time, a document is saved in `users/{uid}`:
```json
{
  "name": "User's Name",
  "email": "user@gmail.com",
  "profilePicture": "<photo_url>",
  "role": "resident",
  "createdAt": "<timestamp>"
}
```

### 11. Role-Based Navigation
- After login (email or Google), the app reads the `role` from Firestore.
- Navigates to the correct dashboard:
  - `admin` → Admin screen
  - `guard` → Guard screen
  - `resident` → Resident screen

---
