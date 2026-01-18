import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart'; // 👈 IMPORTED THEME
import '../core/constants/api_constants.dart'; // 👈 IMPORTED CONSTANTS

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Suggestion State
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1)); // Default tomorrow
  List<dynamic> aiSchedule = [];
  bool isPredicting = false;

  // Overview State
  DateTimeRange? selectedRange;
  Map<String, dynamic> stats = {};
  bool isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAISchedule(); 
  }

  // --- 1. AI PREDICTION LOGIC ---
  Future<void> _fetchAISchedule() async {
    setState(() => isPredicting = true);
    String dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final url = Uri.parse('${ApiConstants.baseUrl}/predict/schedule?date=$dateStr');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          aiSchedule = data['suggested_schedule'] ?? [];
        });
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => isPredicting = false);
    }
  }

  // --- 2. OVERVIEW LOGIC ---
  Future<void> _fetchPeriodStats() async {
    if (selectedRange == null) return;
    
    setState(() => isLoadingStats = true);
    String start = DateFormat('yyyy-MM-dd').format(selectedRange!.start);
    String end = DateFormat('yyyy-MM-dd').format(selectedRange!.end);
    
    final url = Uri.parse('${ApiConstants.baseUrl}/analytics/period?user_id=test_user&start_date=$start&end_date=$end');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          stats = data['stats'];
        });
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark, // Updated
      appBar: AppBar(
        title: const Text("Planner & Review"),
        backgroundColor: AppTheme.kBackgroundDark,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.kPrimaryTeal, // Updated
          labelColor: AppTheme.kPrimaryTeal, // Updated
          unselectedLabelColor: AppTheme.kTextGrey, // Updated
          tabs: const [
            Tab(text: "AI Suggestion"),
            Tab(text: "Period Review"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPredictionTab(),
          _buildOverviewTab(),
        ],
      ),
    );
  }

  // --- TAB 1: AI SUGGESTION UI ---
  Widget _buildPredictionTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Date Picker Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Plan for: ${DateFormat('MMM d').format(selectedDate)}",
                style: const TextStyle(color: AppTheme.kTextWhite, fontSize: 18), // Updated
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kCardDark), // Updated
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
                child: const Text("Change Date", style: TextStyle(color: AppTheme.kPrimaryTeal)), // Updated
              )
            ],
          ),
          const SizedBox(height: 20),
          
          isPredicting 
          ? const CircularProgressIndicator(color: AppTheme.kPrimaryTeal) // Updated
          : Expanded(
              child: ListView.builder(
                itemCount: aiSchedule.length,
                itemBuilder: (context, index) {
                  final item = aiSchedule[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.kCardDark, // Updated
                      borderRadius: BorderRadius.circular(12),
                      border: Border(left: BorderSide(color: AppTheme.kPrimaryTeal.withOpacity(0.5), width: 4)), // Updated
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['time'], style: const TextStyle(color: AppTheme.kTextGrey, fontWeight: FontWeight.bold)), // Updated
                        Text(item['activity'], style: const TextStyle(color: AppTheme.kTextWhite, fontSize: 16)), // Updated
                        Icon(Icons.arrow_forward, color: AppTheme.kTextGrey.withOpacity(0.3), size: 16), // Updated
                      ],
                    ),
                  );
                },
              ),
            )
        ],
      ),
    );
  }

  // --- TAB 2: OVERVIEW UI ---
  Widget _buildOverviewTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.calendar_month, color: AppTheme.kBackgroundDark), // Updated
            label: Text(selectedRange == null ? "Select Period" : "Change Period", 
              style: const TextStyle(color: AppTheme.kBackgroundDark, fontWeight: FontWeight.bold)), // Updated
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kPrimaryTeal), // Updated
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppTheme.kPrimaryTeal, // Updated
                        onPrimary: Colors.black,
                        surface: AppTheme.kCardDark, // Updated
                      ),
                    ),
                    child: child!,
                  );
                }
              );
              if (picked != null) {
                setState(() => selectedRange = picked);
                _fetchPeriodStats();
              }
            },
          ),
          const SizedBox(height: 10),
          if (selectedRange != null)
            Text(
              "${DateFormat('MM/dd').format(selectedRange!.start)} - ${DateFormat('MM/dd').format(selectedRange!.end)}",
              style: const TextStyle(color: AppTheme.kTextGrey), // Updated
            ),
          const SizedBox(height: 30),
          
          isLoadingStats
          ? const CircularProgressIndicator(color: AppTheme.kPrimaryTeal) // Updated
          : stats.isEmpty 
              ? const Text("Select a range to see analytics", style: TextStyle(color: AppTheme.kTextGrey)) // Updated
              : Expanded(
                  child: ListView(
                    children: stats.entries.map((entry) {
                      return ListTile(
                        leading: const Icon(Icons.pie_chart, color: AppTheme.kAccentGreen), // Updated
                        title: Text(entry.key, style: const TextStyle(color: AppTheme.kTextWhite)), // Updated
                        trailing: Text("${entry.value.toStringAsFixed(1)} hours", 
                          style: const TextStyle(color: AppTheme.kPrimaryTeal, fontWeight: FontWeight.bold, fontSize: 16)), // Updated
                      );
                    }).toList(),
                  ),
                )
        ],
      ),
    );
  }
}