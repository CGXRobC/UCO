import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_menu_screen.dart';
import 'player_menu_screen.dart';

class LoginScreen extends StatefulWidget {
  final String courseId; // <-- required
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
        // Admin login
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AdminMenuScreen(courseId: widget.courseId),
            ),
          );
        }
      } else {
        // Player login: verify name exists in the players subcollection under this course
        final QuerySnapshot playerDoc = await _firestore
            .collection('courses/${widget.courseId}/players')
            .where('name', isEqualTo: input)
            .get();

        if (playerDoc.docs.isEmpty) {
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

        // Login success
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PlayerMenuScreen(
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
      appBar: AppBar(title: const Text('Unofficial Cornish Open Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Enter Admin Code (ADMIN2025) or Player Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: _login,
              child: const Text('Login', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
