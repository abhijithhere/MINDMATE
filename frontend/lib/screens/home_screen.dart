import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Add intl to pubspec.yaml if missing
import '../main.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State Variables
  String userName = "Abhijit"; // Placeholder until profile fetch
  List<dynamic> todayEvents = [];
  Map<String, dynamic>? aiPrediction;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    // 1. Fetch Full Timeline to filter for TODAY
    final timelineUrl = Uri.parse('http://10.0.2.2:8000/memories?user_id=test_user');
    
    try {
      final response = await http.get(timelineUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> allItems = data['timeline'];
        
        // Filter: Get only EVENTS that happen TODAY
        final now = DateTime.now();
        final String todayStr = DateFormat('yyyy-MM-dd').format(now);
        
        setState(() {
          todayEvents = allItems.where((item) {
            if (item['type'] != 'event') return false;
            // Check if date matches today
            return item['start_time'].toString().startsWith(todayStr);
          }).toList();
        });

        // 2. Get AI Prediction based on the LAST event
        if (allItems.isNotEmpty) {
           // Find the most recent completed event to use as context
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
    // We send current context to the AI Brain
    final predictUrl = Uri.parse(
      'http://10.0.2.2:8000/predict?previous_activity=$prevActivity&current_location=Home&current_fatigue=Low'
    );

    try {
      final response = await http.post(predictUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['predictions'] != null && data['predictions'].isNotEmpty) {
          setState(() {
            aiPrediction = data['predictions'][0]; // Take the top suggestion
          });
        }
      }
    } catch (e) {
      print("Prediction Error: $e");
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
                          Text("Hello, $userName", style: const TextStyle(color: kTextGrey, fontSize: 16)),
                          const SizedBox(height: 4),
                          const Text("Your Day Overview", style: TextStyle(color: kTextWhite, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const CircleAvatar(
                        backgroundColor: kCardDark,
                        child: Icon(Icons.person, color: kPrimaryTeal),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- AI BRAIN CARD ---
                  _buildAIPredictionCard(),
                  
                  const SizedBox(height: 24),

                  // --- STATS ROW ---
                  Row(
                    children: [
                      Expanded(child: _buildStatCard("Pending", "${todayEvents.length}", Icons.assignment_outlined, Colors.orange)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard("Focus", "4.5h", Icons.timer, Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard("Energy", "High", Icons.bolt, Colors.yellow)),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // --- TODAY'S SCHEDULE ---
                  const Text("Today's Schedule", style: TextStyle(color: kTextWhite, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  
                  todayEvents.isEmpty 
                    ? _buildEmptyState()
                    : ListView.builder(
                        shrinkWrap: true, // Important for usage inside ScrollView
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

  // --- WIDGETS ---

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
              : "Analyzing your patterns...",
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            aiPrediction != null 
              ? "${(aiPrediction!['probability'] * 100).toStringAsFixed(0)}% Confidence"
              : "Gathering data from timeline...",
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: kTextWhite, fontSize: 18, fontWeight: FontWeight.bold)),
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
        child: Text("No events scheduled for today.", style: TextStyle(color: kTextGrey.withOpacity(0.5))),
      ),
    );
  }
}