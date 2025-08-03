import 'package:flutter/material.dart';
import 'onboarding_reminder.dart';

class OnboardingStep2 extends StatefulWidget {
  @override
  _OnboardingStep2State createState() => _OnboardingStep2State();
}

class _OnboardingStep2State extends State<OnboardingStep2> {
  int? selectedIndex;

  final List<Map<String, String>> options = [
    {"label": "I’m shy / weak in English", "image": "assets/images/shy.png"},
    {"label": "I want to impress a girl I matched", "image": "assets/images/impress.png"},
    {"label": "I’m already chatting but need help", "image": "assets/images/help.png"},
    {"label": "I lost someone but want to try again", "image": "assets/images/try_again.png"},
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
              "Which best describes you?",
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
                    MaterialPageRoute(builder: (_) => OnboardingReminder()),
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
