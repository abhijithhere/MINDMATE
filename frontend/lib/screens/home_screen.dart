import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';
import 'login_screen.dart';

// 🟢 CORRECT IMPORTS (Pointing to features folder)
import '../features/chat/screens/chat_screen.dart';
import '../features/voice_mode_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "Guest"; 
  List<dynamic> todayEvents = [];
  Map<String, dynamic>? aiPrediction;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
  }

  Future<void> _loadUserAndData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('user_id');

    if (userId == null) {
      _logout();
      return;
    }

    setState(() => userName = userId!);

    final timelineUrl = Uri.parse('${ApiConstants.baseUrl}/memories?user_id=$userId');
    
    try {
      final response = await http.get(timelineUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          todayEvents = (data['timeline'] as List).take(3).toList();
        });
      }
    } catch (e) {
      print("Error loading dashboard: $e");
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Welcome Back,\n$userName", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout)
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // Quick Actions
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard("Voice Mode", Icons.mic, Colors.purple, 
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceModeScreen()))),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildActionCard("Chat", Icons.chat, Colors.blue, 
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  const Text("Today's Schedule", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  
                  ...todayEvents.map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: AppTheme.kCardDark, borderRadius: BorderRadius.circular(15)),
                    child: Text(e['title'] ?? "Event", style: const TextStyle(color: Colors.white)),
                  ))
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildActionCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.kCardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}