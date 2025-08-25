import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatefulWidget {
  final String courseId;

  const LeaderboardScreen({super.key, required this.courseId});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference scoresCollection;
  late CollectionReference playersCollection;

  @override
  void initState() {
    super.initState();
    final courseDoc = _firestore
        .collection('course_settings')
        .doc(widget.courseId);
    scoresCollection = courseDoc.collection('scores');
    playersCollection = courseDoc.collection('players');
  }

  Stream<List<Map<String, dynamic>>> _leaderboardStream() async* {
    await for (var scoresSnapshot in scoresCollection.snapshots()) {
      final playersSnapshot = await playersCollection.get();

      Map<String, String> playerNames = {};
      for (var p in playersSnapshot.docs) {
        playerNames[p.id] = p['name'] ?? 'Unknown';
      }

      Map<String, int> totalPoints = {};
      Map<String, int> lastHole = {};

      for (var s in scoresSnapshot.docs) {
        final playerId = s['player'] as String;
        final points = s['points'] as int;
        final hole = s['hole'] as int;

        totalPoints[playerId] = (totalPoints[playerId] ?? 0) + points;
        if (lastHole[playerId] == null || hole > lastHole[playerId]!) {
          lastHole[playerId] = hole;
        }
      }

      List<Map<String, dynamic>> leaderboard = [];
      totalPoints.forEach((playerId, points) {
        leaderboard.add({
          'playerId': playerId,
          'name': playerNames[playerId] ?? playerId,
          'points': points,
          'hole': lastHole[playerId] ?? 0,
        });
      });

      leaderboard.sort((a, b) => b['points'].compareTo(a['points']));
      yield leaderboard;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _leaderboardStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final leaderboard = snapshot.data!;

            if (leaderboard.isEmpty)
              return const Center(child: Text('No scores submitted yet.'));

            return ListView.builder(
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final player = leaderboard[index];
                return ListTile(
                  leading: Text('${index + 1}'),
                  title: Text(player['name']),
                  subtitle: Text('Hole: ${player['hole']}'),
                  trailing: Text('${player['points']} pts'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
