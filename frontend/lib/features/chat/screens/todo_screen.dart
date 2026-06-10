// frontend/lib/features/chat/screens/todo_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../services/api_service.dart';
import 'package:intl/intl.dart';

class TodoScreen extends StatefulWidget {
  final String userId;
  const TodoScreen({super.key, required this.userId});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final ApiService _apiService = ApiService();

  // ✅ FIX: Cache the Future so FutureBuilder doesn't re-fire on every setState
  late Future<List<dynamic>> _todoFuture;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  void _loadTodos() {
    _todoFuture = _apiService.getTasksByPage(widget.userId, 'todo');
  }

  void _refresh() {
    setState(() {
      _loadTodos(); // creates a new Future only when explicitly refreshed
    });
  }

  Future<void> _deleteTask(int id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/reminders/delete/$id');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        _refresh();
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

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
              title: const Text("Add New Task",
                  style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: msgController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "What do you need to do?",
                      hintStyle: TextStyle(color: Colors.white38),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: AppTheme.kPrimaryTeal)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.calendar_today,
                              color: AppTheme.kPrimaryTeal, size: 18),
                          label: Text(
                            selectedDate != null
                                ? DateFormat('MMM dd').format(selectedDate!)
                                : "Date",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              setDialogState(() => selectedDate = date);
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.access_time,
                              color: AppTheme.kPrimaryTeal, size: 18),
                          label: Text(
                            selectedTime != null
                                ? selectedTime!.format(context)
                                : "Time",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime ?? TimeOfDay.now(),
                            );
                            if (time != null) {
                              setDialogState(() => selectedTime = time);
                            }
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
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kPrimaryTeal),
                  onPressed: () async {
                    if (msgController.text.isNotEmpty &&
                        selectedDate != null &&
                        selectedTime != null) {
                      final dt = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                      );

                      Navigator.pop(context);

                      final success = await _apiService.createReminder(
                        widget.userId,
                        msgController.text.trim(),
                        dt.toIso8601String(),
                        'Low',
                      );

                      if (success) _refresh();
                    }
                  },
                  child: const Text("Save",
                      style: TextStyle(color: Colors.white)),
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
        title: const Text("LOW PRIORITY TASKS",
            style: TextStyle(
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.kPrimaryTeal),
            onPressed: _refresh,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.kPrimaryTeal,
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        color: AppTheme.kPrimaryTeal,
        child: FutureBuilder<List<dynamic>>(
          // ✅ FIX: Use the cached _todoFuture, NOT an inline function call
          future: _todoFuture,
          builder: (context, snapshot) {
            // ── Loading ───────────────────────────────────────────
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                    color: AppTheme.kPrimaryTeal),
              );
            }

            // ── Error ─────────────────────────────────────────────
            if (snapshot.hasError) {
              debugPrint("❌ TodoScreen error: ${snapshot.error}");
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 48),
                    const SizedBox(height: 12),
                    Text("Error: ${snapshot.error}",
                        style:
                            const TextStyle(color: Colors.redAccent)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text("Retry"),
                    )
                  ],
                ),
              );
            }

            // ── Debug print ───────────────────────────────────────
            final tasks = snapshot.data ?? [];
            debugPrint("✅ TodoScreen: got ${tasks.length} low-priority tasks");

            // ── Empty ─────────────────────────────────────────────
            if (tasks.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(
                    child: Text(
                      "No low-priority tasks pending.",
                      style: TextStyle(color: Colors.white30),
                    ),
                  ),
                ],
              );
            }

            // ── List ──────────────────────────────────────────────
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final String title =
                    task['message'] ?? task['title'] ?? "Untitled Task";

                String displayTime = "No time set";
                if (task['trigger_time'] != null) {
                  try {
                    displayTime = DateFormat('MMM dd, hh:mm a')
                        .format(DateTime.parse(task['trigger_time']));
                  } catch (_) {
                    displayTime = task['trigger_time'].toString();
                  }
                }

                return Dismissible(
                  key: Key(task['id'].toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child:
                        const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  onDismissed: (direction) => _deleteTask(task['id']),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.kCardDark,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.radio_button_unchecked,
                            color: AppTheme.kPrimaryTeal, size: 24),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text("Due: $displayTime",
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_left, color: Colors.white10),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}