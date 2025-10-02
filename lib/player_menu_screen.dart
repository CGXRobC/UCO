// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'score_input_screen.dart';
import 'leaderboard_screen.dart';
import 'stats_screen.dart';
import 'login_screen.dart';

class PlayerMenuScreen extends StatelessWidget {
  final String playerName;
  final String playerId;
  final String courseId;

  const PlayerMenuScreen({
    super.key,
    required this.playerName,
    required this.playerId,
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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'web/Assets/images/U_C_O_Background.png',
            ), // Path to your image
            fit: BoxFit.cover, // Makes the image cover the entire background
            opacity: 0.7, // Adjusts opacity for readability
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Round 1
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: Colors.white.withOpacity(
                        0.8,
                      ), // Semi-transparent button for contrast
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScoreInputScreen(
                          round: 1,
                          playerId: playerId,
                          playerName: playerName,
                          courseId: courseId,
                        ),
                      ),
                    ),
                    child: const Text(
                      '1. Add Round 1 Scores',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Round 2
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: Colors.white.withOpacity(0.8),
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
                ),
              ),
              const SizedBox(height: 16),

              // Round 3
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: Colors.white.withOpacity(0.8),
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
                ),
              ),
              const SizedBox(height: 16),

              // Leaderboard
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: Colors.white.withOpacity(0.8),
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
                ),
              ),
              const SizedBox(height: 16),

              // Stats
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: Colors.white.withOpacity(0.8),
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
                ),
              ),
              const Spacer(),

              // Logout button
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: ElevatedButton.icon(
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
