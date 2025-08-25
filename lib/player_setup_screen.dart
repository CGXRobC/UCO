import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerSetupScreen extends StatefulWidget {
  final String courseId; // Required
  const PlayerSetupScreen({super.key, required this.courseId});

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _handicapController = TextEditingController();

  Future<void> _addPlayer() async {
    final name = _nameController.text.trim();
    final handicap = double.tryParse(_handicapController.text.trim());

    if (name.isEmpty || handicap == null || handicap < 0 || handicap > 54) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter valid name & handicap (0-54)")),
        );
      }
      return;
    }

    try {
      // Store player in the course-specific subcollection
      await _firestore.collection('courses/${widget.courseId}/players').add({
        'name': name,
        'handicap': handicap,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Player $name added")));

      // Clear input fields
      _nameController.clear();
      _handicapController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error adding player: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Players")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Player Name"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _handicapController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Handicap (0-54)"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addPlayer,
              child: const Text("Add Player"),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('courses/${widget.courseId}/players')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final players = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      return ListTile(
                        title: Text(player['name']),
                        subtitle: Text("Handicap: ${player['handicap']}"),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
