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
  String? userId;
  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (_checkIfAccountIsDeleted() == true) {
      userId = user?.uid;
      if (user != null) {
        fetchNumericUserId(user!.uid);
      }
    }
    _speech = stt.SpeechToText();
    Future.delayed(const Duration(milliseconds: 3000), () {
      _initSpeech();
    });
  }

  Future<bool> _checkIfAccountIsDeleted() async {
    try {
      IdTokenResult? idTokenResult = await user?.getIdTokenResult(true);
      if (idTokenResult == null || idTokenResult.token == null) {
        FirebaseAuth.instance.signOut();
        Navigator.pushReplacementNamed(context, '/login_screen');
        return false;
      } else {
        return true;
      }
    } catch (er) {
      FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login_screen');
      return false;
    }
  }

  Future<void> fetchNumericUserId(String firebaseUid) async {
    // Find the user document with matching `id` field (Firebase UID)
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Users')
        .where('id', isEqualTo: firebaseUid)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        userId = snapshot.docs.first.id; // This is your numeric ID as string
      });
    }
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
    if (!_speech.isListening) {
      // ✅ prevent overlap
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
    }
    if (text.contains("stop hearing") || text.contains("exit listening")) {
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
                accountName: Text(
                  user?.displayName ?? "User Name",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                accountEmail: Text(
                  user?.email ?? "user@example.com",
                  style: TextStyle(fontSize: 14),
                ),
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
                      title: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.black, fontSize: 18),
                      ),
                      onTap: () => logout(),
                    ),
                  ],
                ),
              ),
            ),
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
            colors: [Color(0xFF00695C), Color(0xFF26A69A), Color(0xFFB2DFDB)],
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
                    GestureDetector(
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 18,
                          color: Color(0xFF00695C),
                        ),
                      ),
                      onTap: () => {_scaffoldKey.currentState?.openDrawer()},
                    ),
                    const Text(
                      "Smart Vision",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notification_add),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 200),
                Expanded(
                  child: ListView(
                    children: [
                      _buildMenuButton(
                        text: "Detect Object",
                        icon: Icons.remove_red_eye,
                        onTap: () => _navigateTo('/object-detect'),
                      ),
                      const SizedBox(height: 10),
                      _buildMenuButton(
                        text: "Read Text",
                        icon: Icons.text_snippet,
                        onTap: () => _navigateTo('/read-text'),
                      ),
                      const SizedBox(height: 10),
                      _buildMenuButton(
                        text: "Exit Application",
                        icon: Icons.logout,
                        onTap: () {
                          if (Platform.isAndroid || Platform.isIOS) {
                            SystemNavigator.pop();
                          } else {
                            exit(0);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildMenuButton(
                        text: "Instructions",
                        icon: Icons.info_outline,
                        onTap: () => _navigateTo('/how-to-use'),
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

  Widget _buildMenuButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF00695C),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
