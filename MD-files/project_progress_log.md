# Project Progress Log

This document tracks the daily progress and steps followed in the development of the KnockLogs application.

## 1. Project Initialization
- Created a new Flutter project.
- Organized folder structure (`lib/screens`, `lib/services`, `lib/models`, `MD-files`).
- Verified `.gitignore` to exclude build artifacts and sensitive files.

## 2. Firebase Setup
- Created a new project in the Firebase Console.
- Installed FlutterFire CLI.
- Ran `flutterfire configure` to generate `firebase_options.dart`.
- Added `firebase_core` dependency associated with the project.
- Initialized Firebase in `main.dart` using `Firebase.initializeApp()`.

## 3. Authentication Implementation
- Enabled **Email/Password** sign-in method in Firebase Console.
- Added `firebase_auth` dependency.
- Created `AuthService` class to manage user sessions.
- Built `LoginScreen` with email and password fields.

## 4. Google Authentication Setup
- Enabled **Google** sign-in method in Firebase Console.
- Generated SHA-1 and SHA-256 fingerprints using `keytool` and added them to Firebase Android App settings.
- Downloaded updated `google-services.json` and placed it in `android/app/`.
- Added `google_sign_in` dependency.
- Implemented Google Sign-In logic in `AuthService` (handling credential retrieval and Firebase authentication).

---

# Daily Work Log

## [Current Date]
- Documented project setup steps.
- Validated folder structure.
