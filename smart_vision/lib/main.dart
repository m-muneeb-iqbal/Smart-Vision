import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'homescreen.dart';
import 'HowToUseScreen.dart';
import 'object_detection_screen.dart';
import 'ReadTextScreen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const BlindVisionApp());
}

class BlindVisionApp extends StatelessWidget {
  const BlindVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Vision',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Color(0xFF26A69A),
      ),
      home: FirebaseAuth.instance.currentUser == null
          ? const LoginScreen()
          : const HomeScreen(),
      routes: {
        '/login_screen': (context) => const LoginScreen(),
        '/signup_screen': (context) => const SignupScreen(),
        '/home_screen': (context) => const HomeScreen(),
        '/object-detect': (context) => const ObjectDetectionScreen(),
        '/read-text': (context) => const ReadTextScreen(),
        '/how-to-use': (context) => const HowToUseScreen(),
      },
    );
  }
}
