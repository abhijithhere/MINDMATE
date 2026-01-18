

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/background_service.dart';
import 'screens/home_screen.dart';
import 'screens/timeline_screen.dart';
import 'screens/login_screen.dart';
import 'screens/planner_screen.dart';
import 'core/theme/app_theme.dart';

// 🟢 NEW CORRECT IMPORTS
import 'features/chat/screens/chat_screen.dart'; 
import 'features/voice_mode_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await _requestPermissions();
  await initializeService();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

Future<void> _requestPermissions() async {
  await Permission.microphone.request();
  await Permission.notification.request();
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MindMate',
      theme: AppTheme.darkTheme,
      home: isLoggedIn ? const MainLayout() : const LoginScreen(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TimelineScreen(),
    const PlannerScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openVoiceOrb() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const VoiceModeScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      
      floatingActionButton: SizedBox(
        height: 70,
        width: 70,
        child: FloatingActionButton(
          onPressed: _openVoiceOrb, 
          backgroundColor: AppTheme.kCardDark,
          elevation: 10,
          shape: const CircleBorder(),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.mintGradient,
            ),
            child: const Center(
              child: Icon(Icons.mic_rounded, size: 32, color: Colors.black),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: AppTheme.kCardDark,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.dashboard_rounded, 
                  color: _selectedIndex == 0 ? AppTheme.kPrimaryTeal : AppTheme.kTextGrey, size: 28),
                onPressed: () => _onItemTapped(0),
              ),
              IconButton(
                icon: Icon(Icons.calendar_month_rounded, 
                  color: _selectedIndex == 2 ? AppTheme.kPrimaryTeal : AppTheme.kTextGrey, size: 28),
                onPressed: () => _onItemTapped(2),
              ),
              IconButton(
                icon: Icon(Icons.history_rounded, 
                  color: _selectedIndex == 1 ? AppTheme.kPrimaryTeal : AppTheme.kTextGrey, size: 28),
                onPressed: () => _onItemTapped(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}