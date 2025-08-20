import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UCO Leaderboard')),
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
          final Map<String, Map<int, int>> leaderboard = {};
          final Map<String, Map<int, int>> birdieCount = {};

          for (final doc in snapshot.data!.docs) {
            final String playerId = doc['player'] as String;
            final int points = doc['points'] as int;
            final int round =
                doc['round'] as int? ?? 1; // Default to round 1 if missing
            final bool isBirdie = doc.data().toString().contains('isBirdie')
                ? doc['isBirdie'] as bool
                : false;
            leaderboard[playerId] ??= {};
            leaderboard[playerId]![round] =
                (leaderboard[playerId]![round] ?? 0) + points;
            if (isBirdie) {
              birdieCount[playerId] ??= {};
              birdieCount[playerId]![round] =
                  (birdieCount[playerId]![round] ?? 0) + 1;
            }
          }
          final sorted = leaderboard.entries.toList()
            ..sort((a, b) {
              final aTotal = a.value.values.fold(
                0,
                (total, points) => total + points,
              );
              final bTotal = b.value.values.fold(
                0,
                (total, points) => total + points,
              );
              return bTotal.compareTo(aTotal);
            });
          return ListView.builder(
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final playerId = sorted[index].key;
              final round1 = leaderboard[playerId]![1] ?? 0;
              final round2 = leaderboard[playerId]![2] ?? 0;
              final round3 = leaderboard[playerId]![3] ?? 0;
              final total = round1 + round2 + round3;
              return FutureBuilder<String>(
                future: FirebaseFirestore.instance
                    .collection('players')
                    .doc(playerId)
                    .get()
                    .then((doc) => doc.data()?['name'] ?? playerId),
                builder: (context, nameSnapshot) {
                  if (nameSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      leading: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      title: Text(
                        playerId,
                        style: const TextStyle(fontSize: 18),
                      ),
                      subtitle: Text(
                        'R1: $round1 | R2: $round2 | R3: $round3 | Birdies: ${birdieCount[playerId]?.values.fold(0, (birdieTotal, birdieValue) => birdieTotal + birdieValue) ?? 0}',
                      ),
                      trailing: Text(
                        '$total pts',
                        style: const TextStyle(fontSize: 18),
                      ),
                    );
                  }
                  if (nameSnapshot.hasError) {
                    return ListTile(
                      leading: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      title: Text('Error: ${nameSnapshot.error}'),
                      subtitle: Text(
                        'R1: $round1 | R2: $round2 | R3: $round3 | Birdies: ${birdieCount[playerId]?.values.fold(0, (birdieTotal, birdieValue) => birdieTotal + birdieValue) ?? 0}',
                      ),
                      trailing: Text(
                        '$total pts',
                        style: const TextStyle(fontSize: 18),
                      ),
                    );
                  }
                  final playerName = nameSnapshot.data ?? playerId;
                  return ListTile(
                    leading: Text(
                      '${index + 1}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    title: Text(
                      playerName,
                      style: const TextStyle(fontSize: 18),
                    ),
                    subtitle: Text(
                      'R1: $round1 | R2: $round2 | R3: $round3 | Birdies: ${birdieCount[playerId]?.values.fold(0, (birdieTotal, birdieValue) => birdieTotal + birdieValue) ?? 0}',
                    ),
                    trailing: Text(
                      '$total pts',
                      style: const TextStyle(fontSize: 18),
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
