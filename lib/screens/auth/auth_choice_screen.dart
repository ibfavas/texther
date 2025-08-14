import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../home_screen.dart';
import '../onboarding/onboarding_step1.dart';
import 'email_login_screen.dart';
import 'email_signup_screen.dart';

class AuthChoiceScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  Future<void> _handleSocialLogin(
      BuildContext context, Future<UserCredential?> Function() signInMethod) async {
    try {
      final userCredential = await signInMethod();
      final user = userCredential?.user;

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();

        final isNewUser = userCredential!.additionalUserInfo?.isNewUser ?? false;
        final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

        if (isNewUser || !seenOnboarding) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => OnboardingStep1()),
                (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
                (route) => false,
          );
        }
      } else {
        _showError(context, "Login failed. Please try again.");
      }
    } on FirebaseAuthException catch (e) {
      _showError(context, e.message ?? "An authentication error occurred.");
    } catch (e) {
      _showError(context, "An unexpected error occurred: ${e.toString()}");
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Image.asset(
              'assets/images/reminder_love.png',
              height: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 25),
            const Text(
              "Welcome to",
              style: TextStyle(fontSize: 28, color: Colors.white),
            ),
            const Text(
              "TextHer",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EmailLoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text("Log in"),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EmailSignupScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF222222),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text("Sign up"),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              "Continue With Accounts",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _handleSocialLogin(context, _authService.signInWithGoogle);
                      },
                      icon: const Icon(Icons.mail_outline, size: 20),
                      label: const Text("GOOGLE",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A242A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Facebook login coming soon!'),
                            backgroundColor: Colors.blueGrey,
                          ),
                        );
                      },
                      icon: const Icon(Icons.facebook, size: 20),
                      label: const Text("FACEBOOK",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A426A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}