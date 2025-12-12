import 'package:flutter/material.dart';

// --- Constants (Matching your design system) ---
const Color kBackgroundColor = Color(0xFF0F172A);
const Color kPrimaryGreen = Color(0xFF10B981);
const Color kAccentTeal = Color(0xFF2DD4BF);
const Color kCardColor = Color(0xFF1E293B);
const Color kCardHighlight = Color(0xFF334155);
const Color kTextColor = Colors.white;
const Color kSecondaryTextColor = Color(0xFF94A3B8);

// ==================== VOICE INTERACTION PAGE ====================
class VoiceInteractionPage extends StatelessWidget {
  const VoiceInteractionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A2E2C), kBackgroundColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Chatpodia",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              
              const Spacer(flex: 1),
              
              // Animated Pulse Circle
              const FlowingGlowingCircle(),
              
              const SizedBox(height: 40),
              const Text("Podia is listening...",
                  style: TextStyle(color: kSecondaryTextColor, fontSize: 18)),
              
              const Spacer(flex: 1),
              
              // Spoken Text Preview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                        fontSize: 24,
                        color: kTextColor,
                        fontWeight: FontWeight.w500,
                        height: 1.3),
                    children: [
                      TextSpan(text: "Hi, play my favorite playlist to accompany me "),
                      TextSpan(
                        text: "while studying\nmy assignments.",
                        style: TextStyle(color: kSecondaryTextColor),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(flex: 2),
              
              // Bottom Controls
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // --- UPDATED: KEYBOARD ICON BUTTON ---
                    IconButton(
                      onPressed: () {
                        // Navigates to the Chat Page
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const ChatPage()),
                        );
                      },
                      icon: const Icon(Icons.keyboard_outlined, color: kTextColor),
                      iconSize: 28,
                    ),
                    
                    // Mic Button (Visual only for now)
                    Container(
                      height: 72,
                      width: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [kAccentTeal, kPrimaryGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryGreen.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: const Icon(Icons.mic, color: Colors.white, size: 32),
                    ),
                    
                    // Close Button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: kTextColor),
                      iconSize: 28,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== CHAT PAGE (TEXT INTERFACE) ====================
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Chat Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
                    onPressed: () {
                      // --- UPDATED: Enables going back ---
                      Navigator.pop(context);
                    },
                  ),
                  const Text("Chatpodia",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(
                      icon: const Icon(Icons.more_horiz, color: Colors.white), onPressed: () {}),
                ],
              ),
            ),

            // Messages List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: const [
                  ReceivedMessageBubble(
                    message: "How can I assist you today?",
                    showActions: true,
                  ),
                  SizedBox(height: 24),
                  SentMessageBubble(message: "Recommended music"),
                  SizedBox(height: 12),
                  QuickReplySuggestionsCard(),
                ],
              ),
            ),

            // Input Area
            _buildChatInputBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInputBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: kBackgroundColor,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: kSecondaryTextColor),
                  border: InputBorder.none,
                  suffixIcon: Icon(Icons.graphic_eq, color: kSecondaryTextColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: kPrimaryGreen,
            radius: 24,
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

// ==================== WIDGET COMPONENTS (Unchanged) ====================

// 1. RECEIVED MESSAGE (AI)
class ReceivedMessageBubble extends StatelessWidget {
  final String message;
  final bool showActions;
  const ReceivedMessageBubble(
      {super.key, required this.message, this.showActions = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [kAccentTeal, Colors.white],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(24).copyWith(topLeft: Radius.zero),
              ),
              child: Text(message, style: const TextStyle(color: kTextColor, fontSize: 15)),
            ),
            if (showActions) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPillButton(Icons.copy, "Copy"),
                  const SizedBox(width: 8),
                  _buildPillButton(Icons.share, "Share"),
                ],
              )
            ]
          ],
        ),
      ],
    );
  }

  Widget _buildPillButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: kSecondaryTextColor),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: kSecondaryTextColor, fontSize: 12)),
        ],
      ),
    );
  }
}

// 2. SENT MESSAGE (User)
class SentMessageBubble extends StatelessWidget {
  final String message;
  const SentMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24).copyWith(bottomRight: Radius.zero),
          ),
          child: Text(message,
              style: const TextStyle(
                  color: Colors.black, fontSize: 15, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

// 3. QUICK REPLY SUGGESTIONS CARD
class QuickReplySuggestionsCard extends StatelessWidget {
  const QuickReplySuggestionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [kAccentTeal, Colors.white],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(20).copyWith(topLeft: Radius.zero),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: const [
                      Icon(Icons.message_outlined, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        "Quick reply suggestions",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Spacer(),
                      Icon(Icons.keyboard_arrow_down, color: kSecondaryTextColor),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.white.withOpacity(0.08)),
                _buildListItem(Icons.music_note_outlined, "Lofi Beats"),
                _buildListItem(Icons.headphones_outlined, "Nature & Ambient Sounds"),
                _buildListItem(Icons.local_fire_department_outlined, "Motivational & Classical"),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: kCardHighlight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.share, size: 14, color: kSecondaryTextColor),
                        SizedBox(width: 8),
                        Text("Share", 
                            style: TextStyle(color: kSecondaryTextColor, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: kSecondaryTextColor, size: 18),
          const SizedBox(width: 12),
          Text(
            text, 
            style: const TextStyle(color: kSecondaryTextColor, fontSize: 14)
          ),
        ],
      ),
    );
  }
}

// 4. ANIMATED CIRCLE (For Voice Page)
class FlowingGlowingCircle extends StatefulWidget {
  const FlowingGlowingCircle({super.key});
  @override
  State<FlowingGlowingCircle> createState() => _FlowingGlowingCircleState();
}

class _FlowingGlowingCircleState extends State<FlowingGlowingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      width: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildPulsingCircle(0.0),
          _buildPulsingCircle(0.5),
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5EEAD4), kPrimaryGreen],
              ),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryGreen.withOpacity(0.6),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: ClipOval(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_controller.value * 200 - 100, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingCircle(double delayStart) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = (_controller.value + delayStart) % 1.0;
        final double scale = 1.0 + (t * 0.5);
        final double opacity = 1.0 - t;

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity * 0.5,
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kAccentTeal.withOpacity(0.5), width: 2),
                gradient: RadialGradient(
                  colors: [kAccentTeal.withOpacity(0.0), kAccentTeal.withOpacity(0.1)],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}