import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class EventTile extends StatelessWidget {
  final String time;
  final String title;
  final String subtitle;
  final String category;
  final Color color;
  final bool isSuggestion;
  final bool isFirst;
  final bool isLast;

  const EventTile({
    super.key,
    required this.time,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.color,
    this.isSuggestion = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time Column
          SizedBox(
            width: 50,
            child: Column(
              children: [
                if (!isFirst) Expanded(child: Container(width: 2, color: Colors.grey.withOpacity(0.2))),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    height: 12, width: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                      color: AppTheme.kBackgroundDark,
                    ),
                  ),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey.withOpacity(0.2))),
              ],
            ),
          ),
          
          // Time Text
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(time, style: const TextStyle(color: AppTheme.kTextGrey, fontSize: 12)),
            ),
          ),

          // Card Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.kCardDark,
                borderRadius: BorderRadius.circular(16),
                border: isSuggestion ? Border.all(color: AppTheme.kAccentGreen.withOpacity(0.3)) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(isSuggestion ? Icons.lightbulb : Icons.article, size: 14, color: color),
                      const SizedBox(width: 8),
                      Text(category.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const Spacer(),
                      if (isSuggestion) const Icon(Icons.check_circle_outline, color: AppTheme.kAccentGreen, size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppTheme.kTextGrey, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}