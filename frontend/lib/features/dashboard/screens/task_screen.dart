// lib/features/dashboard/screens/task_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      appBar: AppBar(title: const Text("AGENTIC TASKS")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildTask("Review AI Architecture", "Extracted from Gmail", false),
          _buildTask("Finalize Voice Model", "Extracted from Voice Chat", true),
        ],
      ),
    );
  }

  Widget _buildTask(String title, String source, bool done) {
    return CheckboxListTile(
      value: done,
      onChanged: (val) {},
      title: Text(title, style: TextStyle(decoration: done ? TextDecoration.lineThrough : null)),
      subtitle: Text(source, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      activeColor: AppTheme.kPrimaryTeal,
      checkColor: Colors.black,
    );
  }
}