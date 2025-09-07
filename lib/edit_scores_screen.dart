import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class EditScoresScreen extends StatefulWidget {
  final String courseId;
  const EditScoresScreen({super.key, required this.courseId});

  @override
  State<EditScoresScreen> createState() => _EditScoresScreenState();
}

class _EditScoresScreenState extends State<EditScoresScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedPlayerId;
  String? _selectedPlayerName;
  int _selectedRound = 1;
  int _playerHandicap = 0;
  List<Map<String, dynamic>> _holeData = List.generate(
    18,
    (_) => {'par': 0, 'strokeIndex': '0', 'grossScore': '', 'points': '0'},
  );
  bool _isLoading = true;
  bool _isSaving = false;
  final List<TextEditingController> _scoreControllers = List.generate(
    18,
    (_) => TextEditingController(),
  );

  @override
  void initState() {
    super.initState();
    _fetchCourseData();
  }

  @override
  void dispose() {
    for (var controller in _scoreControllers) {
      controller.dispose();
    }
    super.dispose();
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: No holes found in course')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      for (var doc in holesSnapshot.docs) {
        final data = doc.data();
        final holeNumber = (data['hole'] as num?)?.toInt() ?? 0;
        if (holeNumber >= 1 && holeNumber <= 18) {
          final par = (data['par'] as num?)?.toInt() ?? 0;
          final strokeIndex = (data['handicap'] as num?)?.toInt() ?? 0;
          _holeData[holeNumber - 1] = {
            'par': par,
            'strokeIndex': strokeIndex.toString(),
            'grossScore': '',
            'points': '0',
          };
          print('Hole $holeNumber: par=$par, strokeIndex=$strokeIndex');
        }
      }
      print('Fetched course data: $_holeData');
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error fetching hole data: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching hole data: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPlayerScores() async {
    if (_selectedPlayerId == null || _selectedRound == 0) return;

    setState(() => _isLoading = true);
    try {
      final playerDoc = await _firestore
          .collection('courses/${widget.courseId}/players')
          .doc(_selectedPlayerId)
          .get();
      _playerHandicap = (playerDoc.data()?['handicap'] as num?)?.toInt() ?? 0;
      print('Fetched player $_selectedPlayerId handicap: $_playerHandicap');
      if (!playerDoc.exists || playerDoc.data()?['handicap'] == null) {
        print('Warning: No handicap for player $_selectedPlayerId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Warning: Player handicap not set')),
          );
        }
      }

      final scoresQuery = await _firestore
          .collection('courses/${widget.courseId}/scores')
          .where('playerId', isEqualTo: _selectedPlayerId)
          .where('round', isEqualTo: _selectedRound)
          .get();

      final tempHoleData = List<Map<String, dynamic>>.from(_holeData);
      for (int i = 0; i < 18; i++) {
        _scoreControllers[i].text = '';
        tempHoleData[i]['grossScore'] = '';
        tempHoleData[i]['points'] = '0';
      }

      for (var doc in scoresQuery.docs) {
        final hole = (doc['hole'] as num).toInt() - 1;
        final grossScore = (doc['grossScore'] as num).toInt();
        final points = (doc['points'] as num).toInt();
        tempHoleData[hole] = {
          'par': tempHoleData[hole]['par'],
          'strokeIndex': tempHoleData[hole]['strokeIndex'],
          'grossScore': grossScore.toString(),
          'points': points.toString(),
        };
        _scoreControllers[hole].text = grossScore.toString();
      }

      for (int i = 0; i < 18; i++) {
        if (tempHoleData[i]['grossScore'] != '') {
          final grossScore = int.tryParse(tempHoleData[i]['grossScore']) ?? 0;
          tempHoleData[i]['points'] = _calculatePointsForHole(
            i,
            grossScore,
          ).toString();
        }
      }

      setState(() {
        _holeData = tempHoleData;
        _isLoading = false;
      });
      print('Fetched player scores: $_holeData');
    } catch (e) {
      print('Error fetching player scores: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching player scores: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  int _calculatePointsForHole(int holeIndex, int grossScore) {
    if (grossScore == 0) return 0;

    final par = _holeData[holeIndex]['par'] as int;
    final strokeIndex = int.parse(_holeData[holeIndex]['strokeIndex']);
    int strokesReceived = 0;
    if (_playerHandicap >= strokeIndex) {
      strokesReceived = 1;
      if (_playerHandicap >= strokeIndex + 18) {
        strokesReceived = 2;
      }
    }
    final netScore = grossScore - strokesReceived;
    final points = (2 + par - netScore).clamp(0, 6);
    print(
      'Hole ${holeIndex + 1}: gross=$grossScore, par=$par, strokeIndex=$strokeIndex, handicap=$_playerHandicap, strokesReceived=$strokesReceived, netScore=$netScore, points=$points',
    );
    return points;
  }

  Future<void> _saveScores() async {
    if (_selectedPlayerId == null || _selectedRound == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a player and round')),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      final batch = _firestore.batch();

      // Delete all existing scores for this player and round
      final existingScores = await _firestore
          .collection('courses/${widget.courseId}/scores')
          .where('playerId', isEqualTo: _selectedPlayerId)
          .where('round', isEqualTo: _selectedRound)
          .get();
      for (var doc in existingScores.docs) {
        batch.delete(doc.reference);
      }
      print(
        'Deleted ${existingScores.docs.length} existing scores for player $_selectedPlayerId, round $_selectedRound',
      );

      // Save new scores
      for (int i = 0; i < 18; i++) {
        final grossScore = int.tryParse(_scoreControllers[i].text) ?? 0;
        if (grossScore > 0) {
          final points = _calculatePointsForHole(i, grossScore);
          final scoreRef = _firestore
              .collection('courses/${widget.courseId}/scores')
              .doc('${_selectedPlayerId}_${_selectedRound}_${i + 1}');
          batch.set(scoreRef, {
            'playerId': _selectedPlayerId,
            'round': _selectedRound,
            'hole': i + 1,
            'grossScore': grossScore,
            'points': points,
          });
        }
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scores updated successfully')),
        );
      }
      await _fetchPlayerScores();
    } catch (e) {
      print('Error saving scores: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving scores: $e')));
      }
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Player Scores')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display Selected Player Name
                    if (_selectedPlayerName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Editing Scores for $_selectedPlayerName (Handicap: $_playerHandicap)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    // Player Dropdown
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('courses/${widget.courseId}/players')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        final players = snapshot.data!.docs;
                        return DropdownButton<String>(
                          value: _selectedPlayerId,
                          hint: const Text('Select Player'),
                          isExpanded: true,
                          items: players.map((doc) {
                            final name = doc['name'] as String;
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPlayerId = value;
                              _selectedPlayerName =
                                  players.firstWhere(
                                        (doc) => doc.id == value,
                                      )['name']
                                      as String;
                              _fetchPlayerScores();
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Round Dropdown
                    DropdownButton<int>(
                      value: _selectedRound,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Round 1')),
                        DropdownMenuItem(value: 2, child: Text('Round 2')),
                        DropdownMenuItem(value: 3, child: Text('Round 3')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRound = value!;
                          _fetchPlayerScores();
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Header Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.yellow[100],
                              border: Border.all(color: Colors.grey, width: 1),
                            ),
                            child: const Text(
                              'Hole',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              border: Border.all(color: Colors.grey, width: 1),
                            ),
                            child: const Text(
                              'Par',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              border: Border.all(color: Colors.grey, width: 1),
                            ),
                            child: const Text(
                              'SI',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            width: 50,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 1),
                            ),
                            child: const Text(
                              'Score',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              border: Border.all(color: Colors.grey, width: 1),
                            ),
                            child: const Text(
                              'Pts',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Data Rows
                    ...List.generate(18, (index) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              decoration: BoxDecoration(
                                color: Colors.yellow[100],
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Container(
                              width: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${_holeData[index]['par']}',
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Container(
                              width: 50,
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _holeData[index]['strokeIndex'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Container(
                              width: 50,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9]'),
                                  ),
                                ],
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: const TextStyle(fontSize: 12),
                                controller: _scoreControllers[index],
                                onChanged: (value) {
                                  final grossScore = int.tryParse(value) ?? 0;
                                  setState(() {
                                    _holeData[index]['grossScore'] = value;
                                    _holeData[index]['points'] =
                                        _calculatePointsForHole(
                                          index,
                                          grossScore,
                                        ).toString();
                                  });
                                },
                              ),
                            ),
                            Container(
                              width: 50,
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _holeData[index]['points'],
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Total Points
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Total Points: ${_holeData.fold(0, (total, hole) => total + (int.tryParse(hole['points'] ?? '0') ?? 0))}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Save Button
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Confirm Save'),
                                        content: const Text(
                                          'Replace existing scores for this round?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Save'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) _saveScores();
                                  },
                            child: _isSaving
                                ? const CircularProgressIndicator()
                                : const Text(
                                    'Save Scores',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    // Clear Scores Button
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                            onPressed: _isSaving || _selectedPlayerId == null
                                ? null
                                : () async {
                                    setState(() => _isSaving = true);
                                    final batch = _firestore.batch();
                                    final scoresQuery = await _firestore
                                        .collection(
                                          'courses/${widget.courseId}/scores',
                                        )
                                        .where(
                                          'playerId',
                                          isEqualTo: _selectedPlayerId,
                                        )
                                        .where(
                                          'round',
                                          isEqualTo: _selectedRound,
                                        )
                                        .get();
                                    for (var doc in scoresQuery.docs) {
                                      batch.delete(doc.reference);
                                    }
                                    await batch.commit();
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Scores cleared'),
                                        ),
                                      );
                                    }
                                    await _fetchPlayerScores();
                                    setState(() => _isSaving = false);
                                  },
                            child: const Text(
                              'Clear Scores',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
