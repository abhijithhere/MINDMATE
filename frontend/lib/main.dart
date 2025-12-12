import 'package:flutter/material.dart';
import 'chat_pages.dart';   
import 'chat_history.dart'; 

void main() {
  runApp(const ChatpodiaApp());
}

// --- Constants (Refined for "Clean/No-Glow" Look) ---
const Color kBackgroundColor = Color(0xFF0B0F14); // Deep matte black
const Color kPrimaryTeal = Color(0xFF19D3B1);     // Muted Teal
const Color kAccentGreen = Color(0xFF3DF5C9);     // Soft Aqua
const Color kCardGlass = Color(0xFF1C2229);       // Slightly lighter for cards
const Color kTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFF94A3B8);

class ChatpodiaApp extends StatelessWidget {
  const ChatpodiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kBackgroundColor,
        primaryColor: kPrimaryTeal,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: kTextColor),
        ),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: kPrimaryTeal,
          secondary: kAccentGreen,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Page List
    final List<Widget> pages = [
      const HomePage(),          // Index 0: New Minimal Dashboard
      const ChatHistoryPage(),   // Index 1: History
      const Center(child: Text("Notes")), // Index 2 (Placeholder)
      const Center(child: Text("Profile")), // Index 3 (Placeholder)
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Background: Subtle top-left gradient (No heavy neon)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryTeal.withOpacity(0.15), // Very subtle
                boxShadow: [
                  BoxShadow(
                    blurRadius: 100,
                    color: kPrimaryTeal.withOpacity(0.15), // Color is required for the shadow to be seen
                  ),
                ],
              ),
            ),
          ),
          pages[_currentIndex], 
        ],
      ),
      
      // Voice Button: ONLY on Home Page
      floatingActionButton: _currentIndex == 0 
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const VoiceInteractionPage()),
                );
              },
              backgroundColor: kPrimaryTeal,
              elevation: 4, // Subtle shadow, no neon glow
              child: const Icon(Icons.mic, color: Colors.black),
            )
          : null,
      
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF13181E).withOpacity(0.9), // Solid matte dark
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.home_filled,
                    color: _currentIndex == 0 ? kAccentGreen : kSecondaryTextColor),
                onPressed: () => setState(() => _currentIndex = 0),
              ),
              IconButton(
                icon: Icon(Icons.chat_bubble_outline,
                    color: _currentIndex == 1 ? kAccentGreen : kSecondaryTextColor),
                onPressed: () => setState(() => _currentIndex = 1),
              ),
              const SizedBox(width: 48), 
              IconButton(
                icon: Icon(Icons.note_alt_outlined, // Changed to Notes icon
                    color: _currentIndex == 2 ? kAccentGreen : kSecondaryTextColor),
                onPressed: () => setState(() => _currentIndex = 2),
              ),
              IconButton(
                icon: Icon(Icons.person_outline,
                    color: _currentIndex == 3 ? kAccentGreen : kSecondaryTextColor),
                onPressed: () => setState(() => _currentIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== NEW MINIMAL HOME PAGE ====================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // 1. Top Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: kCardGlass,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=32'), // Placeholder
              ),
              const Icon(Icons.settings_outlined, color: Colors.white),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 2. Greeting
          const Text(
            "Hi Abhijith,",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: kSecondaryTextColor),
          ),
          const SizedBox(height: 8),
          const Text(
            "How can I assist you today?",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kTextColor),
          ),

          const SizedBox(height: 40),

          // 3. Central AI Orb (Clean, subtle gradient, no neon bloom)
          Center(
            child: Container(
              height: 180,
              width: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kAccentGreen.withOpacity(0.8),
                    kPrimaryTeal.withOpacity(0.6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryTeal.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 0,
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // 4. Quick Action Chips (Updated List)
          // Removed: OCR Scan, Mood Check
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildGlassChip(Icons.edit_note, "Smart Notes"),
                const SizedBox(width: 12),
                _buildGlassChip(Icons.mic_none, "Voice Notes"),
                const SizedBox(width: 12),
                _buildGlassChip(Icons.search, "Smart Search"),
                const SizedBox(width: 12),
                _buildGlassChip(Icons.calendar_today, "Daily Planner"),
                const SizedBox(width: 12),
                _buildGlassChip(Icons.notifications_none, "Reminders"),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // 5. Today's Overview (Carousel)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's Overview",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const Icon(Icons.arrow_forward, size: 16, color: kSecondaryTextColor),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildOverviewCard("Important", "Project Submission", "Due 5:00 PM", Icons.warning_amber),
                const SizedBox(width: 16),
                _buildOverviewCard("Meeting", "Team Sync", "10:00 AM", Icons.videocam_outlined),
                const SizedBox(width: 16),
                _buildOverviewCard("Habit", "Drink Water", "6/8 Cups", Icons.local_drink_outlined),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // 6. Suggested For You (Rich Cards)
          const Text("Suggested For You",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _buildRichCard("Productivity Tip", "Focus on one task at a time for better flow.", Icons.lightbulb_outline),
          const SizedBox(height: 12),
          _buildRichCard("Health Insight", "Your sleep quality improved by 10% this week.", Icons.favorite_border),
          
          const SizedBox(height: 80), // Bottom padding
        ],
      ),
    );
  }

  // Helper: Glassmorphism Chip
  Widget _buildGlassChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05), // Low opacity for glass feel
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kAccentGreen, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: kTextColor, fontSize: 13)),
        ],
      ),
    );
  }

  // Helper: Overview Card (Vertical)
  Widget _buildOverviewCard(String type, String title, String subtitle, IconData icon) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: kPrimaryTeal, size: 20),
          ),
          const SizedBox(height: 16),
          Text(type, style: const TextStyle(color: kSecondaryTextColor, fontSize: 12)),
          const SizedBox(height: 4),
          Text(title, 
              style: const TextStyle(color: kTextColor, fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: kSecondaryTextColor, fontSize: 12)),
        ],
      ),
    );
  }

  // Helper: Rich Card (Horizontal)
  Widget _buildRichCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kCardGlass, kCardGlass.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kAccentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: kAccentGreen, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: kSecondaryTextColor, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}