import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_choice_screen.dart'; // Ensure this path is correct

class WelcomeMessageScreen extends StatefulWidget {
  @override
  _WelcomeMessageScreenState createState() => _WelcomeMessageScreenState();
}

class _WelcomeMessageScreenState extends State<WelcomeMessageScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingPages = [
    {
      'image': 'assets/images/dating_chat_1.jpg',
      'title': 'Get Better at\nRomantic Conversations',
      'description': '\n\nStruggling with what to say?\nWe’ve got your back with smooth suggestions.',
    },
    {
      'image': 'assets/images/dating_chat_2.png',
      'title': 'Impress with the\nRight Words',
      'description': '\n\nSay the right thing at the right time\nand build stronger connections.',
    },
    {
      'image': 'assets/images/dating_chat_3.png',
      'title': 'Confident Messaging\nStarts Here',
      'description': '\n\nNever overthink a reply again.\nText her with clarity and charm.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeCarouselOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_carousel_onboarding', true); // New flag for this carousel
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AuthChoiceScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _onboardingPages.length,
            itemBuilder: (context, index) {
              final page = _onboardingPages[index];
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Spacer(),
                    Container(
                      height: MediaQuery.of(context).size.height * 0.44, // Adjust height as needed
                      width: MediaQuery.of(context).size.width * 0.8,
                      decoration: BoxDecoration(
                        color: Colors.white10, // Slightly lighter background for the card
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          page['image']!,
                          fit: BoxFit.cover, // Adjust fit as necessary
                        ),
                      ),
                    ),
                    SizedBox(height: 34),
                    Text(
                      page['title']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      page['description']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[300],
                      ),
                    ),
                    Spacer(),
                  ],
                ),
              );
            },
          ),
          // Skip Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: TextButton(
              onPressed: _completeCarouselOnboarding,
              child: Text(
                "Skip",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          // Page Indicators
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.25, // Adjust position
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingPages.length,
                    (index) => AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.white : Colors.grey[600],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          // Navigation Arrows
          Positioned(
            bottom: 60, // Adjust position
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: _currentPage == 0
                            ? null
                            : () {
                          _pageController.previousPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        },
                      ),
                      Container(width: 1, height: 24, color: Colors.grey[700]), // Separator
                      IconButton(
                        icon: Icon(Icons.arrow_forward, color: Colors.white),
                        onPressed: _currentPage == _onboardingPages.length - 1
                            ? _completeCarouselOnboarding // Go to AuthChoiceScreen on last page
                            : () {
                          _pageController.nextPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}