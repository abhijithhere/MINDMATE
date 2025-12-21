import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; 
import 'login_screen.dart';
import 'chat_screen.dart'; // Import Chat Screen
import 'voice_mode_screen.dart';
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

    setState(() {
      userName = userId;
    });

    final timelineUrl = Uri.parse('http://10.0.2.2:8000/memories?user_id=$userId');
    
    try {
      final response = await http.get(timelineUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> allItems = data['timeline'];
        
        final now = DateTime.now();
        final String todayStr = DateFormat('yyyy-MM-dd').format(now);
        
        setState(() {
          todayEvents = allItems.where((item) {
            if (item['type'] != 'event') return false;
            return item['start_time'].toString().startsWith(todayStr);
          }).toList();
        });

        if (allItems.isNotEmpty) {
           var lastEvent = allItems.firstWhere(
             (i) => i['type'] == 'event', 
             orElse: () => {'category': 'Sleep'}
           );
           await _fetchAIPrediction(lastEvent['category']);
        }
      }
    } catch (e) {
      print("Error loading dashboard: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchAIPrediction(String prevActivity) async {
    final predictUrl = Uri.parse(
      'http://10.0.2.2:8000/predict?previous_activity=$prevActivity&current_location=Home&current_fatigue=Low'
    );

    try {
      final response = await http.post(predictUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['predictions'] != null && data['predictions'].isNotEmpty) {
          setState(() {
            aiPrediction = data['predictions'][0];
          });
        }
      }
    } catch (e) {
      print("Prediction Error: $e");
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundDark,
      body: SafeArea(
        child: isLoading 
          ? const Center(child: CircularProgressIndicator(color: kPrimaryTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Welcome Back,", style: TextStyle(color: kTextGrey, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(userName, style: const TextStyle(color: kTextWhite, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'logout') _logout();
                        },
                        color: kCardDark,
                        child: const CircleAvatar(
                          backgroundColor: kCardDark,
                          radius: 24,
                          child: Icon(Icons.person, color: kPrimaryTeal, size: 30),
                        ),
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: Colors.redAccent),
                                SizedBox(width: 10),
                                Text("Logout", style: TextStyle(color: Colors.redAccent)),
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- AI PREDICTION CARD ---
                  _buildAIPredictionCard(),
                  
                  const SizedBox(height: 24),

                  // --- 🆕 ACTION BUTTONS ROW (Chat, Voice, Log) ---
                  const Text("Quick Actions", style: TextStyle(color: kTextWhite, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          label: "Voice Mode", 
                          icon: Icons.mic_none_outlined, 
                          color: Colors.purpleAccent,
                          // ✅ CHANGE THIS LINE:
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VoiceModeScreen())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionCard(
                          label: "Voice Mode", 
                          icon: Icons.mic_none_outlined, 
                          color: Colors.purpleAccent,
                          // For now, Voice also opens ChatScreen, but we could separate it later
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionCard(
                          label: "Log Event", 
                          icon: Icons.edit_note, 
                          color: Colors.orangeAccent,
                          onTap: () {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text("Quick Log feature coming soon!"))
                             );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // --- STATS ROW (Kept for Dashboard Info) ---
                  Row(
                    children: [
                      Expanded(child: _buildStatCard("Pending", "${todayEvents.length}", Icons.assignment_outlined, kTextGrey)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard("Focus", "4.5h", Icons.timer, kTextGrey)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard("Energy", "High", Icons.bolt, kTextGrey)),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // --- TODAY'S SCHEDULE ---
                  const Text("Today's Schedule", style: TextStyle(color: kTextWhite, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  
                  todayEvents.isEmpty 
                    ? _buildEmptyState()
                    : ListView.builder(
                        shrinkWrap: true, 
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: todayEvents.length,
                        itemBuilder: (context, index) => _buildScheduleItem(todayEvents[index]),
                      ),
                ],
              ),
            ),
      ),
    );
  }

  // --- 🆕 NEW ACTION CARD WIDGET ---
  Widget _buildActionCard({
    required String label, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100, // Fixed height for square look
        decoration: BoxDecoration(
          color: kCardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label, 
              style: const TextStyle(
                color: kTextWhite, 
                fontWeight: FontWeight.bold, 
                fontSize: 14
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIPredictionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryTeal.withOpacity(0.8), kAccentGreen.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: kPrimaryTeal.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.psychology, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text("MindMate Suggests", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            aiPrediction != null 
              ? "Based on your habits, you usually '${aiPrediction!['activity']}' now."
              : "No data found for $userName.",
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
           Text(
            aiPrediction != null 
              ? "${(aiPrediction!['probability'] * 100).toStringAsFixed(0)}% Confidence"
              : "Interact with the app to train your brain.",
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Simplified Stat Card (Non-clickable)
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: kCardDark.withOpacity(0.5), // Slightly darker to differentiate
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: kTextWhite, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: kTextGrey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(dynamic item) {
    DateTime start = DateTime.parse(item['start_time']);
    String timeStr = DateFormat('h:mm a').format(start);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: kPrimaryTeal, width: 4)),
      ),
      child: Row(
        children: [
          Text(timeStr, style: const TextStyle(color: kTextGrey, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'], style: const TextStyle(color: kTextWhite, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(item['category'] ?? "General", style: TextStyle(color: kTextGrey.withOpacity(0.7), fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: kTextGrey),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Text("No events today for $userName.", style: TextStyle(color: kTextGrey.withOpacity(0.5))),
      ),
    );
  }
}