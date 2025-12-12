import 'package:flutter/material.dart';
import 'chat_pages.dart'; // Import to navigate to the actual chat on click

// --- Constants (Matching your design system) ---
const Color kBackgroundColor = Color(0xFF0F172A);
const Color kPrimaryGreen = Color(0xFF10B981);
const Color kAccentTeal = Color(0xFF2DD4BF);
const Color kCardColor = Color(0xFF1E293B);
const Color kSecondaryTextColor = Color(0xFF94A3B8);
const Color kTextColor = Colors.white;

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  // Mock Data for Date Filters
  final List<String> _dates = ["All", "Today", "Yesterday", "Dec 10", "Dec 08", "Nov 24"];
  int _selectedDateIndex = 0;

  // Mock Data for Chat History
  final List<Map<String, dynamic>> _chatHistory = [
    {
      "title": "Music Recommendations",
      "preview": "Podia: Here is a Lofi playlist for studying...",
      "time": "10:30 AM",
      "icon": Icons.music_note,
      "color": Colors.purpleAccent,
    },
    {
      "title": "Python Code Help",
      "preview": "You: How do I fix this indentation error?",
      "time": "09:15 AM",
      "icon": Icons.code,
      "color": Colors.blueAccent,
    },
    {
      "title": "Yoga Poses",
      "preview": "Podia: Try the Cobra pose for back relief.",
      "time": "Yesterday",
      "icon": Icons.self_improvement,
      "color": kPrimaryGreen,
    },
    {
      "title": "Travel Itinerary",
      "preview": "You: Plan a 3-day trip to Kyoto.",
      "time": "Dec 10",
      "icon": Icons.flight_takeoff,
      "color": Colors.orangeAccent,
    },
    {
      "title": "Creative Story",
      "preview": "Podia: Once upon a time in a neon city...",
      "time": "Dec 08",
      "icon": Icons.auto_stories,
      "color": Colors.pinkAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // --- Header ---
              const Text(
                "History",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 20),

              // --- Search Bar ---
              Container(
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: TextField(
                  style: const TextStyle(color: kTextColor),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, color: kSecondaryTextColor),
                    hintText: "Search conversations...",
                    hintStyle: TextStyle(color: kSecondaryTextColor),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // --- Date Selection (Horizontal List) ---
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _dates.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedDateIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDateIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? kPrimaryGreen : kCardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected 
                            ? null 
                            : Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Center(
                          child: Text(
                            _dates[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : kSecondaryTextColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // --- Chat List ---
              Expanded(
                child: ListView.builder(
                  itemCount: _chatHistory.length,
                  itemBuilder: (context, index) {
                    final chat = _chatHistory[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: InkWell(
                        onTap: () {
                          // Navigate to the actual Chat Interface when clicked
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChatPage()),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kCardColor.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Row(
                            children: [
                              // Icon Avatar
                              Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: chat['color'].withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  chat['icon'],
                                  color: chat['color'],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Text Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          chat['title'],
                                          style: const TextStyle(
                                            color: kTextColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          chat['time'],
                                          style: TextStyle(
                                            color: kSecondaryTextColor.withOpacity(0.7),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      chat['preview'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: kSecondaryTextColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}