import 'package:flutter/material.dart';
import 'onboarding_step2.dart';

class OnboardingStep1 extends StatefulWidget {
  @override
  _OnboardingStep1State createState() => _OnboardingStep1State();
}

class _OnboardingStep1State extends State<OnboardingStep1> {
  int? selectedIndex;

  final List<Map<String, String>> options = [
    {"label": "Making foreign friends", "image": "assets/images/friends.png"},
    {"label": "Starting a romantic chat", "image": "assets/images/romantic.png"},
    {"label": "Flirting without being awkward", "image": "assets/images/flirting.png"},
    {"label": "Expressing love like a pro", "image": "assets/images/love.png"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What do you need help with?",
              style: TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = selectedIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    child: Card(
                      color: isSelected ? Colors.white10 : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: isSelected ? Colors.white : Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Image.asset(option['image']!, width: 40),
                        title: Text(
                          option['label']!,
                          style: TextStyle(color: Colors.white),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: Colors.white)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: selectedIndex == null
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OnboardingStep2()),
                  );
                },
                icon: Icon(Icons.arrow_forward_ios),
                label: Text("Next"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
