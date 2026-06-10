// lib/main_layout.dart
import 'package:flutter/material.dart';
import 'package:mindmate/core/theme/app_theme.dart';

import 'screens/home_screen.dart';                          // ← HOME (tab 0)
import 'features/chat/screens/home_orb_screen.dart';        // ← Voice hub (tab 1)
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/memory/screens/memory_screen.dart';
import 'screens/planner_screen.dart';
import 'screens/overview_screen.dart';
import 'screens/reminders_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/chat/screens/chat_history_screen.dart';
import 'features/chat/screens/todo_screen.dart';

class MainLayout extends StatefulWidget {
  final String userId;
  const MainLayout({super.key, required this.userId});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeScreen(),         // 0: Home  ← default
      HomeOrbScreen(userId: widget.userId),        // 1: Voice & AI Hub
      DashboardScreen(userId: widget.userId),      // 2: Daily Stats
      MemoryScreen(userId: widget.userId),         // 3: Memory Core
      PlannerScreen(userId: widget.userId),        // 4: AI Planner
      OverviewScreen(userId: widget.userId),       // 5: Life Overview
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      appBar: AppBar(
        title: const Text(
          "MINDMATE",
          style: TextStyle(
              letterSpacing: 4, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        backgroundColor: AppTheme.kBackgroundDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.kPrimaryTeal),
      ),
      drawer: _buildDrawer(),
      body: IndexedStack(index: _selectedIndex, children: _pages),

      // Bottom nav for the 3 most-used screens
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex.clamp(0, 2),
        onTap: (i) => setState(() => _selectedIndex = i),
        backgroundColor: AppTheme.kCardDark,
        selectedItemColor: AppTheme.kPrimaryTeal,
        unselectedItemColor: Colors.white30,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.mic),            label: 'Voice'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.kBackgroundDark,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _tile(Icons.home_outlined,          'Home',            0),
                _tile(Icons.mic,                    'Voice Hub',       1),
                _tile(Icons.dashboard_customize,    'Dashboard',       2),
                _tile(Icons.memory,                 'Memory Core',     3),
                _tile(Icons.auto_awesome,           'AI Planner',      4),
                _tile(Icons.insights,               'Life Overview',   5),
                const Divider(color: Colors.white10, indent: 20, endIndent: 20, height: 30),
                _pushTile(Icons.chat_bubble_outline, 'Chat',
                    ChatScreen(userId: widget.userId)),
                _pushTile(Icons.history,             'Chat History',
                    ChatHistoryScreen(userId: widget.userId)),
                _pushTile(Icons.checklist,           'To-Do List',
                    TodoScreen(userId: widget.userId)),
                _pushTile(Icons.alarm_on,            'Reminders',
                    RemindersScreen(userId: widget.userId)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'MindMate v1.0.2 • Proactive AI',
              style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5))),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:  AppTheme.kPrimaryTeal.withOpacity(0.1),
                shape:  BoxShape.circle,
              ),
              child: const Icon(Icons.psychology, size: 40,
                  color: AppTheme.kPrimaryTeal),
            ),
            const SizedBox(height: 12),
            Text(
              widget.userId,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w300,
                  overflow: TextOverflow.ellipsis),
            ),
            const Text('PROACTIVE MODE ACTIVE',
                style: TextStyle(
                    color: AppTheme.kPrimaryTeal, fontSize: 9,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Switches IndexedStack index
  Widget _tile(IconData icon, String label, int index) {
    final selected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon,
          color: selected ? AppTheme.kPrimaryTeal : Colors.white54),
      title: Text(label,
          style: TextStyle(
              color: selected ? Colors.white : Colors.white70)),
      selected:           selected,
      selectedTileColor:  AppTheme.kPrimaryTeal.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Navigator.pop(context);
        setState(() => _selectedIndex = index);
      },
    );
  }

  // Pushes a new screen (doesn't change IndexedStack)
  Widget _pushTile(IconData icon, String label, Widget screen) {
    return ListTile(
      leading: Icon(icon, color: Colors.white54),
      title:   Text(label, style: const TextStyle(color: Colors.white70)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => screen));
      },
    );
  }
}