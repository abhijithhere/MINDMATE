import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../services/api_service.dart';

class EmailHubScreen extends StatefulWidget {
  final String userId;
  const EmailHubScreen({super.key, required this.userId});

  @override
  State<EmailHubScreen> createState() => _EmailHubScreenState();
}

class _EmailHubScreenState extends State<EmailHubScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _emails = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGmailData();
  }

  Future<void> _fetchGmailData() async {
    final data = await _apiService.getGmailData(widget.userId);
    if (mounted) {
      setState(() {
        _emails = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundDark,
      appBar: AppBar(
        title: const Text("Email Intelligence"),
        backgroundColor: AppTheme.kCardDark,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.kPrimaryTeal))
        : Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _DonutStat(label: "Extracted", count: "12", color: AppTheme.kAccentGreen, percentage: 0.8),
                    _DonutStat(label: "Pending", count: "3", color: AppTheme.kPrimaryTeal, percentage: 0.3),
                  ],
                ),
                const SizedBox(height: 30),
                const Text("Analysis Feed", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: _emails.isEmpty 
                    ? const Center(child: Text("No extracted events from Gmail.", style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: _emails.length,
                        itemBuilder: (context, index) {
                          final email = _emails[index];
                          // Adapting standard event/timeline columns to the Email UI
                          return _EmailCard(
                            sender: email['sender'] ?? "Gmail Sync",
                            role: email['category'] ?? "Automated Extraction",
                            time: email['start_time'] ?? "Recent",
                            action: email['title'] ?? "Action Required",
                            snippet: email['description'] ?? email['content'] ?? "No summary available.",
                            isAlert: (email['priority'] ?? "Low") == "High",
                          );
                        },
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
          height: 60, width: 60,
          child: Stack(
            children: [
              Center(child: Text(count, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              CircularProgressIndicator(
                value: percentage, strokeWidth: 6, color: color, backgroundColor: Colors.white10,
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
  final String sender, role, time, action, snippet;
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
                    CircleAvatar(backgroundColor: Colors.grey.shade800, child: Text(sender.isNotEmpty ? sender[0].toUpperCase() : "G")),
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
                  Icon(isAlert ? Icons.assignment_late : Icons.auto_awesome, color: isAlert ? AppTheme.kAccentGreen : AppTheme.kPrimaryTeal, size: 20),
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