import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/api_constants.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id');
    if (userId == null) return;

    final url = Uri.parse('${ApiConstants.baseUrl}/chat/history?user_id=$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> rawMessages = data['messages'] ?? [];
        
        setState(() {
          // 🛡️ CRASH PROOFING: Ensure 'text' is never null
          messages = rawMessages.map((m) => {
            'sender': m['sender'] ?? 'ai',
            'text': m['text'] ?? "..." // If text is null, show dots
          }).toList().cast<Map<String, dynamic>>();
          isLoading = false;
        });
      }
    } catch (e) {
      print("Chat Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty || userId == null) return;

    String text = _controller.text;
    _controller.clear();

    setState(() {
      messages.add({'sender': 'user', 'text': text});
    });

    final url = Uri.parse('${ApiConstants.baseUrl}/chat/send');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": userId,
          "text": text,
          "sender": "user"
        }),
      );

      // 🛡️ CRASH PROOFING: Handle backend response safely
      String reply = "..."; 
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Look for 'ai_response', 'response', or 'message'
        reply = data['ai_response'] ?? data['response'] ?? data['message'] ?? "I couldn't think of a response.";
      } else {
        reply = "Error: ${response.statusCode}";
      }

      setState(() {
        messages.add({'sender': 'ai', 'text': reply});
      });
      
    } catch (e) {
      setState(() {
        messages.add({'sender': 'ai', 'text': "Connection Error"});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      appBar: AppBar(
        title: const Text("MindMate Chat"),
        backgroundColor: AppTheme.kCardDark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.kPrimaryTeal))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isUser = msg['sender'] == 'user';
                      // 🛡️ FINAL SAFETY CHECK: Ensure we display a String
                      final String messageText = msg['text']?.toString() ?? "";

                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isUser ? AppTheme.kPrimaryTeal : AppTheme.kCardDark,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                              bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                            ),
                          ),
                          child: Text(
                            messageText,
                            style: TextStyle(
                              color: isUser ? Colors.black : Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.kCardDark,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: TextStyle(color: AppTheme.kTextGrey.withOpacity(0.5)),
                      filled: true,
                      fillColor: AppTheme.kBackgroundDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: AppTheme.kPrimaryTeal,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}