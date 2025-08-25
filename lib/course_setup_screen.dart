import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'player_setup_screen.dart';

class CourseSetupScreen extends StatefulWidget {
  const CourseSetupScreen({super.key});

  @override
  State<CourseSetupScreen> createState() => _CourseSetupScreenState();
}

class _CourseSetupScreenState extends State<CourseSetupScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _courseNameController = TextEditingController(
    text: 'China Fleet Country Club',
  );
  final TextEditingController _courseRatingController = TextEditingController(
    text: '70.9',
  );
  final TextEditingController _slopeRatingController = TextEditingController(
    text: '127',
  );

  late DocumentReference _courseDocRef;

  @override
  void initState() {
    super.initState();
    _courseDocRef = _firestore.collection('course_settings').doc('UCO2025');
  }

  Future<void> _saveCourseSettings() async {
    try {
      await _courseDocRef.set({
        'name': _courseNameController.text.trim(),
        'courseRating':
            double.tryParse(_courseRatingController.text.trim()) ?? 70.9,
        'slopeRating': int.tryParse(_slopeRatingController.text.trim()) ?? 127,
      });

      // Automatically create 18 holes if not exist
      await _createHoles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course and holes saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving course: $e')));
      }
    }
  }

  Future<void> _createHoles() async {
    final holesCollection = _courseDocRef.collection('holes');

    for (int i = 1; i <= 18; i++) {
      final doc = holesCollection.doc('hole_$i');
      final snapshot = await doc.get();

      if (!snapshot.exists) {
        await doc.set({
          'hole': i,
          'par': 4, // default par
          'handicap': i, // default stroke index
        });
      }
    }
  }

  Future<void> _updateHole(int holeNumber, int par, int handicap) async {
    await _courseDocRef.collection('holes').doc('hole_$holeNumber').update({
      'par': par,
      'handicap': handicap,
    });
  }

  @override
  Widget build(BuildContext context) {
    final holesCollection = _courseDocRef.collection('holes');

    return Scaffold(
      appBar: AppBar(title: const Text('Set Up Course')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _courseNameController,
              decoration: const InputDecoration(
                labelText: 'Course Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _courseRatingController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Course Rating',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _slopeRatingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Slope Rating',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveCourseSettings,
              child: const Text('Save Course and Create Holes'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Edit Holes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: holesCollection.orderBy('hole').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();

                  final holes = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: holes.length,
                    itemBuilder: (context, index) {
                      final hole = holes[index];
                      final holeNumber = hole['hole'] as int;
                      final parController = TextEditingController(
                        text: hole['par'].toString(),
                      );
                      final handicapController = TextEditingController(
                        text: hole['handicap'].toString(),
                      );

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Text(
                                'Hole $holeNumber',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: parController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Par',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: handicapController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Stroke Index',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.save),
                                onPressed: () {
                                  final par =
                                      int.tryParse(parController.text) ?? 4;
                                  final handicap =
                                      int.tryParse(handicapController.text) ??
                                      holeNumber;
                                  _updateHole(holeNumber, par, handicap);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PlayerSetupScreen()),
              ),
              child: const Text('Go to Player Setup'),
            ),
          ],
        ),
      ),
    );
  }
}
