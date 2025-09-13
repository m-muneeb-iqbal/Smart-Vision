import 'package:flutter/material.dart';

class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manual"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Back",
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            SizedBox(height: 20),
            Text(
              "Welcome to Blind Vision System!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.tealAccent,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Here's how you can use this app effectively:",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 30),
            InstructionStep(
              number: 1,
              title: "Launch the App",
              description:
                  "Open the Blind Vision app. You will see a set of big, accessible buttons on the main screen.",
            ),
            InstructionStep(
              number: 2,
              title: "Use Voice Commands",
              description:
                  "Speak clearly commands like 'Detect Object', 'Read Text', etc. The app will respond automatically.",
            ),
            InstructionStep(
              number: 3,
              title: "Detect Objects",
              description:
                  "Tap the 'Object Detection' button or say 'Detect Object' to scan your surroundings using the camera.",
            ),
            InstructionStep(
              number: 4,
              title: "Read Text",
              description:
                  "To read printed or handwritten text, tap 'Read the Text'. Point the camera at the text to hear it aloud.",
            ),
            InstructionStep(
              number: 5,
              title: "Audio Feedback",
              description:
                  "All actions provide voice feedback so that users can interact without needing to look at the screen.",
            ),
            SizedBox(height: 20),
            Text(
              "For best experience, use the app in a well-lit environment and speak clearly near the microphone.",
              style: TextStyle(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class InstructionStep extends StatelessWidget {
  final int number;
  final String title;
  final String description;

  const InstructionStep({
    super.key,
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.teal,
            child: Text(
              number.toString(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
