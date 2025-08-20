import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'score_input_screen.dart'; // Updated import

class PlayerSetupScreen extends StatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _handicapController = TextEditingController();

  Future<void> _addPlayer() async {
    final String name = _nameController.text.trim();
    final double? handicap = double.tryParse(_handicapController.text.trim());
    if (name.isEmpty || handicap == null || handicap < 0 || handicap > 54) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter a valid name and handicap (0-54)'),
          ),
        );
      }
      return;
    }

    try {
      final DocumentSnapshot groupDoc = await _firestore
          .collection('settings')
          .doc('group')
          .get();
      if (!groupDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Group code not found. Please set group code first.',
              ),
            ),
          );
        }
        return;
      }
      final String groupCode = groupDoc['code'] as String;

      await _firestore.collection('players').add({
        'name': name,
        'handicap': handicap,
        'groupCode': groupCode,
        'timestamp': Timestamp.now(),
      });

      _nameController.clear();
      _handicapController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Player $name added')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding player: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: _addPlayer,
              child: const Text('Add Player', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const ScoreInputScreen(round: 1),
                ), // Updated reference
              ),
              child: const Text(
                'Start Scoring',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('players').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      return ListTile(
                        title: Text(doc['name'] as String),
                        subtitle: Text('Handicap: ${doc['handicap']}'),
                      );
                    }).toList(),
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
