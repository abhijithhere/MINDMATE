// frontend\lib\features\chat\screens\reminders_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/api_service.dart';
import '../../../services/notification_service.dart';
import 'package:intl/intl.dart';

class RemindersScreen extends StatefulWidget {
  final String userId;
  const RemindersScreen({super.key, required this.userId});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermissions();
    _fetchReminders();
  }

  Future<void> _requestNotificationPermissions() async {
    final plugin = FlutterLocalNotificationsPlugin();
    final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    if (Platform.isAndroid) {
      try { await android?.requestExactAlarmsPermission(); } catch (e) { debugPrint("Permission error: $e"); }
    }
  }

  Future<void> _fetchReminders() async {
    try {
      final data = await _apiService.getTasksByPage(widget.userId, 'reminders');
      if (mounted) {
        setState(() { _reminders = data; _isLoading = false; });
        _syncLocalNotifications();
      }
    } catch (e) {
      debugPrint("Sync Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _syncLocalNotifications() async {
    for (var rem in _reminders) {
      bool isActive = rem['is_active'] == true || rem['status'] == 'active';
      String? timeString = rem['raw_time'] ?? rem['trigger_time'];

      if (isActive && timeString != null) {
        DateTime trigger = DateTime.parse(timeString);
        if (trigger.isAfter(DateTime.now())) {
          NotificationService.scheduleNotification(
            id: rem['id'],
            title: "MindMate Alert: ${rem['title'] ?? rem['message'] ?? 'Task'}",
            body: "High Priority Task needs your attention!",
            scheduledDate: trigger,
            priorityLevel: "High",
          );
        }
      }
    }
  }

  Future<void> _deleteReminder(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/reminders/delete/$id');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        await NotificationService.cancel(id);
        _fetchReminders();
      }
    } catch (e) { debugPrint("Delete error: $e"); }
  }

  Future<void> _toggleStatus(int id, bool isActive) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/reminders/toggle');
    try {
      await http.post(
        url, headers: {"Content-Type": "application/json"},
        body: json.encode({"reminder_id": id, "is_active": isActive}),
      );
      if (!isActive) {
        await NotificationService.cancel(id);
      } else {
        _fetchReminders(); 
      }
    } catch (e) { debugPrint("Toggle Error: $e"); }
  }

  // 🟢 NEW: Dialog to add a Critical Alert manually
  Future<void> _showAddDialog(BuildContext context) async {
    final TextEditingController msgController = TextEditingController();
    DateTime? selectedDate = DateTime.now();
    TimeOfDay? selectedTime = TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.kCardDark,
              title: const Text("Add Critical Alert", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: msgController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "What's the emergency?",
                      hintStyle: TextStyle(color: Colors.white38),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.calendar_today, color: Colors.redAccent, size: 18),
                          label: Text(
                            selectedDate != null ? DateFormat('MMM dd').format(selectedDate!) : "Date",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context, initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(), lastDate: DateTime(2030),
                            );
                            if (date != null) setDialogState(() => selectedDate = date);
                          },
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.access_time, color: Colors.redAccent, size: 18),
                          label: Text(
                            selectedTime != null ? selectedTime!.format(context) : "Time",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context, initialTime: selectedTime ?? TimeOfDay.now(),
                            );
                            if (time != null) setDialogState(() => selectedTime = time);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: () async {
                    if (msgController.text.isNotEmpty && selectedDate != null && selectedTime != null) {
                      final dt = DateTime(
                        selectedDate!.year, selectedDate!.month, selectedDate!.day,
                        selectedTime!.hour, selectedTime!.minute,
                      );
                      
                      Navigator.pop(context); 
                      
                      // 🟢 Send to API as 'High' priority
                      final success = await _apiService.createReminder(
                        widget.userId, msgController.text.trim(), dt.toIso8601String(), 'High',
                      );
                      
                      // Fetch reminders to show new task AND register background alarm!
                      if (success) _fetchReminders(); 
                    }
                  },
                  child: const Text("Save Alert", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      appBar: AppBar(
        title: const Text("CRITICAL ALERTS", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.redAccent)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.redAccent),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.redAccent), 
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchReminders();
            }
          )
        ],
      ),
      // 🟢 NEW: Floating Action Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : _reminders.isEmpty 
              ? const Center(child: Text("No high-priority alerts.", style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reminders.length,
                  itemBuilder: (context, index) => _buildReminderTile(_reminders[index]),
                ),
    );
  }

  Widget _buildReminderTile(Map<String, dynamic> item) {
    const Color pColor = Colors.redAccent;
    final String title = item['title'] ?? item['message'] ?? "Untitled";
    final bool isActive = item['is_active'] == true || item['status'] == 'active';
    
    String displayTime = "No time set";
    if (item['remind_time'] != null) {
      displayTime = item['remind_time'];
    } else if (item['trigger_time'] != null) {
      displayTime = DateFormat('hh:mm a').format(DateTime.parse(item['trigger_time']));
    }

    return Dismissible(
      key: Key(item['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(15)),
        child: const Icon(Icons.delete_forever, color: Colors.white, size: 30),
      ),
      onDismissed: (direction) => _deleteReminder(item['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.kCardDark,
          borderRadius: BorderRadius.circular(15),
          border: const Border(left: BorderSide(color: pColor, width: 5)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(displayTime, style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          trailing: Switch(
            value: isActive,
            activeColor: pColor,
            onChanged: (val) {
              setState(() {
                item['is_active'] = val;
                item['status'] = val ? 'active' : 'inactive';
              });
              _toggleStatus(item['id'], val);
            },
          ),
        ),
      ),
    );
  }
}