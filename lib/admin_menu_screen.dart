import 'package:flutter/material.dart';
import 'course_setup_screen.dart';
import 'player_setup_screen.dart';
import 'score_input_screen.dart';
import 'leaderboard_screen.dart';
import 'stats_screen.dart';

class AdminMenuScreen extends StatelessWidget {
  const AdminMenuScreen({super.key});

  final String courseId = "UCO2025"; // Use your course document ID

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Menu')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CourseSetupScreen()),
              ),
              child: const Text('1. Set Course Up'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlayerSetupScreen()),
              ),
              child: const Text('2. Set Players Up'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ScoreInputScreen(round: 1, courseId: courseId),
                ),
              ),
              child: const Text('3. Add Round 1 Scores'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ScoreInputScreen(round: 2, courseId: courseId),
                ),
              ),
              child: const Text('4. Add Round 2 Scores'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ScoreInputScreen(round: 3, courseId: courseId),
                ),
              ),
              child: const Text('5. Add Round 3 Scores'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LeaderboardScreen(courseId: courseId),
                ),
              ),
              child: const Text('6. View Leaderboard'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatsScreen(courseId: courseId),
                ),
              ),
              child: const Text('7. View Stats'),
            ),
          ],
        ),
      ),
    );
  }
}
