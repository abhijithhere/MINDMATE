// frontend/lib/features/chat/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>>? initialHistory;
  const ChatScreen({super.key, required this.userId, this.initialHistory});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages = [];
    if (widget.initialHistory != null) {
      _messages = widget.initialHistory!.map((msg) {
        return {
          'sender': msg['sender'] ?? 'ai',
          'text': msg['content'] ?? msg['text'] ?? '',
          'timestamp': msg['time'] ?? DateTime.now().toIso8601String(),
        };
      }).toList().cast<Map<String, dynamic>>();
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userText = _controller.text.trim();
    setState(() {
      _messages.add({"sender": "user", "text": userText, "timestamp": DateTime.now().toIso8601String()});
      _isTyping = true;
    });
    _controller.clear();

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.chatSend),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": widget.userId, "text": userText}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // 🟢 FIX: Handle both 'ai_response' and 'response' keys to prevent null errors
          _messages.add({
            "sender": "ai", 
            "text": data['ai_response'] ?? data['response'] ?? "I processed that, but had trouble formatting the answer.",
            "timestamp": DateTime.now().toIso8601String()
          });
        });
      }
    } catch (e) {
      debugPrint("Chat Error: $e");
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      appBar: AppBar(title: const Text("MINDMATE CHAT"), backgroundColor: Colors.transparent),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                // 🟢 FIX: Provide a default string to avoid the Red Screen
                return ChatBubble(
                  message: msg['text'] ?? "...", 
                  isUser: msg['sender'] == 'user',
                  timestamp: DateTime.parse(msg['timestamp'] ?? DateTime.now().toIso8601String()),
                );
              },
            ),
          ),
          if (_isTyping) const Padding(
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(color: AppTheme.kPrimaryTeal, backgroundColor: Colors.black),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: AppTheme.kCardDark,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "Type a message...", border: InputBorder.none),
            ),
          ),
          IconButton(icon: const Icon(Icons.send, color: AppTheme.kPrimaryTeal), onPressed: _sendMessage),
        ],
      ),
    );
  }
}