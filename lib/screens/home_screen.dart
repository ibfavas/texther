import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'auth/auth_choice_screen.dart';

class HomeScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  Future<void> _confirmSignOut(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _authService.signOut();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('seen_carousel_onboarding', true);
        await prefs.setBool('seen_onboarding', false);
        await prefs.setBool('is_new_signup_user', false);

        if (context.mounted) {
          // Use pushAndRemoveUntil to ensure proper navigation
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => AuthChoiceScreen()),
                (route) => false,
          );
        }
      } catch (e) {
        print("Sign-out error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error signing out')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("TextHer Home", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmSignOut(context),
          )
        ],
      ),
      body: Center(
        child: Text(
          "Welcome, ${user?.email ?? "User"} 👋",
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }
}
