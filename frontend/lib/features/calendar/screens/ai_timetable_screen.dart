import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/event_tile.dart';

class AiTimetableScreen extends StatelessWidget {
  const AiTimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      appBar: AppBar(
        title: const Text("AI Daily Plan"),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh, size: 16, color: AppTheme.kAccentGreen),
            label: const Text("Regenerate", style: TextStyle(color: AppTheme.kAccentGreen)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            // Timeline Item 1
            EventTile(
              time: "08:00",
              title: "Morning Briefing",
              subtitle: "Review Q3 metrics & inbox zero.",
              category: "Briefing",
              color: AppTheme.kPrimaryTeal,
              isFirst: true,
            ),
            // Timeline Item 2 (Suggestion)
            EventTile(
              time: "08:30",
              title: "Vitamin D Optimization",
              subtitle: "Take a 10m sunlight walk.",
              category: "Suggestion",
              color: AppTheme.kAccentGreen,
              isSuggestion: true,
            ),
            // Timeline Item 3
            EventTile(
              time: "09:00",
              title: "Deep Work (Project Alpha)",
              subtitle: "Core implementation of auth module.",
              category: "Focus",
              color: Colors.white,
            ),
            // Timeline Item 4
            EventTile(
              time: "11:30",
              title: "Team Sync",
              subtitle: "Weekly standup with design team.",
              category: "Meeting",
              color: Colors.grey,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}