// lib/features/settings/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  // Always use the synced Gmail ID for your project presentation
  final String userId = "meanonymus87@gmail.com";

  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      appBar: AppBar(title: const Text("USER IDENTITY")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.kPrimaryTeal,
              child: Icon(Icons.person, size: 50, color: Colors.black),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(userId, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const Center(
            child: Text("B.Tech CSE Final Year", style: TextStyle(color: Colors.white54, fontSize: 12)),
          ),
          const SizedBox(height: 40),
          
          const Text("SECURITY & AI STATUS", style: TextStyle(color: AppTheme.kPrimaryTeal, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 10),
          _buildInfoTile("Voice Enrollment", "Verified (classifier.ckpt)", Icons.verified_user),
          _buildInfoTile("Agentic RAG", "Active & Syncing", Icons.auto_awesome),
          _buildInfoTile("Sync Frequency", "Every 5 Minutes", Icons.sync),
          
          const SizedBox(height: 30),
          const Text("VOICE BIOMETRIC LOGS", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 10),
          _buildLogTile("Success", "Authenticated via Voice Login", "10:30 AM"),
          _buildLogTile("Heartbeat", "Background Identity Verified", "12:45 PM"),

          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.8)),
            child: const Text("LOGOUT"),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppTheme.kPrimaryTeal, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.white70)),
      trailing: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildLogTile(String status, String action, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.kCardDark, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.lock_open, color: AppTheme.kAccentGreen, size: 16),
          const SizedBox(width: 15),
          Expanded(child: Text(action, style: const TextStyle(fontSize: 12))),
          Text(time, style: const TextStyle(color: Colors.white24, fontSize: 10)),
        ],
      ),
    );
  }
}