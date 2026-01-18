import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/event_tile.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime focusedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      appBar: AppBar(
        title: Text(DateFormat('MMMM yyyy').format(focusedDate)),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () => setState(() => focusedDate = DateTime.now()),
          ),
          // Toggle View Button
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.kAccentGreen),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Text("All Events", style: TextStyle(color: AppTheme.kAccentGreen, fontSize: 12)),
                Icon(Icons.keyboard_arrow_down, color: AppTheme.kAccentGreen, size: 16)
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Days Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
                  .map((e) => Text(e, style: const TextStyle(color: AppTheme.kTextGrey, fontSize: 12, fontWeight: FontWeight.bold)))
                  .toList(),
            ),
          ),
          
          // Calendar Grid (Simplified visual representation)
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                int day = 12 + index; // Mock days
                bool isSelected = index == 2; // Mock selected (Wed 14)
                
                return Column(
                  children: [
                    Container(
                      width: 36, height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.kAccentGreen : Colors.transparent,
                        shape: BoxShape.circle,
                        boxShadow: isSelected ? [
                          BoxShadow(color: AppTheme.kAccentGreen.withOpacity(0.5), blurRadius: 10)
                        ] : [],
                      ),
                      child: Text(
                        "$day", 
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          
          const Divider(color: Colors.white10),
          
          // Events List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                 EventTile(
                  time: "09:00",
                  title: "Team Sync",
                  subtitle: "Review Q4 Goals",
                  category: "Meeting",
                  color: AppTheme.kPrimaryTeal,
                  isFirst: true,
                ),
                 EventTile(
                  time: "11:30",
                  title: "Dentist Appointment",
                  subtitle: "Dr. Smith • Downtown Clinic",
                  category: "Health",
                  color: Colors.blueAccent,
                ),
                 EventTile(
                  time: "14:00",
                  title: "Project Review",
                  subtitle: "Final Design Handoff",
                  category: "Work",
                  color: AppTheme.kAccentGreen,
                  isLast: true,
                ),
              ],
            ),
          ),
          
          // Floating Add Button
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                onPressed: () {},
                backgroundColor: AppTheme.kPrimaryTeal,
                child: const Icon(Icons.add, color: Colors.black),
              ),
            ),
          )
        ],
      ),
    );
  }
}