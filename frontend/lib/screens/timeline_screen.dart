import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../main.dart'; // Imports your global theme colors

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  List<dynamic> timelineItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMemories();
  }

  Future<void> fetchMemories() async {
    // We fetch data for 'test_user' because that is what generate_dummy_data.py created.
    // In a real app, you would use the logged-in user's ID here.
    final url = Uri.parse('http://10.0.2.2:8000/memories?user_id=test_user');
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          timelineItems = data['timeline'];
          isLoading = false;
        });
      } else {
        print("Error: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Connection Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Timeline"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            // ✅ FIX: This line makes the back button work
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kPrimaryTeal),
              ),
            )
          : timelineItems.isEmpty 
              ? _buildEmptyState() // Show this if list is truly empty
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: timelineItems.length,
                  itemBuilder: (context, index) {
                    final item = timelineItems[index];
                    return _buildGlowingCard(item);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: kTextGrey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text("No memories yet", style: TextStyle(color: kTextGrey, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildGlowingCard(Map<String, dynamic> item) {
    bool isEvent = item['type'] == 'event';
    
    // Define gradient colors based on type
    final List<Color> gradientColors = isEvent
        ? [kPrimaryTeal, kAccentGreen] // Teal-to-Green for Events
        : [const Color(0xFFAB47BC), const Color(0xFF7E57C2)]; // Purple-to-Blue for Memories

    IconData icon = isEvent ? Icons.event_available_rounded : Icons.lightbulb_outline_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: kCardDark,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- GLOWING INDICATOR BAR ---
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: gradientColors,
                    ),
                  ),
                ),
                
                // --- CARD CONTENT ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- ICON ---
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradientColors.map((c) => c.withOpacity(0.2)).toList(),
                            ),
                          ),
                          child: Icon(icon, color: gradientColors[0]),
                        ),
                        const SizedBox(width: 16),
                        
                        // --- TEXT ---
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEvent ? item['title'] : item['content'],
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 16,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  // Category Chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: kBackgroundDark,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      item['category'] ?? "General",
                                      style: TextStyle(
                                        color: gradientColors[0],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Time
                                  Text(
                                    _formatTime(item['start_time']),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      DateTime date = DateTime.parse(isoString);
      String weekday = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][date.weekday - 1];
      String hour = date.hour > 12 ? (date.hour - 12).toString() : (date.hour == 0 ? "12" : date.hour.toString());
      String minute = date.minute.toString().padLeft(2, '0');
      String period = date.hour >= 12 ? "PM" : "AM";
      return "$weekday, $hour:$minute $period";
    } catch (e) {
      return isoString;
    }
  }
}