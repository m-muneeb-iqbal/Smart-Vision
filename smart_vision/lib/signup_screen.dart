import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool hidePassword = true;
  String? errorMessage = '';
  String successMessage = '';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _controllerName = TextEditingController();
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

  Future<int> _getNextUserId() async {
    DocumentReference counterDoc = FirebaseFirestore.instance.collection('MetaData').doc('UserCounter');

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(counterDoc);

      int currentCount = snapshot.exists ? (snapshot.get('counter') as int) : 0;
      int nextCount = currentCount + 1;

      // Update the counter for the next user
      transaction.set(counterDoc, {'counter': nextCount}, SetOptions(merge: true));
      return nextCount;
    });
  }

  void _signUp() async {

    String name = _controllerName.text.trim();
    String email = _controllerEmail.text.trim();
    String password = _controllerPassword.text.trim();

    try {
      // Sign up using your custom FirebaseAuthService
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {

        // Generate a new userId
        int userId = await _getNextUserId();

        // Save user details to Firestore in nested collection
        await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId.toString())
          .set({
            'id': user.uid,
            'Email': email,
            'Name': name,
            'CreatedAt': DateTime.now(),
            'User Id' : userId.toString(),
        });

        setState(() {
            successMessage = 'Account created successfully!';
        });

        await Future.delayed(const Duration(seconds: 2));
        
        // Navigate to login screen
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    } catch (e) {
        setState(() {
          errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _controllerName.dispose();
    _controllerEmail.dispose();
    _controllerPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 const Text(
                    "Smart Vision",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                        
                  // Full Name
                  SizedBox(
                    height: 45,
                    child: TextField(
                      controller: _controllerName,
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: "Name",
                        labelStyle: const TextStyle(color: Colors.white),
                        hintText: "Enter your name",
                        hintStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white)
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 45,
                    child: TextField(
                      controller: _controllerEmail,
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle: const TextStyle(color: Colors.white),
                        hintText: "Enter your email",
                        hintStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white)
                    ),
                  ),
                  const SizedBox(height: 20),
                        
                  // Password
                  SizedBox(
                    height: 45,
                    child: TextField(
                      controller: _controllerPassword,
                      obscureText: hidePassword,
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: const TextStyle(color: Colors.white),
                        hintText: "Enter Password",
                        hintStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              hidePassword = !hidePassword;
                            });
                          }, 
                          icon: Icon(
                            hidePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white,
                          )
                        )
                      ),
                      style: const TextStyle(color: Colors.white)
                    ),
                  ),
                  const SizedBox(height: 30),
                        
                  // Error or Success Message
                  if (errorMessage != null && errorMessage!.isNotEmpty)
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  if (successMessage.isNotEmpty)
                    Text(
                      successMessage,
                      style: const TextStyle(color: Colors.white),
                    ),
                  const SizedBox(height: 10),
                        
                  ElevatedButton(
                    onPressed: _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF26A69A), // Theme color for button text
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text('Register'),
                  ),
                  const SizedBox(height: 20),
                        
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen()
                        )
                      );
                    },
                    child: const Text(
                      'Already a User? Sign In!',
                      style: TextStyle(color: Colors.white),
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
