//frontend\lib\screens\home_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import 'reminders_screen.dart'; 
import '../features/voice_mode_screen.dart'; 
import '../features/chat/screens/todo_screen.dart'; // 🟢 Added for the new To-Do feature

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "Guest"; 
  String? userId; 
  List<dynamic> upcomingReminders = []; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
  }

  Future<void> _loadUserAndData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id');

    if (userId == null) {
      _logout();
      return;
    }

    setState(() => userName = userId!.split('@')[0]); 

    // 🟢 Fetching HIGH PRIORITY Reminders for the dashboard
    final reminderUrl = Uri.parse('${ApiConstants.baseUrl}/reminders/filter?user_id=$userId&priorities=High');
    
    try {
      final response = await http.get(reminderUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          upcomingReminders = (data['reminders'] as List).take(2).toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading reminders: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      body: SafeArea(
        child: isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.kPrimaryTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  
                  const Text("Quick Actions", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2, // Changed to 2 for better UI balance
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _buildActionCard("Voice Mode", Icons.mic, Colors.purple, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => VoiceModeScreen(userId: userId)))),
                      
                      _buildActionCard("AI Chat", Icons.chat, Colors.blue, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(userId: userId!)))),
                      
                      _buildActionCard("High Alerts", Icons.notification_important, Colors.redAccent, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => RemindersScreen(userId: userId!)))),
                      
                      // 🟢 NEW: To-Do List (Low/Medium Priority)
                      _buildActionCard("To-Do List", Icons.checklist, AppTheme.kPrimaryTeal, 
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => TodoScreen(userId: userId!)))),
                    ],
                  ),
                  
                  const SizedBox(height: 35),
                  const Text("Critical Alarms", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  
                  if (upcomingReminders.isEmpty)
                    const Text("No high-priority alerts today", style: TextStyle(color: Colors.grey))
                  else
                    ...upcomingReminders.map((r) => _buildMiniReminder(r)),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Welcome Back,", style: TextStyle(color: Colors.white54, fontSize: 14)),
            Text(userName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white38), 
          onPressed: _logout
        )
      ],
    );
  }

  Widget _buildMiniReminder(Map<String, dynamic> r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.kCardDark, 
        borderRadius: BorderRadius.circular(20),
        border: const Border(left: BorderSide(color: Colors.redAccent, width: 4))
      ),
      child: Row(
        children: [
          const Icon(Icons.access_alarm, color: Colors.redAccent, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['title'] ?? "Reminder", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(r['trigger_time'] ?? "", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white10),
        ],
      ),
    );
  }

  Widget _buildActionCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.kCardDark,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}