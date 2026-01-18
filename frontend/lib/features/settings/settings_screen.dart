import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../auth/screens/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          _buildSectionHeader("Account"),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.white),
            title: const Text("Profile", style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
          ListTile(
            leading: const Icon(Icons.mic_none, color: Colors.white),
            title: const Text("Voice Settings", style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
          
          _buildSectionHeader("System"),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined, color: Colors.white),
            title: const Text("Notifications", style: TextStyle(color: Colors.white)),
            value: true,
            onChanged: (val) {},
            activeColor: AppTheme.kPrimaryTeal,
          ),
          
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Log Out", style: TextStyle(color: Colors.redAccent)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: const TextStyle(color: AppTheme.kPrimaryTeal, fontWeight: FontWeight.bold)),
    );
  }
}