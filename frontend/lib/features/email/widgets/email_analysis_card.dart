import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_container.dart';

class EmailAnalysisCard extends StatelessWidget {
  final String sender;
  final String role;
  final String time;
  final String action;
  final String snippet;
  final bool isAlert;

  const EmailAnalysisCard({
    super.key,
    required this.sender, 
    required this.role, 
    required this.time,
    required this.action, 
    required this.snippet, 
    this.isAlert = true
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        color: AppTheme.kCardDark,
        opacity: 0.8,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey.shade800, 
                      radius: 18,
                      child: Text(sender[0], style: const TextStyle(color: Colors.white)),
                    ),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text(time, style: const TextStyle(color: AppTheme.kTextGrey, fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Action Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isAlert ? AppTheme.kAccentGreen : AppTheme.kPrimaryTeal).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(
                    color: isAlert ? AppTheme.kAccentGreen : AppTheme.kPrimaryTeal, 
                    width: 4
                  )
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isAlert ? Icons.assignment_late_outlined : Icons.flight_takeoff, 
                    color: isAlert ? AppTheme.kAccentGreen : AppTheme.kPrimaryTeal, 
                    size: 20
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      action, 
                      style: TextStyle(
                        color: isAlert ? AppTheme.kAccentGreen : AppTheme.kPrimaryTeal, 
                        fontWeight: FontWeight.bold,
                        fontSize: 13
                      )
                    )
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Snippet
            Text(
              snippet, 
              maxLines: 2, 
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.kTextGrey, height: 1.4, fontSize: 13)
            ),
            
            const SizedBox(height: 16),
            
            // Buttons
            Row(
              children: [
                _SmallButton(
                  icon: Icons.edit_note, 
                  label: "Draft Reply", 
                  onTap: () {}
                ),
                const SizedBox(width: 10),
                _SmallButton(
                  icon: Icons.snooze, 
                  label: "Snooze", 
                  onTap: () {}
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SmallButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}