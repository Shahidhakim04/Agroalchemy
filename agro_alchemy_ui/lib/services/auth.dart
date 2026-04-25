import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final userStream = FirebaseAuth.instance.authStateChanges();
  final user = FirebaseAuth.instance.currentUser;

  // Rate limiting for Firestore updates
  static DateTime? _lastUpdate;
  static const _minimumUpdateInterval = Duration(minutes: 5);

  Future<void> _createOrUpdateUser(
    User user, {
    String? customDisplayName,
    bool isAnonymous = false,
  }) async {
    try {
      print('Creating/updating user document for UID: ${user.uid}');
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      // Check if we need to enforce rate limiting for updates
      final now = DateTime.now();
      if (_lastUpdate != null) {
        final timeSinceLastUpdate = now.difference(_lastUpdate!);
        if (timeSinceLastUpdate < _minimumUpdateInterval) {
          print('Skipping update due to rate limiting');
          return;
        }
      }

      try {
        await userRef.set({
          'displayName':
              customDisplayName ?? user.displayName ?? 'Unknown User',
          'photoURL': user.photoURL,
          'email': user.email,
          if (_lastUpdate == null) 'createdAt': FieldValue.serverTimestamp(),
          'lastSignIn': FieldValue.serverTimestamp(),
          'isAnonymous': isAnonymous,
        }, SetOptions(merge: true));

        _lastUpdate = now;
        print('User document created/updated successfully');
      } on FirebaseException catch (e) {
        if (e.code == 'resource-exhausted') {
          print('Quota exceeded, will retry later');
          // Don't throw here, let the user continue using the app
          return;
        }
        rethrow;
      }
    } catch (e) {
      print('Error creating/updating user document: $e');
      // Don't throw here to allow the user to continue using the app
      return;
    }
  }

  Future<void> anonLogin() async {
    try {
      print('Starting anonymous login...');
      final userCredential = await FirebaseAuth.instance.signInAnonymously();

      if (userCredential.user != null) {
        try {
          await _createOrUpdateUser(
            userCredential.user!,
            customDisplayName: 'Anonymous User',
            isAnonymous: true,
          ).timeout(const Duration(seconds: 3));
        } catch (_) {
          // Ignore timeout or other errors during user creation to allow login to proceed
        }
      }
    } on FirebaseAuthException catch (e) {
      print('Anonymous login error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error during anonymous login: $e');
      rethrow;
    }
  }

  Future<void> googleLogin() async {
    try {
      print('Starting Google sign in process...');

      if (kIsWeb) {
        // On web, use Firebase's signInWithPopup (authenticate() is not supported)
        final userCredential = await FirebaseAuth.instance.signInWithPopup(
          GoogleAuthProvider(),
        );
        if (userCredential.user != null) {
          // Try to create user doc with short timeout so dashboard has data
          try {
            await _createOrUpdateUser(userCredential.user!)
                .timeout(const Duration(seconds: 3));
          } catch (_) {}
        }
        return;
      }

      // Mobile: use Google Sign-In then Firebase credential
      final googleUser = await GoogleSignIn.instance.authenticate();

      print('Getting Google auth tokens...');
      final googleAuth = googleUser.authentication;
      final authCredential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      print('Signing in to Firebase with Google credentials...');
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        authCredential,
      );

      if (userCredential.user != null) {
        await _createOrUpdateUser(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      print(
        'Firebase Auth error during Google login: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      print('Unexpected error during Google login: $e');
      rethrow;
    }
  }

  Future<void> appleLogin() async {
    try {
      print('Starting Apple sign in process...');
      final appleUser = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final authCredential = OAuthProvider("apple.com").credential(
        idToken: appleUser.identityToken,
        accessToken: appleUser.authorizationCode,
      );

      print('Signing in to Firebase with Apple credentials...');
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        authCredential,
      );

      if (userCredential.user != null) {
        String? displayName = userCredential.user!.displayName;
        if (displayName == null && appleUser.givenName != null) {
          displayName = '${appleUser.givenName} ${appleUser.familyName}'.trim();
        }
        try {
          await _createOrUpdateUser(
            userCredential.user!,
            customDisplayName: displayName,
          ).timeout(const Duration(seconds: 3));
        } catch (_) {
          // Ignore timeout or other errors during user creation to allow login to proceed
        }
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth error during Apple login: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error during Apple login: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      print('Signing out user...');
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut();
      }
      await FirebaseAuth.instance.signOut();
      print('Sign out successful');
    } catch (e) {
      print('Error during sign out: $e');
      rethrow;
    }
  }
}
