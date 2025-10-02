import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'admin_menu_screen.dart';
import 'player_menu_screen.dart';

class LoginScreen extends StatefulWidget {
  final String courseId;
  const LoginScreen({super.key, required this.courseId});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _codeController = TextEditingController();
  final String _adminCode = 'ADMIN2025';

  Future<void> _login() async {
    final String input = _codeController.text.trim();
    if (input.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid code or player name')),
        );
      }
      return;
    }

    try {
      if (input == _adminCode) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AdminMenuScreen(courseId: widget.courseId),
            ),
          );
        }
      } else {
        final QuerySnapshot playerQuery = await _firestore
            .collection('courses/${widget.courseId}/players')
            .where('name', isEqualTo: input)
            .get();

        if (playerQuery.docs.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Player not found. Please check your name or contact admin.',
                ),
              ),
            );
          }
          return;
        }

        final playerDoc = playerQuery.docs.first;
        final playerId = playerDoc.id;

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PlayerMenuScreen(
                playerId: playerId,
                playerName: input,
                courseId: widget.courseId,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging in: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'web/Assets/images/U_C_O_Background.png',
            ), // Path to your image
            fit: BoxFit.cover, // Makes the image cover the entire background
            opacity: 0.7, // Adjusts opacity for readability
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Enter Code or Name',
                  border: OutlineInputBorder(),
                  filled: true, // Add background to TextField
                  fillColor:
                      Colors.white70, // Semi-transparent white background
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor:
                      Colors.white70, // Semi-transparent white background
                ),
                onPressed: _login,
                child: const Text('Login', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
