import 'package:flutter/material.dart';
import 'package:agro_alchemy_ui/login_page.dart';
import 'package:agro_alchemy_ui/services/auth.dart';
import 'package:agro_alchemy_ui/dashboard.dart'; // Ensure this import is correct
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Rate limiting for lastAccess updates
  static DateTime? _lastAccessUpdate;
  static const _minimumUpdateInterval = Duration(minutes: 15);

  Future<Widget> _getInitialScreen(String uid) async {
    try {
      print('Checking user document for UID: $uid');
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      try {
        final doc = await userRef.get();

        if (!doc.exists) {
          print('Creating new user document for UID: $uid');
          await userRef.set({
            'createdAt': FieldValue.serverTimestamp(),
            'lastAccess': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('User document created successfully');
        } else {
          print('Existing user document found');

          // Update lastAccess time with rate limiting
          final now = DateTime.now();
          if (_lastAccessUpdate == null ||
              now.difference(_lastAccessUpdate!) >= _minimumUpdateInterval) {
            try {
              await userRef.update({
                'lastAccess': FieldValue.serverTimestamp(),
              });
              _lastAccessUpdate = now;
            } on FirebaseException catch (e) {
              if (e.code == 'resource-exhausted') {
                print('Quota exceeded for lastAccess update, skipping');
                // Continue without the update
              } else {
                rethrow;
              }
            }
          }
        }

        return const Dashboard();  // Updated to Dashboard
      } on FirebaseException catch (e) {
        if (e.code == 'resource-exhausted') {
          print('Quota exceeded, proceeding without updates');
          // If we can't write to Firestore, still let the user use the app
          return const Dashboard();  // Updated to Dashboard
        }
        rethrow;
      }
    } catch (e, stackTrace) {
      print('Error in _getInitialScreen: $e');
      print('Stack trace: $stackTrace');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Failed to load user data. Please try again."),
            ElevatedButton(
              onPressed: () => AuthService().signOut(),
              child: const Text("Sign Out"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("An error occurred"));
        } else if (snapshot.hasData) {
          final user = snapshot.data!;
          return FutureBuilder(
            future: _getInitialScreen(user.uid),
            builder: (context, AsyncSnapshot<Widget> futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (futureSnapshot.hasError) {
                return const Center(child: Text("Failed to load user data"));
              } else {
                return futureSnapshot.data!;
              }
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
