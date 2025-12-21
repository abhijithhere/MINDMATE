import 'package:flutter/material.dart';
import '../main.dart'; // For theme colors

class VoiceModeScreen extends StatefulWidget {
  const VoiceModeScreen({super.key});

  @override
  State<VoiceModeScreen> createState() => _VoiceModeScreenState();
}

class _VoiceModeScreenState extends State<VoiceModeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // State for the Toggle
  bool isAlwaysListening = true; // Default to true based on your request

  // Placeholder Data
  String liveTranscript = "Hi, play my favorite playlist to accompany me while studying my assignments.";
  String extractedNote = "• Action: Play Playlist\n• Context: Studying\n• Mood: Focused";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text("Voice Mode", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        
        // --- 🆕 ALWAYS ON TOGGLE ---
        actions: [
          Row(
            children: [
              Text(
                "Always On", 
                style: TextStyle(
                  color: isAlwaysListening ? kPrimaryTeal : Colors.grey, 
                  fontSize: 12, 
                  fontWeight: FontWeight.bold
                )
              ),
              Switch(
                value: isAlwaysListening,
                activeColor: kPrimaryTeal,
                activeTrackColor: kPrimaryTeal.withOpacity(0.3),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.withOpacity(0.3),
                onChanged: (value) {
                  setState(() {
                    isAlwaysListening = value;
                    // If turned off, we could stop the animation or clear text
                    if (!isAlwaysListening) {
                      _controller.stop();
                    } else {
                      _controller.repeat(reverse: true);
                    }
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value ? "Always Listening Enabled" : "Always Listening Paused"),
                      duration: const Duration(milliseconds: 800),
                      backgroundColor: kCardDark,
                    )
                  );
                },
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      
      body: Stack(
        children: [
          // BACKGROUND GRADIENT (Only visible when On)
          if (isAlwaysListening)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [kPrimaryTeal.withOpacity(0.2), Colors.transparent],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
              ),
            ),

          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 20),
              
              // --- 1. THE PULSING ORB ---
              Expanded(
                flex: 2,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      double scale = isAlwaysListening ? (_controller.value * 20) : 0;
                      
                      return Container(
                        width: 180 + scale,
                        height: 180 + scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isAlwaysListening 
                              ? [kPrimaryTeal, kAccentGreen.withOpacity(0.8)]
                              : [Colors.grey.shade800, Colors.grey.shade900], // Grey when off
                          ),
                          boxShadow: isAlwaysListening ? [
                            BoxShadow(
                              color: kPrimaryTeal.withOpacity(0.6),
                              blurRadius: 40 + scale,
                              spreadRadius: 5,
                            ),
                          ] : [],
                        ),
                        child: Center(
                          child: Icon(
                            isAlwaysListening ? Icons.mic : Icons.mic_off, 
                            color: Colors.white, 
                            size: 60
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // --- 2. LISTENING INDICATOR ---
              Text(
                isAlwaysListening ? "MindMate is listening..." : "Mic is Paused",
                style: TextStyle(color: kTextGrey.withOpacity(0.6), fontSize: 16, letterSpacing: 1.2),
              ),
              const SizedBox(height: 30),

              // --- 3. TRANSCRIPT & NOTE AREA (Visible only when On) ---
              Expanded(
                flex: 2,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: isAlwaysListening ? 1.0 : 0.3, // Dimmed when off
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: kCardDark,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LIVE TRANSCRIPT
                        Text(
                          isAlwaysListening ? liveTranscript : "...",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 10),
                        
                        // EXTRACTED DATA
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: kPrimaryTeal, size: 18),
                            const SizedBox(width: 8),
                            const Text("EXTRACTED NOTES", style: TextStyle(color: kPrimaryTeal, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              isAlwaysListening ? extractedNote : "",
                              style: const TextStyle(
                                color: kTextGrey,
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ),
                        
                        // CONTROLS
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCircleButton(Icons.keyboard, "Type"),
                            // The STOP button can also toggle the state
                            _buildCircleButton(
                              isAlwaysListening ? Icons.pause : Icons.play_arrow, 
                              "Toggle", 
                              isPrimary: true
                            ),
                            _buildCircleButton(Icons.close, "Cancel"),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, String label, {bool isPrimary = false}) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPrimary ? kPrimaryTeal : Colors.white10,
            border: isPrimary ? null : Border.all(color: Colors.white24),
          ),
          child: IconButton(
            icon: Icon(icon, color: isPrimary ? Colors.black : Colors.white),
            onPressed: () {
              if (label == "Toggle") {
                 setState(() {
                   isAlwaysListening = !isAlwaysListening;
                   if (!isAlwaysListening) _controller.stop();
                   else _controller.repeat(reverse: true);
                 });
              }
              if (label == "Cancel") Navigator.pop(context);
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}