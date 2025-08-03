import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home_screen.dart';

class OnboardingReminder extends StatelessWidget {
  Future<void> completeOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen()),
          (route) => false,
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image at the top
              Center(
                child: Image.asset(
                  'assets/images/reminder_love.png', // Replace with your actual asset
                  height: 180,
                ),
              ),
              SizedBox(height: 32),
              // Title
              Text(
                "Behavioral Reminder",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              // Body Text
              Text(
                "This app is your romantic friend.\n\n"
                    "✨ Don’t rush.\n"
                    "✨ Build connection slowly.\n"
                    "✨ Respect others.\n"
                    "✨ Be authentic, be kind.",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[300],
                  height: 1.6,
                ),
              ),
              Spacer(),
              // Start button
              Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  onPressed: () => completeOnboarding(context),
                  icon: Icon(Icons.check),
                  label: Text("Start"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
