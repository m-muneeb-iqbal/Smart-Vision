import 'package:flutter/material.dart';

class ReadTextScreen extends StatelessWidget {
  const ReadTextScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Read Text Screen'),
      ),
      body: const Center(
        child: Text(
          'This is a dummy screen for reading text.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}