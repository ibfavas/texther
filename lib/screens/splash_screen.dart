import 'package:cloud_firestore/cloud_firestore.dart';
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
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool seenCarousel = prefs.getBool('seen_carousel_onboarding') ?? false;
    final bool seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    final user = FirebaseAuth.instance.currentUser;

    // 🔥 Preload user data if logged in
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (snapshot.exists) {
          final data = snapshot.data() ?? {};
          await prefs.setString('userName', data['name'] ?? '');
          await prefs.setString('userPlan', data['plan'] ?? 'free');
        }
      } catch (e) {
        debugPrint("⚠️ Error preloading user data: $e");
      }
    }

    if (!mounted) return;

    if (!seenCarousel) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => WelcomeMessageScreen()),
      );
    } else if (user == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AuthChoiceScreen()),
      );
    } else if (!seenOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OnboardingStep1()),
      );
    } else {
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
