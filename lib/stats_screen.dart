import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatsScreen extends StatefulWidget {
  final String courseId;
  final int? round;

  const StatsScreen({super.key, required this.courseId, this.round});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> _holeData = List.generate(
    18,
    (_) => {'par': 0},
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
      print('Fetching course data for courseId: ${widget.courseId}');
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
          _courseError = 'No holes found';
          _isLoadingCourse = false;
        });
        return;
      }

      for (var doc in holesSnapshot.docs) {
        final data = doc.data();
        final holeNumber = (data['hole'] as num?)?.toInt() ?? 0;
        if (holeNumber >= 1 && holeNumber <= 18) {
          final par = (data['par'] as num?)?.toInt() ?? 0;
          _holeData[holeNumber - 1] = {'par': par};
          print('Hole $holeNumber: par=$par');
        }
      }
      setState(() => _isLoadingCourse = false);
    } catch (e) {
      print('Error fetching course data: $e');
      setState(() {
        _courseError = 'Error fetching course data: $e';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats', style: TextStyle(fontSize: 18)),
      ),
      body: _isLoadingCourse
          ? const Center(child: CircularProgressIndicator())
          : _courseError != null
          ? Center(child: Text(_courseError!))
          : StreamBuilder<QuerySnapshot>(
              stream: _scoreStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No scores available'));
                }

                final scores = snapshot.data!.docs;
                print('Fetched scores: ${scores.length} documents');

                final Map<String, Map<String, int>> statsMap = {};

                for (var s in scores) {
                  final playerId = s['playerId'] as String;
                  final points = (s['points'] as num).toInt();
                  final grossScore = (s['grossScore'] as num).toInt();
                  final hole = (s['hole'] as num).toInt() - 1;
                  final holePar = _holeData[hole]['par'] as int;

                  if (holePar == 0) continue;

                  final parDiff = grossScore - holePar;
                  print(
                    'Player $playerId, Hole ${hole + 1}: gross=$grossScore, par=$holePar, parDiff=$parDiff',
                  );

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
                    statsMap[playerId]!['pars'] =
                        statsMap[playerId]!['pars']! + 1;
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
                    (a, b) => b.value['totalPoints']!.compareTo(
                      a.value['totalPoints']!,
                    ),
                  );

                print('Sorted players: ${sortedPlayers.length}');

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
                        if (!playerSnap.hasData) {
                          return const SizedBox();
                        }
                        if (playerSnap.hasError) {
                          return const ListTile(
                            title: Text('Error loading player'),
                          );
                        }
                        final playerData =
                            playerSnap.data!.data() as Map<String, dynamic>?;
                        final playerName =
                            playerData?['name'] as String? ?? 'Unknown';
                        final handicap =
                            (playerData?['handicap'] as num?)?.toInt() ?? 0;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          color: index == 0 ? Colors.amber[100] : null,
                          child: ListTile(
                            title: Text(
                              '$playerName ($handicap)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Points: ${stats['totalPoints']}, Pars: ${stats['pars']}, Birdies: ${stats['birdies']}, Eagles: ${stats['eagles']}, Bogeys: ${stats['bogeys']}, Double+: ${stats['doubleBogeysPlus']}',
                              style: const TextStyle(fontSize: 14),
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
