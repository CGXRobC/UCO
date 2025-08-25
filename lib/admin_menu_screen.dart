import 'package:flutter/material.dart';
import 'course_setup_screen.dart';
import 'player_setup_screen.dart';
import 'score_input_screen.dart';
import 'leaderboard_screen.dart';
import 'stats_screen.dart';
import 'login_screen.dart'; // ✅ Import login screen

class AdminMenuScreen extends StatelessWidget {
  final String courseId; // Required
  const AdminMenuScreen({super.key, required this.courseId});

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(courseId: courseId)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. Set Course Up
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseSetupScreen(courseId: courseId),
                ),
              ),
              child: const Text(
                '1. Set Course Up',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Set Players Up
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerSetupScreen(courseId: courseId),
                ),
              ),
              child: const Text(
                '2. Set Players Up',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Add Round 1 Scores
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScoreInputScreen(
                    courseId: courseId,
                    round: 1,
                    playerName: '', // Admin selects player inside the screen
                  ),
                ),
              ),
              child: const Text(
                '3. Add Round 1 Scores',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Add Round 2 Scores
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScoreInputScreen(
                    courseId: courseId,
                    round: 2,
                    playerName: '',
                  ),
                ),
              ),
              child: const Text(
                '4. Add Round 2 Scores',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),

            // 5. Add Round 3 Scores
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScoreInputScreen(
                    courseId: courseId,
                    round: 3,
                    playerName: '',
                  ),
                ),
              ),
              child: const Text(
                '5. Add Round 3 Scores',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),

            // 6. View Leaderboard
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LeaderboardScreen(courseId: courseId),
                ),
              ),
              child: const Text(
                '6. View Leaderboard',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),

            // 7. View Stats
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StatsScreen(courseId: courseId),
                ),
              ),
              child: const Text(
                '7. View Stats',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const Spacer(),

            // ✅ Logout button at bottom
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                "Logout",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              onPressed: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}
