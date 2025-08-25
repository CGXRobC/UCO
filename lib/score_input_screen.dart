import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreInputScreen extends StatefulWidget {
  final int round;
  final String? playerName;
  final String courseId; // New required courseId parameter

  const ScoreInputScreen({
    super.key,
    required this.round,
    this.playerName,
    required this.courseId,
  });

  @override
  State<ScoreInputScreen> createState() => _ScoreInputScreenState();
}

class _ScoreInputScreenState extends State<ScoreInputScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _hole = 1;
  int _score = 0;
  String? _selectedPlayerId;
  double? _selectedHandicap;
  final TextEditingController _scoreController = TextEditingController();
  String? _groupCode;

  late CollectionReference playersCollection;
  late CollectionReference holesCollection;
  late CollectionReference scoresCollection;
  late DocumentReference courseDocRef;

  @override
  void initState() {
    super.initState();

    // References using courseId
    courseDocRef = _firestore
        .collection('course_settings')
        .doc(widget.courseId);
    playersCollection = courseDocRef.collection('players');
    holesCollection = courseDocRef.collection('holes');
    scoresCollection = courseDocRef.collection('scores');

    _fetchPlayers();
    _fetchGroupCode();
    if (widget.playerName != null) {
      _fetchPlayerIdFromName(widget.playerName!);
    }
  }

  Future<void> _fetchPlayers() async {
    final querySnapshot = await playersCollection.get();
    if (querySnapshot.docs.isNotEmpty &&
        _selectedPlayerId == null &&
        widget.playerName == null) {
      setState(() {
        _selectedPlayerId =
            querySnapshot.docs.first.id; // default select first player
        _fetchPlayerHandicap();
      });
    }
  }

  Future<void> _fetchPlayerIdFromName(String name) async {
    final querySnapshot = await playersCollection
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        _selectedPlayerId = querySnapshot.docs.first.id;
        _fetchPlayerHandicap();
      });
    }
  }

  Future<void> _fetchPlayerHandicap() async {
    if (_selectedPlayerId != null) {
      final doc = await playersCollection.doc(_selectedPlayerId).get();
      if (doc.exists) {
        setState(() {
          _selectedHandicap = doc['handicap']?.toDouble() ?? 24.0;
        });
      }
    }
  }

  Future<int> _getParForHole(int hole) async {
    final doc = await holesCollection.doc('hole_$hole').get();
    return doc.exists ? doc['par'] as int : 4;
  }

  Future<int> _getStrokeIndexForHole(int hole) async {
    final doc = await holesCollection.doc('hole_$hole').get();
    return doc.exists ? doc['handicap'] as int : 1;
  }

  Future<void> _fetchGroupCode() async {
    final snapshot = await courseDocRef.get();
    setState(() {
      _groupCode = snapshot.data()?['name'] ?? 'UCO2025';
    });
  }

  Future<void> _submitScore() async {
    if (_score < 1 || _score > 12 || _selectedPlayerId == null) return;

    final par = await _getParForHole(_hole);
    final strokeIndex = await _getStrokeIndexForHole(_hole);
    final handicapIndex = _selectedHandicap ?? 24;
    final courseDoc = await courseDocRef.get();
    final slopeRating = courseDoc['slopeRating'] as int? ?? 127;
    final courseRating = courseDoc['courseRating'] as double? ?? 70.9;

    // Course handicap calculation
    final courseHandicap = ((handicapIndex * slopeRating) / 113).round();
    final strokes = courseHandicap / 18.0;
    final netScore = _score - (strokes * strokeIndex).round();

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

    await scoresCollection.add({
      'player': _selectedPlayerId,
      'round': widget.round,
      'hole': _hole,
      'grossScore': _score,
      'netScore': netScore,
      'points': points,
      'isBirdie': isBirdie,
      'timestamp': Timestamp.now(),
      'courseName': courseDoc['name'],
      'courseRating': courseRating,
      'slopeRating': slopeRating,
    });

    setState(() {
      _scoreController.clear();
      _score = 0;
      _hole = _hole < 18 ? _hole + 1 : 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Round ${widget.round} Scores')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.playerName == null)
              StreamBuilder<QuerySnapshot>(
                stream: playersCollection.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();

                  final items = snapshot.data!.docs
                      .map(
                        (doc) => DropdownMenuItem(
                          value: doc.id,
                          child: Text(doc['name']),
                        ),
                      )
                      .toList();

                  return DropdownButton<String>(
                    value: _selectedPlayerId,
                    hint: const Text('Select Player'),
                    items: items,
                    onChanged: (val) {
                      setState(() {
                        _selectedPlayerId = val;
                        _fetchPlayerHandicap();
                      });
                    },
                  );
                },
              )
            else
              Text('Player: ${widget.playerName}'),

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
              onChanged: (val) => setState(() => _hole = val!),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _scoreController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter Gross Score (1-12)',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => _score = int.tryParse(val) ?? 0,
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitScore,
              child: const Text('Submit Score'),
            ),
          ],
        ),
      ),
    );
  }
}
