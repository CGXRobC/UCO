import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatefulWidget {
  final String courseId; // NEW
  final int? round; // optional, show all rounds if null

  const LeaderboardScreen({super.key, required this.courseId, this.round});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> _scoreStream() {
    final collection = _firestore.collection(
      'courses/${widget.courseId}/scores',
    );
    if (widget.round != null) {
      return collection.where('round', isEqualTo: widget.round).snapshots();
    }
    return collection.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _scoreStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final scores = snapshot.data!.docs;

          // Map playerId -> total points & current hole
          final Map<String, Map<String, dynamic>> leaderboard = {};

          for (var s in scores) {
            final playerId = s['playerId'];
            final hole = s['holeNumber'];
            final points = s['points'];

            if (!leaderboard.containsKey(playerId)) {
              leaderboard[playerId] = {'points': 0, 'hole': 0};
            }
            leaderboard[playerId]!['points'] += points;
            if (hole > (leaderboard[playerId]!['hole'] as int)) {
              leaderboard[playerId]!['hole'] = hole;
            }
          }

          // Convert to a list and sort by points descending
          final sortedPlayers = leaderboard.entries.toList()
            ..sort(
              (a, b) => (b.value['points'] as int).compareTo(
                a.value['points'] as int,
              ),
            );

          return ListView.builder(
            itemCount: sortedPlayers.length,
            itemBuilder: (context, index) {
              final playerId = sortedPlayers[index].key;
              final totalPoints = sortedPlayers[index].value['points'];
              final currentHole = sortedPlayers[index].value['hole'];

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore
                    .collection('courses/${widget.courseId}/players')
                    .doc(playerId)
                    .get(),
                builder: (context, playerSnap) {
                  if (!playerSnap.hasData) return const SizedBox();
                  final playerName = playerSnap.data!['name'];
                  return ListTile(
                    leading: Text('${index + 1}'),
                    title: Text(playerName),
                    subtitle: Text('Hole: $currentHole'),
                    trailing: Text('Points: $totalPoints'),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
