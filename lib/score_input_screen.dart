import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreInputScreen extends StatefulWidget {
  final int round;
  final String? playerName;
  const ScoreInputScreen({super.key, required this.round, this.playerName});

  @override
  State<ScoreInputScreen> createState() => _ScoreInputScreenState();
}

class _ScoreInputScreenState extends State<ScoreInputScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _hole = 1;
  int _score = 0;
  String? _selectedPlayerId; // Use ID instead of name
  final Map<String, String> _players = {}; // Made final, initialized empty
  double? _selectedHandicap;
  String? _groupCode;
  final TextEditingController _scoreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPlayers();
    _fetchGroupCode();
    if (widget.playerName != null) {
      _fetchPlayerIdFromName(widget.playerName!);
    }
  }

  Future<void> _fetchPlayers() async {
    final querySnapshot = await _firestore.collection('players').get();
    setState(() {
      _players.clear(); // Clear existing map
      _players.addAll({
        for (var doc in querySnapshot.docs) doc['name'] as String: doc.id,
      });
    });
    print('Fetched players: $_players');
  }

  Future<void> _fetchPlayerIdFromName(String name) async {
    final querySnapshot = await _firestore
        .collection('players')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        _selectedPlayerId = querySnapshot.docs.first.id;
        _fetchPlayerHandicap(); // Fetch handicap for the player
      });
      print('Set _selectedPlayerId to: $_selectedPlayerId for player $name');
    }
  }

  Future<void> _fetchGroupCode() async {
    final snapshot = await _firestore.collection('settings').doc('group').get();
    setState(() {
      _groupCode = snapshot.data()?['code']?.trim() ?? 'UCO2025';
    });
    print('Group code set to: $_groupCode');
  }

  Future<bool> _playerExists(String playerId) async {
    final querySnapshot = await _firestore
        .collection('players')
        .where(FieldPath.documentId, isEqualTo: playerId)
        .limit(1)
        .get();
    if (querySnapshot.docs.isEmpty) {
      print('Player $playerId not found by ID');
      return false;
    } else {
      print('Player $playerId found by ID: ${querySnapshot.docs.first.id}');
      return true;
    }
  }

  Future<void> _fetchPlayerHandicap() async {
    if (_selectedPlayerId != null) {
      final playerDoc = await _firestore
          .collection('players')
          .doc(_selectedPlayerId)
          .get();
      if (playerDoc.exists) {
        setState(() {
          _selectedHandicap = playerDoc['handicap'] as double?;
        });
      }
    }
  }

  Future<int> _getParForHole(int hole) async {
    final DocumentSnapshot doc = await _firestore
        .collection('course')
        .doc('hole_$hole')
        .get();
    return doc.exists ? doc['par'] as int : 4;
  }

  Future<double?> _holeHandicapAdjustment(int hole) async {
    final doc = await _firestore.collection('course').doc('hole_$hole').get();
    return doc.exists ? (doc['handicap'] as double? ?? 1.0) : 1.0;
  }

  Future<void> _submitScore() async {
    if (_score < 1 ||
        _score > 12 ||
        _selectedPlayerId == null ||
        _groupCode == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Select a player, enter a valid score (1-12), and set a group code',
            ),
          ),
        );
      }
      print(
        'Submission failed: _score=$_score, _selectedPlayerId=$_selectedPlayerId, _groupCode=$_groupCode',
      );
      return;
    }

    if (!(await _playerExists(_selectedPlayerId!))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Player not found in database.')),
        );
      }
      print('Submission failed: Player $_selectedPlayerId not found');
      return;
    }

    final int par = await _getParForHole(_hole);
    final double handicapIndex = _selectedHandicap ?? 24;
    final DocumentSnapshot courseSettings = await _firestore
        .collection('course_settings')
        .doc('settings')
        .get();
    final Map<String, dynamic>? courseData =
        courseSettings.data() as Map<String, dynamic>?;
    final int slopeRating = courseData?['slopeRating'] as int? ?? 127;
    final double courseRating = courseData?['courseRating'] as double? ?? 70.9;
    final String courseName =
        courseData?['name'] as String? ?? 'China Fleet Country Club';
    final int courseHandicap = ((handicapIndex * slopeRating) / 113).round();
    final double strokes = courseHandicap / 18.0;
    final double? holeAdjustment = await _holeHandicapAdjustment(_hole);
    final int netScore = _score - (strokes * (holeAdjustment ?? 1.0)).round();
    int points = 0;
    bool isBirdie = false;
    if (netScore - par >= 2) {
      points = 0; // Double bogey+
    } else if (netScore - par == 1) {
      points = 1; // Bogey
    } else if (netScore - par == 0) {
      points = 2; // Par
    } else if (netScore - par == -1) {
      points = 3; // Birdie
      isBirdie = true;
    } else if (netScore - par == -2) {
      points = 4; // Eagle
    } else if (netScore - par == -3) {
      points = 5; // Albatross
    }

    try {
      await _firestore.collection('scores').add({
        'player': _selectedPlayerId,
        'hole': _hole,
        'grossScore': _score,
        'points': points,
        'round': widget.round,
        'groupCode': _groupCode,
        'isBirdie': isBirdie,
        'timestamp': Timestamp.now(),
        'courseName': courseName,
        'courseRating': courseRating,
        'slopeRating': slopeRating,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Score submitted for hole $_hole, Round ${widget.round}',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error submitting score: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting score: $e')));
      }
    }

    setState(() {
      _scoreController.clear();
      _score = 0;
      _hole = _hole < 18 ? _hole + 1 : 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Round ${widget.round} Scores')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Group Code: ${_groupCode ?? "Not set"}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (widget.playerName == null) // Admin can select player
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('players').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return const Text('Loading players...');
                  }
                  final List<DropdownMenuItem<String>> playerItems = snapshot
                      .data!
                      .docs
                      .map((doc) {
                        return DropdownMenuItem<String>(
                          value: doc.id, // Use document ID as value
                          child: Text(doc['name'] as String),
                        );
                      })
                      .toList();
                  return DropdownButton<String>(
                    value: _selectedPlayerId,
                    hint: const Text('Select Player'),
                    items: playerItems,
                    onChanged: (value) {
                      setState(() {
                        _selectedPlayerId = value;
                        _fetchPlayerHandicap(); // Fetch handicap for selected ID
                      });
                    },
                  );
                },
              )
            else // Player sees their name
              Text(
                'Player: ${widget.playerName}',
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 16),
            DropdownButton<int>(
              value: _hole,
              items: List.generate(
                18,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text('Hole ${i + 1}'),
                ),
              ),
              onChanged: (value) => setState(() => _hole = value!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _scoreController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter Gross Score (1-12)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _score = int.tryParse(value) ?? 0,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: _submitScore,
              child: const Text('Submit Score', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
