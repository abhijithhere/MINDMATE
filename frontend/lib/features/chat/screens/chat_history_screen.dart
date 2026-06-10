import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/api_service.dart';
import 'package:intl/intl.dart';

class ChatHistoryScreen extends StatefulWidget {
  final String userId;
  const ChatHistoryScreen({super.key, required this.userId});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final data = await _apiService.getChatHistory(widget.userId);
    if (mounted) {
      setState(() {
        _history = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      appBar: AppBar(
        title: const Text("Memory Logs", style: TextStyle(letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.kPrimaryTeal))
          : _history.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  // Reverse the list to show oldest at top, or newest at top depending on your DB ORDER BY
                  itemBuilder: (context, index) {
                    final msg = _history[index];
                    final isUser = msg['sender'] == 'user';
                    final timeStr = msg['time'] != null 
                        ? DateFormat('MMM dd, hh:mm a').format(DateTime.parse(msg['time']))
                        : "";
                    final isVerified = msg['is_owner_voice'] == 1;

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(16),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isUser ? AppTheme.kPrimaryTeal.withOpacity(0.2) : AppTheme.kCardDark,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                          ),
                          border: Border.all(
                            color: isUser ? AppTheme.kPrimaryTeal.withOpacity(0.5) : Colors.white10,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg['content'] ?? "",
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  timeStr,
                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                ),
                                if (isUser) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    isVerified ? Icons.verified : Icons.gpp_maybe,
                                    size: 12,
                                    color: isVerified ? Colors.green : Colors.redAccent,
                                  )
                                ]
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, color: Colors.white24, size: 64),
          SizedBox(height: 16),
          Text("No conversation logs found.", style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}