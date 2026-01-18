import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_container.dart';

class EmailHubScreen extends StatelessWidget {
  const EmailHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      appBar: AppBar(
        title: const Text("Email Intelligence"),
        backgroundColor: AppTheme.kCardDark,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. DONUT CHARTS ROW ---
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DonutStat(label: "Work", count: "8", color: AppTheme.kAccentGreen, percentage: 0.7),
                _DonutStat(label: "Personal", count: "3", color: AppTheme.kPrimaryTeal, percentage: 0.3),
                _DonutStat(label: "Spam", count: "24", color: Colors.blueAccent, percentage: 0.9),
              ],
            ),
            const SizedBox(height: 30),
            
            // --- 2. ANALYSIS FEED ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Analysis Feed", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: (){}, child: const Text("Clear All", style: TextStyle(color: AppTheme.kAccentGreen))),
              ],
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView(
                children: const [
                  _EmailCard(
                    sender: "Prof. Hamilton",
                    role: "Thesis Committee",
                    time: "10m ago",
                    action: "Action: Submit final thesis draft by 5:00 PM today.",
                    snippet: "Just a reminder that the portal closes promptly this evening...",
                  ),
                  _EmailCard(
                    sender: "Delta Airlines",
                    role: "Travel Updates",
                    time: "2h ago",
                    action: "Check-in for Tokyo opens in 2 hours.",
                    snippet: "Your trip to Tokyo (HND) is coming up. Get ready for your flight...",
                    isAlert: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutStat extends StatelessWidget {
  final String label;
  final String count;
  final Color color;
  final double percentage;

  const _DonutStat({required this.label, required this.count, required this.color, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 60,
          width: 60,
          child: Stack(
            children: [
              Center(child: Text(count, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              CircularProgressIndicator(
                value: percentage,
                strokeWidth: 6,
                color: color,
                backgroundColor: Colors.white10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: AppTheme.kTextGrey, fontSize: 12)),
      ],
    );
  }
}

class _EmailCard extends StatelessWidget {
  final String sender;
  final String role;
  final String time;
  final String action;
  final String snippet;
  final bool isAlert;

  const _EmailCard({
    required this.sender, required this.role, required this.time,
    required this.action, required this.snippet, this.isAlert = true
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        color: AppTheme.kCardDark,
        opacity: 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(backgroundColor: Colors.grey.shade800, child: Text(sender[0])),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sender, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(role, style: const TextStyle(color: AppTheme.kTextGrey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                Text(time, style: const TextStyle(color: AppTheme.kTextGrey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isAlert ? AppTheme.kAccentGreen : AppTheme.kPrimaryTeal).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: isAlert ? AppTheme.kAccentGreen : AppTheme.kPrimaryTeal, width: 4)),
              ),
              child: Row(
                children: [
                  Icon(isAlert ? Icons.assignment : Icons.flight_takeoff, color: isAlert ? AppTheme.kAccentGreen : AppTheme.kPrimaryTeal, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(action, style: TextStyle(color: isAlert ? AppTheme.kAccentGreen : AppTheme.kPrimaryTeal, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(snippet, style: const TextStyle(color: AppTheme.kTextGrey, height: 1.4)),
          ],
        ),
      ),
    );
  }
}