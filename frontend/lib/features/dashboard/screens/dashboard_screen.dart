// lib/features/dashboard/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/api_service.dart';
import '../../../shared/widgets/glass_container.dart';

class DashboardScreen extends StatelessWidget {
  final String userId;
  final ApiService _apiService = ApiService();

  DashboardScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _apiService.getDashboardData(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ?? {};
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 50),
              _buildGauge(data['productivity_score'] ?? 0),
              const SizedBox(height: 30),
              const Text("YESTERDAY'S INSIGHTS", style: TextStyle(color: AppTheme.kPrimaryTeal, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(data['summary'] ?? "Syncing your habits... Check back in a moment."),
                ),
              ),
              const SizedBox(height: 20),
              _buildTile("Emails Synced", "${data['email_count'] ?? 0}", Icons.email_outlined),
              _buildTile("Voice Memories", "${data['memory_count'] ?? 0}", Icons.mic_none),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGauge(int score) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(height: 140, width: 140, child: CircularProgressIndicator(value: score / 100, strokeWidth: 10, color: AppTheme.kPrimaryTeal, backgroundColor: Colors.white10)),
          Text("$score%", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTile(String label, String val, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.kPrimaryTeal),
      title: Text(label),
      trailing: Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}