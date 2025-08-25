import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatsScreen extends StatefulWidget {
  final String courseId; // Required courseId

  const StatsScreen({super.key, required this.courseId});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference scoresCollection;

  @override
  void initState() {
    super.initState();
    scoresCollection = _firestore
        .collection('course_settings')
        .doc(widget.courseId)
        .collection('scores');
  }

  Future<Map<String, dynamic>> _calculateStats() async {
    final snapshot = await scoresCollection.get();
    final List<QueryDocumentSnapshot> docs = snapshot.docs;

    Map<String, int> playerPoints = {};
    Map<String, int> playerHoles = {};

    for (var doc in docs) {
      final playerId = doc['player'] as String;
      final points = doc['points'] as int;

      playerPoints[playerId] = (playerPoints[playerId] ?? 0) + points;
      playerHoles[playerId] = (playerHoles[playerId] ?? 0) + 1;
    }

    // Calculate average points per hole
    Map<String, double> avgPoints = {};
    playerPoints.forEach((player, totalPoints) {
      final holes = playerHoles[player] ?? 1;
      avgPoints[player] = totalPoints / holes;
    });

    return {'totalPoints': playerPoints, 'avgPoints': avgPoints};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _calculateStats(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final totalPoints =
                snapshot.data!['totalPoints'] as Map<String, int>;
            final avgPoints =
                snapshot.data!['avgPoints'] as Map<String, double>;

            return ListView(
              children: totalPoints.keys.map((playerId) {
                return ListTile(
                  title: Text('Player ID: $playerId'),
                  subtitle: Text(
                    'Total Points: ${totalPoints[playerId]}, Average Points/Hole: ${avgPoints[playerId]!.toStringAsFixed(2)}',
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
