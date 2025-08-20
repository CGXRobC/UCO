import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UCO Stats')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('scores')
            .orderBy('timestamp')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final Map<String, Map<int, Map<String, int>>> stats = {};
          for (final doc in snapshot.data!.docs) {
            final String playerId = doc['player'] as String;
            final int round =
                doc['round'] as int? ?? 1; // Default to round 1 if missing
            final bool isBirdie = doc.data().toString().contains('isBirdie')
                ? doc['isBirdie'] as bool
                : false;
            final int points = doc['points'] as int;
            stats[playerId] ??= {};
            stats[playerId]![round] ??= {
              'points': 0,
              'birdies': 0,
              'eagles': 0,
            };
            stats[playerId]![round]!['points'] =
                (stats[playerId]![round]!['points'] ?? 0) + points;
            if (isBirdie) {
              stats[playerId]![round]!['birdies'] =
                  (stats[playerId]![round]!['birdies'] ?? 0) + 1;
            }
            if (points >= 4) {
              stats[playerId]![round]!['eagles'] =
                  (stats[playerId]![round]!['eagles'] ?? 0) + 1;
            }
          }
          return ListView.builder(
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final playerId = stats.keys.elementAt(index);
              final round1 =
                  stats[playerId]![1] ??
                  {'points': 0, 'birdies': 0, 'eagles': 0};
              final round2 =
                  stats[playerId]![2] ??
                  {'points': 0, 'birdies': 0, 'eagles': 0};
              final round3 =
                  stats[playerId]![3] ??
                  {'points': 0, 'birdies': 0, 'eagles': 0};
              final totalPoints =
                  round1['points']! + round2['points']! + round3['points']!;
              final totalBirdies =
                  round1['birdies']! + round2['birdies']! + round3['birdies']!;
              final totalEagles =
                  round1['eagles']! + round2['eagles']! + round3['eagles']!;
              return ListTile(
                title: Text(playerId, style: const TextStyle(fontSize: 18)),
                subtitle: Text(
                  'R1: ${round1['points']} pts, ${round1['birdies']} birdies, ${round1['eagles']} eagles\n'
                  'R2: ${round2['points']} pts, ${round2['birdies']} birdies, ${round2['eagles']} eagles\n'
                  'R3: ${round3['points']} pts, ${round3['birdies']} birdies, ${round3['eagles']} eagles\n'
                  'Total: $totalPoints pts, $totalBirdies birdies, $totalEagles eagles',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
