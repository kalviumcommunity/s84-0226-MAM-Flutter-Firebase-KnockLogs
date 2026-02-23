import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Initialize GoogleSignIn with Web Client ID for web platform
  late final GoogleSignIn _googleSignIn;

  GoogleAuthService() {
    if (kIsWeb) {
      // Web Client ID from Google Cloud Console
      _googleSignIn = GoogleSignIn(
        clientId:
            '218660413688-h5smgjvc7fvrqfvfq4voam4f29opip42.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
    } else {
      // For mobile platforms
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      User? user = userCredential.user;

      // Save user in Firestore if first time (don't block navigation if this fails)
      if (user != null) {
        try {
          final userDoc = FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid);

          if (!(await userDoc.get()).exists) {
            await userDoc.set({
              "name": user.displayName,
              "email": user.email,
              "profilePicture": user.photoURL,
              "role": "resident", // default role
              "createdAt": Timestamp.now(),
            });
          }
          print("✅ User saved to Firestore successfully");
        } catch (firestoreError) {
          print("⚠️ Firestore save error (but user auth succeeded): $firestoreError");
          // Don't block navigation even if Firestore save fails
          // User is authenticated via Firebase Auth
        }
      }

      return user;
    } catch (e) {
      print("❌ Google Sign-In Error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Check if user is already signed in
  Future<GoogleSignInAccount?> getCurrentUser() async {
    return await _googleSignIn.signInSilently();
  }
}