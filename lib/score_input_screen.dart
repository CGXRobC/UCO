import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreInputScreen extends StatefulWidget {
  final String courseId;
  final String playerName; // if empty, admin will select
  final int round;

  const ScoreInputScreen({
    super.key,
    required this.courseId,
    required this.playerName,
    required this.round,
  });

  @override
  State<ScoreInputScreen> createState() => _ScoreInputScreenState();
}

class _ScoreInputScreenState extends State<ScoreInputScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<int, TextEditingController> _scoreControllers = {};
  final int totalHoles = 18;
  String? selectedPlayer; // For admin dropdown
  List<String> players = [];

  bool get isAdmin => widget.playerName.isEmpty;

  @override
  void initState() {
    super.initState();
    for (int i = 1; i <= totalHoles; i++) {
      _scoreControllers[i] = TextEditingController();
    }
    if (isAdmin) {
      _fetchPlayers();
    } else {
      selectedPlayer = widget.playerName;
    }
  }

  Future<void> _fetchPlayers() async {
    final snapshot = await _firestore
        .collection('courses/${widget.courseId}/players')
        .get();
    setState(() {
      players = snapshot.docs.map((doc) => doc['name'] as String).toList();
      if (players.isNotEmpty) selectedPlayer = players.first;
    });
  }

  @override
  void dispose() {
    for (var controller in _scoreControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveScores() async {
    try {
      // Determine which player we're saving for
      final scorePlayerName = isAdmin ? selectedPlayer : widget.playerName;

      if (scorePlayerName == null || scorePlayerName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select a player to save scores."),
          ),
        );
        return;
      }

      final courseScoresRef = _firestore.collection(
        'courses/${widget.courseId}/scores',
      );
      final batch = _firestore.batch();

      for (int holeNumber = 1; holeNumber <= totalHoles; holeNumber++) {
        final input = _scoreControllers[holeNumber]!.text.trim();
        final score = int.tryParse(input);
        if (score == null) continue;

        // Optional: fetch hole info for points calculation
        final holeSnapshot = await _firestore
            .doc('courses/${widget.courseId}/holes/hole_$holeNumber')
            .get();
        if (!holeSnapshot.exists) continue;

        final par = holeSnapshot['par'] as int;
        final handicap = holeSnapshot['handicap'] as int;

        final points = _calculateStablefordPoints(score, par, handicap);

        // Create a new document reference in scores
        final docRef = courseScoresRef.doc();
        batch.set(docRef, {
          'playerName': scorePlayerName,
          'round': widget.round,
          'hole': holeNumber,
          'grossScore': score,
          'points': points,
          'timestamp': FieldValue.serverTimestamp(),
          'groupCode': widget.courseId,
        });
      }

      // Commit all writes at once
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Scores saved successfully")),
      );

      // Clear input fields
      for (var controller in _scoreControllers.values) {
        controller.clear();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving scores: $e")));
    }
  }

  int _calculateStablefordPoints(int score, int par, int handicap) {
    int diff = par - score;
    if (diff >= 2) return 5;
    if (diff == 1) return 4;
    if (diff == 0) return 2;
    if (diff == -1) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAdmin
              ? 'Admin - Round ${widget.round}'
              : '${widget.playerName} - Round ${widget.round}',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (isAdmin)
              DropdownButtonFormField<String>(
                value: selectedPlayer,
                items: players
                    .map(
                      (name) =>
                          DropdownMenuItem(value: name, child: Text(name)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => selectedPlayer = val),
                decoration: const InputDecoration(
                  labelText: 'Select Player',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: totalHoles,
                itemBuilder: (context, index) {
                  int holeNumber = index + 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: TextField(
                      controller: _scoreControllers[holeNumber],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Hole $holeNumber Score',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveScores,
              child: const Text('Save Scores', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
