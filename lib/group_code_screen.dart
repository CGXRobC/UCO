import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'course_setup_screen.dart';
import 'player_setup_screen.dart';

class GroupCodeScreen extends StatefulWidget {
  const GroupCodeScreen({super.key});

  @override
  State<GroupCodeScreen> createState() => _GroupCodeScreenState();
}

class _GroupCodeScreenState extends State<GroupCodeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _codeController = TextEditingController();
  final String _adminCode = 'ADMIN2025'; // Admin code for course setup

  Future<void> _setGroupCode() async {
    final String code = _codeController.text.trim();
    if (code.isEmpty || code.length < 4) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter a valid group code (4+ characters)'),
          ),
        );
      }
      return;
    }

    try {
      // Save group code in Firestore
      await _firestore.collection('settings').doc('group').set({
        'code': code,
        'timestamp': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group code set successfully')),
        );

        // Navigate based on admin code
        final nextScreen = code == _adminCode
            ? CourseSetupScreen(courseId: code)
            : PlayerSetupScreen(courseId: code);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error setting group code: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Group Code')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText:
                    'Enter Group Code (e.g., UCO2025 or ADMIN2025 for admin)',
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
              onPressed: _setGroupCode,
              child: const Text('Set Code', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
