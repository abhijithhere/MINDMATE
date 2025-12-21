import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/background_service.dart';
import 'screens/home_screen.dart';
import 'screens/timeline_screen.dart';
import 'screens/login_screen.dart';
import 'screens/planner_screen.dart';
import 'screens/chat_screen.dart';

// --- CUSTOM COLORS ---
const Color kBackgroundDark = Color(0xFF121212);
const Color kCardDark = Color(0xFF1E1E1E);
const Color kPrimaryTeal = Color(0xFF00E5FF);
const Color kAccentGreen = Color(0xFF00C853);
const Color kTextWhite = Color(0xFFFFFFFF);
const Color kTextGrey = Color(0xFFB3B3B3);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Background Service
  await initializeService();

  // 2. Check Login Status
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kBackgroundDark,
        primaryColor: kPrimaryTeal,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackgroundDark,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: kTextWhite,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
          iconTheme: IconThemeData(color: kTextWhite),
        ),
        colorScheme: const ColorScheme.dark(
          primary: kPrimaryTeal,
          secondary: kAccentGreen,
          surface: kCardDark,
          background: kBackgroundDark,
        ),
      ),
      // Use MainLayout if logged in, otherwise LoginScreen
      home: isLoggedIn ? const MainLayout() : const LoginScreen(),
    );
  }
}

// --- MAIN LAYOUT (Bottom Nav + Voice Orb) ---
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // The screens available in the bottom bar
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

  // ✅ FIX: The missing function is added here
  void _openVoiceOrb() {
  Navigator.push(
    context, 
    MaterialPageRoute(builder: (context) => const ChatScreen())
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Show the selected screen
      body: _screens[_selectedIndex],
      
      // Floating Action Button (The Voice Orb)
      floatingActionButton: SizedBox(
        height: 70,
        width: 70,
        child: FloatingActionButton(
          onPressed: _openVoiceOrb, // Calls the function above
          backgroundColor: kCardDark,
          elevation: 10,
          shape: const CircleBorder(),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [kPrimaryTeal, kAccentGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(Icons.mic_rounded, size: 32, color: Colors.black),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom Navigation Bar
      bottomNavigationBar: BottomAppBar(
        // ... (keep existing properties)
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.dashboard_rounded, 
                  color: _selectedIndex == 0 ? kPrimaryTeal : kTextGrey, size: 28),
                onPressed: () => _onItemTapped(0),
              ),
              IconButton( // Middle Planner Button
                icon: Icon(Icons.calendar_month_rounded, 
                  color: _selectedIndex == 2 ? kPrimaryTeal : kTextGrey, size: 28),
                onPressed: () => _onItemTapped(2),
              ),
              IconButton(
                icon: Icon(Icons.history_rounded, 
                  color: _selectedIndex == 1 ? kPrimaryTeal : kTextGrey, size: 28),
                onPressed: () => _onItemTapped(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}