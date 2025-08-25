import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatefulWidget {
  final String courseId;
  final int? round;

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
      appBar: AppBar(
        title: const Text(
          'Leaderboard',
          style: TextStyle(fontSize: 18), // Smaller font for mobile
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _scoreStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final scores = snapshot.data!.docs;

          // Map playerId -> {totalPoints, currentHole, rounds: {roundNum: {holeData, totalPoints}}}
          final Map<String, Map<String, dynamic>> leaderboard = {};

          for (var s in scores) {
            final playerId = s['playerId'] as String;
            final round = (s['round'] as num).toInt();
            final hole = (s['hole'] as num).toInt();
            final points = (s['points'] as num).toInt();
            final grossScore = (s['grossScore'] as num).toInt();

            if (!leaderboard.containsKey(playerId)) {
              leaderboard[playerId] = {
                'totalPoints': 0,
                'currentHole': 0,
                'rounds': <int, Map<String, dynamic>>{
                  1: {
                    'totalPoints': 0,
                    'holeData': List<Map<String, dynamic>?>.generate(
                      18,
                      (_) => null,
                    ),
                  },
                  2: {
                    'totalPoints': 0,
                    'holeData': List<Map<String, dynamic>?>.generate(
                      18,
                      (_) => null,
                    ),
                  },
                  3: {
                    'totalPoints': 0,
                    'holeData': List<Map<String, dynamic>?>.generate(
                      18,
                      (_) => null,
                    ),
                  },
                },
              };
            }

            leaderboard[playerId]!['totalPoints'] += points;
            if (hole > (leaderboard[playerId]!['currentHole'] as int)) {
              leaderboard[playerId]!['currentHole'] = hole;
            }

            final roundData =
                leaderboard[playerId]!['rounds'][round] as Map<String, dynamic>;
            roundData['totalPoints'] += points;
            final holeData =
                roundData['holeData'] as List<Map<String, dynamic>?>;
            holeData[hole - 1] = {'gross': grossScore, 'points': points};
          }

          // Convert to a list and sort by totalPoints descending
          final sortedPlayers = leaderboard.entries.toList()
            ..sort(
              (a, b) => (b.value['totalPoints'] as int).compareTo(
                a.value['totalPoints'] as int,
              ),
            );

          return ListView.builder(
            itemCount: sortedPlayers.length,
            itemBuilder: (context, index) {
              final playerId = sortedPlayers[index].key;
              final totalPoints = sortedPlayers[index].value['totalPoints'];
              final currentHole = sortedPlayers[index].value['currentHole'];
              final rounds =
                  sortedPlayers[index].value['rounds']
                      as Map<int, Map<String, dynamic>>;

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore
                    .collection('courses/${widget.courseId}/players')
                    .doc(playerId)
                    .get(),
                builder: (context, playerSnap) {
                  if (!playerSnap.hasData) return const SizedBox();
                  final playerName = playerSnap.data!['name'] as String;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ), // Tighter padding
                        leading: Text(
                          '${index + 1}',
                          style: const TextStyle(fontSize: 14), // Smaller font
                        ),
                        title: Text(
                          playerName,
                          style: const TextStyle(fontSize: 16), // Smaller font
                        ),
                        subtitle: Text(
                          'Hole: $currentHole',
                          style: const TextStyle(fontSize: 12), // Smaller font
                        ),
                        trailing: Text(
                          'Pts: $totalPoints',
                          style: const TextStyle(fontSize: 14), // Smaller font
                        ),
                      ),
                      // Display each round's scores
                      ...[1, 2, 3].map((roundNum) {
                        final roundData = rounds[roundNum]!;
                        final holeData =
                            roundData['holeData']
                                as List<Map<String, dynamic>?>;
                        final roundPoints = roundData['totalPoints'] as int;
                        if (holeData.every((data) => data == null)) {
                          return const SizedBox.shrink(); // Skip empty rounds
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 8.0,
                                top: 4.0,
                                bottom: 4.0,
                              ),
                              child: Text(
                                'RND $roundNum (Pts: $roundPoints)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14, // Smaller font
                                ),
                              ),
                            ),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  // Optional: Add hole number labels above scores
                                  const SizedBox(
                                    width: 50,
                                  ), // Space for round label alignment
                                  ...List.generate(18, (i) {
                                    return Container(
                                      width: 24, // Smaller score boxes
                                      height: 24,
                                      margin: const EdgeInsets.all(
                                        1,
                                      ), // Tighter margin
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${i + 1}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                        ), // Tiny hole number
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Container(
                                    width: 50, // Fixed width for round label
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'RND $roundNum',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  ...List.generate(18, (i) {
                                    final data = holeData[i];
                                    if (data == null) {
                                      return Container(
                                        width: 24, // Smaller score boxes
                                        height: 24,
                                        margin: const EdgeInsets.all(
                                          1,
                                        ), // Tighter margin
                                        alignment: Alignment.center,
                                        child: const Text(
                                          '-',
                                          style: TextStyle(
                                            fontSize: 10,
                                          ), // Smaller font
                                        ),
                                      );
                                    }

                                    final gross = data['gross'] as int;
                                    final pts = data['points'] as int;

                                    Color? bgColor;
                                    Color textColor = Colors.black;

                                    if (pts >= 4) {
                                      bgColor = Colors.orange;
                                    } else if (pts == 3) {
                                      bgColor = Colors.red;
                                    } else if (pts == 2) {
                                      bgColor = null; // normal, no bg
                                    } else if (pts == 1) {
                                      bgColor = Colors.black;
                                      textColor =
                                          Colors.white; // for visibility
                                    } else {
                                      bgColor = Colors.grey;
                                    }

                                    return Container(
                                      width: 24, // Smaller score boxes
                                      height: 24,
                                      margin: const EdgeInsets.all(
                                        1,
                                      ), // Tighter margin
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        border: bgColor == null
                                            ? Border.all(
                                                color: Colors.grey,
                                                width: 0.5,
                                              )
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$gross',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 10, // Smaller font
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      const Divider(height: 8), // Tighter divider
                    ],
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
