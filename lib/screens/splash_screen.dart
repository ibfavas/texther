import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'onboarding/welcome_message.dart';
import 'auth/auth_choice_screen.dart';
import 'onboarding/onboarding_step1.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    await Future.delayed(Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final bool seenCarousel = prefs.getBool('seen_carousel_onboarding') ?? false;
    final bool seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (!seenCarousel) {
      // First time ever opening the app
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => WelcomeMessageScreen()),
      );
    } else if (user == null) {
      // Seen welcome carousel, but not logged in
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AuthChoiceScreen()),
      );
    } else if (!seenOnboarding) {
      // Logged in but first time onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OnboardingStep1()),
      );
    } else {
      // Logged in and seen onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image.asset("assets/images/love.png", width: 75),
      ),
    );
  }
}
