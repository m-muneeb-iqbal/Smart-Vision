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
  bool _isCommandMode = false; // ✅ NEW FLAG

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    Future.delayed(const Duration(milliseconds: 3000), () {
      _initSpeech();
    });
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        debugPrint("Speech status: $status");
        if (status == 'notListening') {
          Future.delayed(const Duration(milliseconds: 500), _startListening);
        }
      },
    );
    if (available) {
      _startListening();
    }
  }

  void _startListening() {
    if (!_speech.isListening) { // ✅ prevent overlap
      _speech.listen(
        onResult: (val) {
          String spoken = val.recognizedWords.toLowerCase().trim();
          debugPrint("Recognized: $spoken");
          _processSpeech(spoken);
        },
        listenMode: stt.ListenMode.confirmation,
        localeId: "en_IN", // Or "en_US"
      );
    }
  }

  void _stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
      debugPrint("🎤 Stopped listening");
    }
  }

  void _processSpeech(String text) {
    if (text.isEmpty) return;

    // Handle start/stop listening
    if (text.contains("listening") || text.contains("hey vision")) {
      if (!_isCommandMode) {
        _isCommandMode = true;
        debugPrint("🔊 Command mode activated!");
      }
      return;
    } if (text.contains("stop hearing") || text.contains("exit listening")) {
      if (_isCommandMode) {
        _isCommandMode = false;
        debugPrint("🛑 Command mode deactivated!$text");
        _stopListening();
      }
      return;
    }

    // If not in command mode → ignore
    if (!_isCommandMode) return;

    // Handle actual commands

    _handleCommand(text);
  }

  void _handleCommand(String command) {
    if (_commandExecuted || command.isEmpty) return;

    if (command.contains("object detection") ||
        command.contains("detect object") ||
        command.contains("detect") ||
        command.contains("object")) {
      _navigateTo('/object-detect');
    } else if (command.contains("read text") ||
        command.contains("read") ||
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
      debugPrint("Unrecognized command in command mode: $command");
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
                accountName: const Text("User Name",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                accountEmail: const Text("user@example.com",
                    style: TextStyle(fontSize: 14)),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Color(0xFF00695C)),
                ),
                decoration: const BoxDecoration(color: Color(0xFF00695C)),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFEEEEF1),
                child: Column(
                  children: [
                    ListTile(
                        leading: const Icon(Icons.logout, color: Colors.black),
                        title: const Text("Logout",
                            style: TextStyle(
                                color: Colors.black, fontSize: 18)),
                        onTap: () => logout()),
                  ],
                ),
              ),
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
              Color(0xFF00695C),
              Color(0xFF26A69A),
              Color(0xFFB2DFDB),
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
                    const Text("Smart Vision",
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
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
                      CircleAvatar(radius: 50),
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
                      _buildMenuButton(
                          icon: Icons.remove_red_eye,
                          text: "Object Detection",
                          onTap: () => _navigateTo('/object-detect')),
                      const SizedBox(height: 10),
                      _buildMenuButton(
                          icon: Icons.text_snippet,
                          text: "Read the Text",
                          onTap: () => _navigateTo('/read-text')),
                      const SizedBox(height: 10),
                      _buildMenuButton(
                          icon: Icons.logout,
                          text: "Exit Application",
                          onTap: () {
                            if (Platform.isAndroid || Platform.isIOS) {
                              SystemNavigator.pop();
                            } else {
                              exit(0);
                            }
                          }),
                      const SizedBox(height: 10),
                      _buildMenuButton(
                          icon: Icons.info_outline,
                          text: "How to Use",
                          onTap: () => _navigateTo('/how-to-use')),
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

  Widget _buildMenuButton(
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
            color: const Color(0xFF00695C),
            borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(text,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}