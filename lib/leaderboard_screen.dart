import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LeaderboardScreen extends StatefulWidget {
  final String courseId;
  final int? round;

  const LeaderboardScreen({super.key, required this.courseId, this.round});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Set<String> _expandedPlayers = {};
  final List<Map<String, dynamic>> _holeData = List.generate(
    18,
    (_) => {'par': 0, 'strokeIndex': 0},
  );
  bool _isLoadingCourse = true;
  String? _courseError;

  @override
  void initState() {
    super.initState();
    _fetchCourseData();
  }

  Future<void> _fetchCourseData() async {
    try {
      print('Fetching hole data for courseId: ${widget.courseId}');
      final holesSnapshot = await _firestore
          .collection('courses')
          .doc(widget.courseId)
          .collection('holes')
          .orderBy('hole')
          .get();
      print('Fetched holes: ${holesSnapshot.docs.length} documents');
      if (holesSnapshot.docs.isEmpty) {
        print('No holes found for courseId: ${widget.courseId}');
        setState(() {
          _courseError = 'No holes found in course';
          _isLoadingCourse = false;
        });
        return;
      }

      for (var doc in holesSnapshot.docs) {
        final data = doc.data();
        final holeNumber = (data['hole'] as num?)?.toInt() ?? 0;
        if (holeNumber >= 1 && holeNumber <= 18) {
          final par = (data['par'] as num?)?.toInt() ?? 0;
          final strokeIndex = (data['handicap'] as num?)?.toInt() ?? 0;
          _holeData[holeNumber - 1] = {'par': par, 'strokeIndex': strokeIndex};
          print('Hole $holeNumber: par=$par, strokeIndex=$strokeIndex');
        }
      }
      setState(() => _isLoadingCourse = false);
    } catch (e) {
      print('Error fetching hole data: $e');
      setState(() {
        _courseError = 'Error fetching hole data: $e';
        _isLoadingCourse = false;
      });
    }
  }

  Stream<QuerySnapshot> _scoreStream() {
    final collection = _firestore.collection(
      'courses/${widget.courseId}/scores',
    );
    if (widget.round != null) {
      return collection.where('round', isEqualTo: widget.round).snapshots();
    }
    return collection.snapshots();
  }

  void _toggleExpand(String playerId) {
    setState(() {
      if (_expandedPlayers.contains(playerId)) {
        _expandedPlayers.remove(playerId);
      } else {
        _expandedPlayers.add(playerId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCourse) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_courseError != null) {
      return Scaffold(body: Center(child: Text(_courseError!)));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard', style: TextStyle(fontSize: 18)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _scoreStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final scores = snapshot.data!.docs;
          print('Fetched scores: ${scores.length} documents');

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

          final sortedPlayers = leaderboard.entries.toList()
            ..sort(
              (a, b) => (b.value['totalPoints'] as int).compareTo(
                a.value['totalPoints'] as int,
              ),
            );

          print('Sorted players: ${sortedPlayers.length}');

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.grey[200],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.zero,
                  title: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            'Pos',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Text(
                              'Name',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Text(
                            'Rnd 1',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Text(
                            'Rnd 2',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Text(
                            'Rnd 3',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                expandedHeight: 50,
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
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
                      final playerData =
                          playerSnap.data!.data() as Map<String, dynamic>?;
                      final playerName =
                          playerData?['name'] as String? ?? 'Unknown';
                      final handicap =
                          (playerData?['handicap'] as num?)?.toInt() ?? 0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _toggleExpand(playerId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              color: index == 0 ? Colors.amber[100] : null,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 30,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Row(
                                        children: [
                                          Text(
                                            '$playerName ($handicap)',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(width: 8),
                                          FaIcon(
                                            _expandedPlayers.contains(playerId)
                                                ? FontAwesomeIcons.chevronUp
                                                : FontAwesomeIcons.chevronDown,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      '${rounds[1]!['totalPoints']}',
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      '${rounds[2]!['totalPoints']}',
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      '${rounds[3]!['totalPoints']}',
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      '$totalPoints',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_expandedPlayers.contains(playerId))
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8.0,
                                    top: 4.0,
                                  ),
                                  child: Text(
                                    'Hole: $currentHole',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                ...[1, 2, 3].map((roundNum) {
                                  final roundData = rounds[roundNum]!;
                                  final holeData =
                                      roundData['holeData']
                                          as List<Map<String, dynamic>?>;
                                  final roundPoints =
                                      roundData['totalPoints'] as int;
                                  if (holeData.every((data) => data == null)) {
                                    return const SizedBox.shrink();
                                  }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      // Par Row
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 50,
                                              alignment: Alignment.centerLeft,
                                              child: const Text(
                                                'Par',
                                                style: TextStyle(fontSize: 10),
                                              ),
                                            ),
                                            ...List.generate(18, (i) {
                                              final par =
                                                  _holeData[i]['par'] as int;
                                              return Container(
                                                width: 24,
                                                height: 18,
                                                margin: const EdgeInsets.all(1),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  par == 0 ? '-' : '$par',
                                                  style: const TextStyle(
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                      // Stroke Index Row
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 50,
                                              alignment: Alignment.centerLeft,
                                              child: const Text(
                                                'S.I.',
                                                style: TextStyle(fontSize: 10),
                                              ),
                                            ),
                                            ...List.generate(18, (i) {
                                              final strokeIndex =
                                                  _holeData[i]['strokeIndex']
                                                      as int;
                                              return Container(
                                                width: 24,
                                                height: 18,
                                                margin: const EdgeInsets.all(1),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  strokeIndex == 0
                                                      ? '-'
                                                      : '$strokeIndex',
                                                  style: const TextStyle(
                                                    fontSize: 8,
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                      // Gross Score Row
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 50,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'RND $roundNum',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                            ...List.generate(18, (i) {
                                              final data = holeData[i];
                                              if (data == null) {
                                                return Container(
                                                  width: 24,
                                                  height: 24,
                                                  margin: const EdgeInsets.all(
                                                    1,
                                                  ),
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: Colors.grey,
                                                      width: 0.5,
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    '-',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                );
                                              }

                                              final gross =
                                                  data['gross'] as int;
                                              print(
                                                'Hole ${i + 1}: gross=$gross, points=${data['points']}',
                                              );

                                              return Container(
                                                width: 24,
                                                height: 24,
                                                margin: const EdgeInsets.all(1),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.grey,
                                                    width: 0.5,
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '$gross',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                      // Points Row
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 50,
                                              alignment: Alignment.centerLeft,
                                              child: const Text(
                                                'Pts',
                                                style: TextStyle(fontSize: 10),
                                              ),
                                            ),
                                            ...List.generate(18, (i) {
                                              final data = holeData[i];
                                              if (data == null) {
                                                return Container(
                                                  width: 24,
                                                  height: 18,
                                                  margin: const EdgeInsets.all(
                                                    1,
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: const Text(
                                                    '-',
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                    ),
                                                  ),
                                                );
                                              }

                                              final points =
                                                  data['points'] as int;

                                              return Container(
                                                width: 24,
                                                height: 18,
                                                margin: const EdgeInsets.all(1),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '$points',
                                                  style: const TextStyle(
                                                    fontSize: 8,
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          const Divider(height: 8),
                        ],
                      );
                    },
                  );
                }, childCount: sortedPlayers.length),
              ),
            ],
          );
        },
      ),
    );
  }
}
