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
  final TextEditingController _parController = TextEditingController();
  final TextEditingController _handicapController = TextEditingController();
  final TextEditingController _courseNameController = TextEditingController(
    text: 'China Fleet Country Club',
  );
  final TextEditingController _courseRatingController = TextEditingController(
    text: '70.9',
  );
  final TextEditingController _slopeRatingController = TextEditingController(
    text: '127',
  );
  int _holeNumber = 1;

  Future<void> _saveCourseSettings() async {
    try {
      await _firestore.collection('course_settings').doc('settings').set({
        'name': _courseNameController.text.trim(),
        'courseRating':
            double.tryParse(_courseRatingController.text.trim()) ?? 70.9,
        'slopeRating': int.tryParse(_slopeRatingController.text.trim()) ?? 127,
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Course settings saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving course settings: $e')),
        );
      }
    }
  }

  Future<void> _addHole() async {
    final int? par = int.tryParse(_parController.text.trim());
    final int? holeHandicap = int.tryParse(_handicapController.text.trim());
    if (par == null ||
        par < 3 ||
        par > 5 ||
        holeHandicap == null ||
        holeHandicap < 1 ||
        holeHandicap > 18) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter valid par (3-5) and handicap (1-18)'),
          ),
        );
      }
      return;
    }

    try {
      await _firestore.collection('course').doc('hole_$_holeNumber').set({
        'hole': _holeNumber,
        'par': par,
        'handicap': holeHandicap,
        'groupCode': (await _firestore
            .collection('settings')
            .doc('group')
            .get())['code'],
      });

      _parController.clear();
      _handicapController.clear();
      setState(() {
        _holeNumber = _holeNumber < 18 ? _holeNumber + 1 : 1;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hole $_holeNumber added')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding hole: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Up Course')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height - kToolbarHeight - 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Course Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _courseNameController,
                  decoration: const InputDecoration(
                    labelText: 'Course Name (e.g., China Fleet Country Club)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _courseRatingController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Course Rating (e.g., 70.9)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _slopeRatingController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Slope Rating (e.g., 127)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  onPressed: _saveCourseSettings,
                  child: const Text(
                    'Save Course Settings',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hole Setup',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text('Hole $_holeNumber', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                TextField(
                  controller: _parController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Par (3-5)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _handicapController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Hole Handicap (1-18)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  onPressed: _addHole,
                  child: const Text('Add Hole', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PlayerSetupScreen(),
                    ),
                  ),
                  child: const Text(
                    'Go to Player Setup',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200, // Fixed height to avoid unbounded constraints
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('course').snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return ListView(
                        children: snapshot.data!.docs.map((doc) {
                          return ListTile(
                            title: Text('Hole ${doc['hole']}'),
                            subtitle: Text(
                              'Par: ${doc['par']}, Handicap: ${doc['handicap']}',
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
