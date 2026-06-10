// lib/features/calendar/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/api_service.dart';
import '../widgets/event_tile.dart';

class CalendarScreen extends StatelessWidget {
  final String userId;
  final ApiService _apiService = ApiService();

  CalendarScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      appBar: AppBar(title: const Text("AI FORECAST")),
      body: FutureBuilder<List<dynamic>>(
        future: _apiService.getMemories(userId), // Assuming this fetches predicted tasks
        builder: (context, snapshot) {
          final events = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: events.isEmpty ? 1 : events.length,
            itemBuilder: (context, index) {
              if (events.isEmpty) return const Center(child: Text("AI is calculating your next moves..."));
              final e = events[index];
              return EventTile(
                time: e['time'] ?? "Upcoming",
                title: e['title'] ?? "Predicted Task",
                subtitle: e['description'] ?? "Extracted from history",
                category: "AI Suggestion",
                color: AppTheme.kPrimaryTeal,
              );
            },
          );
        },
      ),
    );
  }
}