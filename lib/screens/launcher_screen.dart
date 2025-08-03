import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/auth/auth_choice_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding/onboarding_step1.dart';
import '../screens/splash_screen.dart';

class LauncherScreen extends StatefulWidget {
  const LauncherScreen({Key? key}) : super(key: key);

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(Duration(seconds: 2)); // Splash time

    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    final isNewUser = prefs.getBool('is_new_signup_user') ?? false;
    final currentUser = FirebaseAuth.instance.currentUser;

    Widget nextScreen;

    if (!seenOnboarding) {
      nextScreen = OnboardingStep1();
    } else if (currentUser != null) {
      nextScreen = isNewUser ? OnboardingStep1() : HomeScreen();
    } else {
      nextScreen = AuthChoiceScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen(); // full screen splash
  }
}
