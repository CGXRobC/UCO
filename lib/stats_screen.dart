import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatsScreen extends StatefulWidget {
  final String courseId; // NEW
  final int? round; // optional

  const StatsScreen({super.key, required this.courseId, this.round});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
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
      appBar: AppBar(title: const Text('Stats')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _scoreStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final scores = snapshot.data!.docs;

          // Map playerId -> stats
          final Map<String, Map<String, int>> statsMap = {};

          for (var s in scores) {
            final playerId = s['playerId'] as String;
            final points = (s['points'] as num).toInt(); // <-- cast to int
            final grossScore = (s['grossScore'] as num).toInt();
            final holePar = (s['holePar'] as num).toInt();

            final parDiff = grossScore - holePar;

            if (!statsMap.containsKey(playerId)) {
              statsMap[playerId] = {
                'totalPoints': 0,
                'birdies': 0,
                'pars': 0,
                'eagles': 0,
                'bogeys': 0,
                'doubleBogeysPlus': 0,
              };
            }

            statsMap[playerId]!['totalPoints'] =
                statsMap[playerId]!['totalPoints']! + points;

            if (parDiff <= -2) {
              statsMap[playerId]!['eagles'] =
                  statsMap[playerId]!['eagles']! + 1;
            } else if (parDiff == -1) {
              statsMap[playerId]!['birdies'] =
                  statsMap[playerId]!['birdies']! + 1;
            } else if (parDiff == 0) {
              statsMap[playerId]!['pars'] = statsMap[playerId]!['pars']! + 1;
            } else if (parDiff == 1) {
              statsMap[playerId]!['bogeys'] =
                  statsMap[playerId]!['bogeys']! + 1;
            } else if (parDiff >= 2) {
              statsMap[playerId]!['doubleBogeysPlus'] =
                  statsMap[playerId]!['doubleBogeysPlus']! + 1;
            }
          }

          final sortedPlayers = statsMap.entries.toList()
            ..sort(
              (a, b) =>
                  b.value['totalPoints']!.compareTo(a.value['totalPoints']!),
            );

          return ListView.builder(
            itemCount: sortedPlayers.length,
            itemBuilder: (context, index) {
              final playerId = sortedPlayers[index].key;
              final stats = sortedPlayers[index].value;

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore
                    .collection('courses/${widget.courseId}/players')
                    .doc(playerId)
                    .get(),
                builder: (context, playerSnap) {
                  if (!playerSnap.hasData) return const SizedBox();
                  final playerName = playerSnap.data!['name'] as String;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    child: ListTile(
                      title: Text(playerName),
                      subtitle: Text(
                        'Points: ${stats['totalPoints']}, Pars: ${stats['pars']}, Birdies: ${stats['birdies']}, Eagles: ${stats['eagles']}, Bogeys: ${stats['bogeys']}, Double+ : ${stats['doubleBogeysPlus']}',
                      ),
                    ),
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
