import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; // Added for max function

class ScoreInputScreen extends StatefulWidget {
  final String courseId;
  final String playerName; // optional for admin
  final String? playerId; // store the player document ID
  final int round;

  const ScoreInputScreen({
    super.key,
    required this.courseId,
    required this.playerName,
    this.playerId,
    required this.round,
  });

  @override
  State<ScoreInputScreen> createState() => _ScoreInputScreenState();
}

class _ScoreInputScreenState extends State<ScoreInputScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<int, TextEditingController> _scoreControllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  final Map<int, String> _pointsDisplay = {};
  final Map<int, bool> _isEditable = {}; // Track editability per hole
  final int totalHoles = 18;
  String? selectedPlayerName; // For admin dropdown
  String? selectedPlayerId; // For admin dropdown
  List<Map<String, String>> players = []; // {id, name}
  int? playerHandicap;
  Map<int, Map<String, int>> holeData = {}; // hole -> {par, strokeIndex}
  bool isLoading = true;

  bool get isAdmin => widget.playerName.isEmpty;

  @override
  void initState() {
    super.initState();
    for (int i = 1; i <= totalHoles; i++) {
      _scoreControllers[i] = TextEditingController();
      _focusNodes[i] = FocusNode()..addListener(() => _handleFocusChange(i));
      _isEditable[i] = true; // Initialize as editable
      _scoreControllers[i]!.addListener(() => _updatePoints(i)); // Add listener
    }
    _fetchHoleData();
    if (isAdmin) {
      _fetchPlayers();
    } else {
      selectedPlayerName = widget.playerName;
      selectedPlayerId = widget.playerId;
      _fetchPlayerData();
    }
  }

  Future<void> _fetchPlayers() async {
    try {
      final snapshot = await _firestore
          .collection('courses/${widget.courseId}/players')
          .get();
      setState(() {
        players = snapshot.docs
            .map((doc) => {'id': doc.id, 'name': doc['name'] as String})
            .toList();
        if (players.isNotEmpty) {
          selectedPlayerName = players.first['name'];
          selectedPlayerId = players.first['id'];
          _fetchPlayerData();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error fetching players: $e")));
      }
    }
  }

  Future<void> _fetchPlayerData() async {
    if (selectedPlayerId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }
    try {
      final playerSnapshot = await _firestore
          .doc('courses/${widget.courseId}/players/$selectedPlayerId')
          .get();
      if (playerSnapshot.exists) {
        setState(() {
          playerHandicap = playerSnapshot['handicap'] as int? ?? 0;
        });
      }

      final scoresSnapshot = await _firestore
          .collection('courses/${widget.courseId}/scores')
          .where('playerId', isEqualTo: selectedPlayerId)
          .where('round', isEqualTo: widget.round)
          .get();

      for (var doc in scoresSnapshot.docs) {
        final hole = doc['hole'] as int;
        final grossScore = doc['grossScore'] as int;
        final points = doc['points'] as int;
        _scoreControllers[hole]!.text = grossScore.toString();
        _pointsDisplay[hole] = points
            .toString(); // Initial points from Firestore
        _isEditable[hole] = false;
        print(
          'Fetched score for hole $hole: gross=$grossScore, points=$points',
        );
      }

      // Recalculate points for all fetched scores
      for (var doc in scoresSnapshot.docs) {
        final hole = doc['hole'] as int;
        _pointsDisplay[hole] = _calculateStablefordPoints(
          int.tryParse(_scoreControllers[hole]!.text) ?? 0,
          holeData[hole]!['par']!,
          holeData[hole]!['strokeIndex']!,
          playerHandicap!,
        ).toString();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching player data: $e")),
        );
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchHoleData() async {
    for (int holeNumber = 1; holeNumber <= totalHoles; holeNumber++) {
      try {
        final holeSnapshot = await _firestore
            .doc('courses/${widget.courseId}/holes/hole_$holeNumber')
            .get();
        if (holeSnapshot.exists) {
          holeData[holeNumber] = {
            'par': holeSnapshot['par'] as int,
            'strokeIndex': holeSnapshot['handicap'] as int,
          };
        }
      } catch (e) {
        // Handle error if needed
      }
    }
    setState(() {}); // Refresh if needed
  }

  int _calculateStablefordPoints(
    int grossScore,
    int par,
    int strokeIndex,
    int playerHandicap,
  ) {
    int strokes = playerHandicap ~/ 18;
    if (strokeIndex <= (playerHandicap % 18)) {
      strokes++;
    }
    int netScore = grossScore - strokes;
    int diff = par - netScore;
    return max(0, 2 + diff);
  }

  void _updatePoints(int holeNumber) {
    final input = _scoreControllers[holeNumber]!.text.trim();
    final score = int.tryParse(input);
    if (score == null ||
        playerHandicap == null ||
        !holeData.containsKey(holeNumber)) {
      setState(() {
        _pointsDisplay[holeNumber] = '';
      });
      return;
    }
    final points = _calculateStablefordPoints(
      score,
      holeData[holeNumber]!['par']!,
      holeData[holeNumber]!['strokeIndex']!,
      playerHandicap!,
    );
    setState(() {
      _pointsDisplay[holeNumber] = '$points';
      print(
        'Updated points for hole $holeNumber: score=$score, points=$points',
      );
    });
  }

  void _handleFocusChange(int holeNumber) {
    if (!_focusNodes[holeNumber]!.hasFocus) {
      _saveSingleHole(holeNumber);
    }
  }

  Future<void> _saveSingleHole(int holeNumber) async {
    try {
      final playerName = isAdmin ? selectedPlayerName : widget.playerName;
      final playerId = isAdmin ? selectedPlayerId : widget.playerId;

      if (playerName == null || playerId == null || playerHandicap == null) {
        return;
      }

      final input = _scoreControllers[holeNumber]!.text.trim();
      final score = int.tryParse(input);
      if (score == null || !holeData.containsKey(holeNumber)) return;

      final par = holeData[holeNumber]!['par']!;
      final strokeIndex = holeData[holeNumber]!['strokeIndex']!;
      final points = _calculateStablefordPoints(
        score,
        par,
        strokeIndex,
        playerHandicap!,
      );

      final docId = '${playerId}_round${widget.round}_hole$holeNumber';
      final docRef = _firestore
          .collection('courses/${widget.courseId}/scores')
          .doc(docId);

      await docRef.set({
        'playerId': playerId,
        'playerName': playerName,
        'round': widget.round,
        'hole': holeNumber,
        'grossScore': score,
        'points': points,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _isEditable[holeNumber] = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Hole $holeNumber saved")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving hole $holeNumber: $e")),
        );
      }
    }
  }

  Future<void> _saveAllScores() async {
    for (int holeNumber = 1; holeNumber <= totalHoles; holeNumber++) {
      if (_isEditable[holeNumber] ?? true) {
        await _saveSingleHole(holeNumber);
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _scoreControllers.values) {
      controller.dispose();
    }
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAdmin
              ? 'Admin - Round ${widget.round}'
              : '${widget.playerName} - Round ${widget.round}',
          style: const TextStyle(fontSize: 18),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            if (isAdmin)
              DropdownButtonFormField<String>(
                initialValue: selectedPlayerId,
                items: players
                    .map(
                      (p) => DropdownMenuItem(
                        value: p['id'],
                        child: Text(
                          p['name']!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedPlayerId = val;
                    selectedPlayerName = players.firstWhere(
                      (p) => p['id'] == val,
                    )['name'];
                    isLoading = true;
                    for (int i = 1; i <= totalHoles; i++) {
                      _scoreControllers[i]!.clear();
                      _pointsDisplay[i] = '';
                      _isEditable[i] = true;
                    }
                  });
                  _fetchPlayerData();
                },
                decoration: const InputDecoration(
                  labelText: 'Select Player',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(fontSize: 14),
                ),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                  const SizedBox(width: 8),
                  Container(
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
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
                  const SizedBox(width: 8),
                  Container(
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.grey, width: 1),
                    ),
                    child: const Text(
                      'S.I.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 70,
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
                  const SizedBox(width: 8),
                  Container(
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
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
            Expanded(
              child: ListView.builder(
                itemCount: totalHoles,
                itemBuilder: (context, index) {
                  int holeNumber = index + 1;
                  final par = holeData[holeNumber]?['par']?.toString() ?? '-';
                  final strokeIndex =
                      holeData[holeNumber]?['strokeIndex']?.toString() ?? '-';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.yellow[100],
                            border: Border.all(color: Colors.grey, width: 1),
                          ),
                          child: Text(
                            '$holeNumber',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border.all(color: Colors.grey, width: 1),
                          ),
                          child: Text(
                            par,
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            border: Border.all(color: Colors.grey, width: 1),
                          ),
                          child: Text(
                            strokeIndex,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: TextField(
                            controller: _scoreControllers[holeNumber],
                            focusNode: _focusNodes[holeNumber],
                            keyboardType: TextInputType.number,
                            enabled: _isEditable[holeNumber] ?? true,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 4,
                              ),
                              border: const OutlineInputBorder(),
                              filled: !(_isEditable[holeNumber] ?? true),
                              fillColor: !(_isEditable[holeNumber] ?? true)
                                  ? Colors.grey[200]
                                  : null,
                            ),
                            onChanged: (value) {
                              final grossScore = int.tryParse(value) ?? 0;
                              _updatePoints(
                                holeNumber,
                              ); // Recalculate on change
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            border: Border.all(color: Colors.grey, width: 1),
                          ),
                          child: Text(
                            _pointsDisplay[holeNumber] ?? '',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saveAllScores,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Save All Scores',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
