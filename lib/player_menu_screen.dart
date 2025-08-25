import 'package:flutter/material.dart';
import 'score_input_screen.dart';
import 'leaderboard_screen.dart';
import 'stats_screen.dart';
import 'login_screen.dart'; // Needed for logout

class PlayerMenuScreen extends StatelessWidget {
  final String playerName;
  final String playerId; // <-- NEW: store player document ID
  final String courseId;

  const PlayerMenuScreen({
    super.key,
    required this.playerName,
    required this.playerId, // required
    required this.courseId,
  });

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
        title: Text('Player Menu - $playerName'),
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
            // Round 1
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
                    round: 1,
                    playerId: playerId, // <-- pass playerId
                    playerName: playerName, // optional
                    courseId: courseId,
                  ),
                ),
              ),
              child: const Text(
                '1. Add Round 1 Scores',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Round 2
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
                    round: 2,
                    playerId: playerId,
                    playerName: playerName,
                    courseId: courseId,
                  ),
                ),
              ),
              child: const Text(
                '2. Add Round 2 Scores',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Round 3
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
                    round: 3,
                    playerId: playerId,
                    playerName: playerName,
                    courseId: courseId,
                  ),
                ),
              ),
              child: const Text(
                '3. Add Round 3 Scores',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Leaderboard
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
                '4. View Leaderboard',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Stats
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
                '5. View Stats',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const Spacer(),

            // Logout button at bottom
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
