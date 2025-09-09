import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late stt.SpeechToText _speech;
  bool _commandExecuted = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _startListening();
        }
      },
      onError: (error) {
        debugPrint("Speech error: $error");
      },
    );
    if (available) {
      _startListening();
    }
  }

  void _startListening() {
    _speech.listen(
      onResult: (val) {
        String command = val.recognizedWords.toLowerCase().trim();
        debugPrint("Recognized Command: $command");
        _handleCommand(command);
      },
      listenMode: stt.ListenMode.confirmation,
      localeId: "en_IN", // Or "en_US"
    );
  }

  void _handleCommand(String command) {
    if (_commandExecuted || command.isEmpty) return;

    // Prioritized command handling
    if (command.contains("object detection") ||
        command.contains("detect object") ||
        command.contains("object")) {
      _navigateTo('/object-detect');
    } else if (command.contains("read text") ||
        command.contains("text") ||
        command.contains("text")) {
      _navigateTo('/read-text');
    } else if (command.contains("how to use") ||
        command.contains("use") ||
        command.contains("usage")) {
      _navigateTo('/how-to-use');
    } else if (command.contains("close the app") ||
        command.contains("exit the app") ||
        command.contains("close") ||
        command.contains("exit")) {
      _commandExecuted = true;
      debugPrint("Close the app command recognized.");
      if (Platform.isAndroid || Platform.isIOS) {
        SystemNavigator.pop();
      } else {
        exit(0);
      }
    } else {
      // No valid command detected, restart listening
      debugPrint("Unrecognized or invalid command: $command");
      _speech.stop();
      Future.delayed(const Duration(milliseconds: 500), _startListening);
    }
  }

  void _navigateTo(String route) {
    _commandExecuted = true;
    _speech.stop();

    Navigator.pushNamed(context, route).then((_) {
      Future.delayed(const Duration(seconds: 1), () {
        _commandExecuted = false;
        _startListening();
      });
    });
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login_screen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: Column(
          children: [
            GestureDetector(
              child: UserAccountsDrawerHeader(
                accountName: Text("User Name", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                accountEmail: Text("user@example.com", style: TextStyle(fontSize: 14)),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Color(0xFF00695C)),
                ),
                decoration: BoxDecoration(color: Color(0xFF00695C)),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFEEEEF1),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.logout, 
                        color: Colors.black
                      ),
                      title: Text(
                        "Logout", 
                        style: TextStyle(
                          color: Colors.black, 
                          fontSize: 18
                        )
                      ),
                      onTap: () => logout()
                    ),
                  ],
                ),
              )
            )
          ],
        ),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00695C), // Darker shade
              Color(0xFF26A69A), // Primary theme color
              Color(0xFFB2DFDB), // Lighter shade
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        _scaffoldKey.currentState?.openDrawer();
                      }, 
                      icon: const Icon(Icons.menu),
                      iconSize: 30,
                      color: Colors.white,
                    ),
                    Text(
                      "Smart Vision",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white
                      )
                    ),
                    IconButton(
                      onPressed: () {}, 
                      icon: const Icon(Icons.settings),
                      color: Colors.white,
                      iconSize: 30,
                    )
                  ],
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('assets/images.png'),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Welcome to Smart Vision",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Helping the visually impaired see the world.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView(
                    children: [
                      GestureDetector(
                        onTap: () => _navigateTo('/object-detect'),
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Color(0xFF00695C),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.remove_red_eye, color: Colors.white,),
                              const SizedBox(width: 10),
                              Text(
                                "Object Detection",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _navigateTo('/read-text'),
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Color(0xFF00695C),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.text_snippet, color: Colors.white,),
                              const SizedBox(width: 10),
                              Text(
                                "Read the Text",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Color(0xFF00695C),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, color: Colors.white,),
                              const SizedBox(width: 10),
                              Text(
                                "Exit Application",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _navigateTo('/how-to-use'),
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Color(0xFF00695C),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline, color: Colors.white,),
                              const SizedBox(width: 10),
                              Text(
                                "How to Use",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  const CustomButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 28),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18.0),
          child: Text(
            text,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          backgroundColor: Colors.teal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
        ),
      ),
    );
  }
}
