import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/background_service.dart';
import 'screens/home_screen.dart';
import 'screens/timeline_screen.dart';
import 'screens/login_screen.dart';
import 'screens/planner_screen.dart';
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 350,
        decoration: BoxDecoration(
          color: kCardDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: kPrimaryTeal.withOpacity(0.5), width: 1)),
          boxShadow: [
            BoxShadow(color: kPrimaryTeal.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing Orb Animation Placeholder
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryTeal,
                boxShadow: [
                  BoxShadow(color: kPrimaryTeal.withOpacity(0.6), blurRadius: 40, spreadRadius: 10)
                ],
              ),
              child: const Icon(Icons.mic, size: 40, color: Colors.black),
            ),
            const SizedBox(height: 30),
            const Text(
              "Listening...",
              style: TextStyle(color: kTextWhite, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Say 'Add a memory' or 'Schedule a meeting'",
              style: TextStyle(color: kTextGrey, fontSize: 14),
            ),
          ],
        ),
      ),
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