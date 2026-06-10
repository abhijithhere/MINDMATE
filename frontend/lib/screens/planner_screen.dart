//frontend\lib\screens\planner_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';

class PlannerScreen extends StatefulWidget {
  final String userId;
  const PlannerScreen({super.key, required this.userId});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  List<dynamic> aiSchedule = [];
  bool isPredicting = false;

  @override
  void initState() {
    super.initState();
    _fetchAISchedule(); 
  }

  Future<void> _fetchAISchedule() async {
  setState(() => isPredicting = true);
  
  String dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
  
  // 🟢 Connect to the correct endpoint from ApiConstants
  final url = Uri.parse('${ApiConstants.prediction}?user_id=${widget.userId}&target_date=$dateStr');
  
  debugPrint("🚀 Requesting AI Plan: $url");

  try {
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // 🕵️ DEBUG: This will show you exactly what the backend sent in your console
      debugPrint("📦 Backend Response: ${response.body}");

      setState(() {
        // 🟢 Extract the 'timetable' key. If it's null, use an empty list.
        aiSchedule = data['timetable'] ?? [];
      });
      
      if (aiSchedule.isEmpty) {
        debugPrint("⚠️ Data received but 'timetable' list is empty.");
      }
    } else {
      debugPrint("❌ Server Error: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("❌ Connection Error: $e");
  } finally {
    if (mounted) {
      setState(() => isPredicting = false);
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      appBar: AppBar(
        title: const Text("AI Future Planner"),
        backgroundColor: AppTheme.kBackgroundDark,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildDatePickerHeader(),
            const SizedBox(height: 20),
            isPredicting 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.kPrimaryTeal))
              : _buildScheduleList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Plan for: ${DateFormat('MMM d').format(selectedDate)}",
          style: const TextStyle(color: AppTheme.kTextWhite, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today, color: AppTheme.kPrimaryTeal),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (picked != null) {
              setState(() => selectedDate = picked);
              _fetchAISchedule();
            }
          },
        )
      ],
    );
  }

  Widget _buildScheduleList() {
    return Expanded(
      child: ListView.builder(
        itemCount: aiSchedule.length,
        itemBuilder: (context, index) {
          final item = aiSchedule[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.kCardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: AppTheme.kPrimaryTeal, width: 4)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(item['time'], style: const TextStyle(color: AppTheme.kPrimaryTeal, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Text(item['activity'], style: const TextStyle(color: AppTheme.kTextWhite, fontSize: 16)),
                ),
                const Icon(Icons.auto_awesome, color: Colors.white10, size: 18),
              ],
            ),
          );
        },
      ),
    );
  }
}