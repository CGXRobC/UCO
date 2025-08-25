import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'score_input_screen.dart';

class PlayerSetupScreen extends StatefulWidget {
  final String courseId;

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
    final double? handicap = double.tryParse(_handicapController.text.trim());

    if (name.isEmpty || handicap == null || handicap < 0 || handicap > 54) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid name and handicap (0-54)')),
      );
      return;
    }

    try {
      await _firestore
          .collection('course_settings')
          .doc(widget.courseId)
          .collection('players')
          .add({
            'name': name,
            'handicap': handicap,
            'timestamp': Timestamp.now(),
          });

      _nameController.clear();
      _handicapController.clear();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Player $name added')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding player: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final playersCollection = _firestore
        .collection('course_settings')
        .doc(widget.courseId)
        .collection('players');

    return Scaffold(
      appBar: AppBar(title: const Text('Add Players')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Player Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _handicapController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Handicap (0-54)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addPlayer,
              child: const Text('Add Player'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Players in this Course:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: playersCollection.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();

                  final players = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      return ListTile(
                        title: Text(player['name']),
                        subtitle: Text('Handicap: ${player['handicap']}'),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ScoreInputScreen(round: 1, courseId: widget.courseId),
                  ),
                );
              },
              child: const Text('Start Round 1 Scoring'),
            ),
          ],
        ),
      ),
    );
  }
}
