import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // For theme colors

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

    final url = Uri.parse('http://10.0.2.2:8000/chat/history?user_id=$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          messages = List<Map<String, dynamic>>.from(data['messages']);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Chat Error: $e");
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty || userId == null) return;

    String text = _controller.text;
    _controller.clear();

    // Optimistic Update (Show immediately)
    setState(() {
      messages.add({'sender': 'user', 'text': text});
    });

    final url = Uri.parse('http://10.0.2.2:8000/chat/send');
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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          messages.add({'sender': 'ai', 'text': data['ai_response']});
        });
      }
    } catch (e) {
      print("Send Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundDark,
      appBar: AppBar(
        title: const Text("MindMate Chat"),
        backgroundColor: kCardDark,
      ),
      body: Column(
        children: [
          // CHAT LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: kPrimaryTeal))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isUser = msg['sender'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isUser ? kPrimaryTeal : kCardDark,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                              bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                            ),
                          ),
                          child: Text(
                            msg['text'],
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

          // INPUT AREA
          Container(
            padding: const EdgeInsets.all(16),
            color: kCardDark,
            child: Row(
              children: [
                // MIC BUTTON
                Container(
                  decoration: BoxDecoration(color: kBackgroundDark, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.mic, color: kPrimaryTeal),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Listening... (Voice Input)")),
                      );
                      // Future: Hook this up to upload-audio endpoint
                    },
                  ),
                ),
                const SizedBox(width: 10),
                
                // TEXT FIELD
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: TextStyle(color: kTextGrey.withOpacity(0.5)),
                      filled: true,
                      fillColor: kBackgroundDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // SEND BUTTON
                CircleAvatar(
                  backgroundColor: kPrimaryTeal,
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