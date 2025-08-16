import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TextHer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Urbanist',
        textTheme: ThemeData.dark().textTheme.copyWith(
          bodyLarge: TextStyle(fontFamily: 'Urbanist'),
          bodyMedium: TextStyle(fontFamily: 'Urbanist'),
          labelLarge: TextStyle(fontFamily: 'Urbanist'),
        ),
      ),
      home: SplashScreen(),
    );
  }
}
