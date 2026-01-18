import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class MemoryPinCard extends StatelessWidget {
  final String title;
  final String content;
  final String category;
  final bool isSecure;

  const MemoryPinCard({
    super.key,
    required this.title,
    required this.content,
    required this.category,
    this.isSecure = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine Color based on Category
    Color cardColor;
    IconData icon;
    
    switch (category.toLowerCase()) {
      case 'secure':
        cardColor = AppTheme.kAccentGreen;
        icon = Icons.security;
        break;
      case 'identity':
        cardColor = Colors.blueAccent;
        icon = Icons.badge;
        break;
      case 'health':
        cardColor = Colors.pinkAccent;
        icon = Icons.medical_services;
        break;
      case 'project':
        cardColor = Colors.cyan;
        icon = Icons.rocket_launch;
        break;
      default:
        cardColor = Colors.orangeAccent;
        icon = Icons.lightbulb;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.kCardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: cardColor),
                  const SizedBox(width: 6),
                  Text(
                    category.toUpperCase(),
                    style: TextStyle(
                      color: cardColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              if (isSecure) 
                const Icon(Icons.push_pin, size: 14, color: AppTheme.kAccentGreen),
            ],
          ),
          const SizedBox(height: 12),
          
          // Title
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Content (Obscured if secure)
          if (isSecure)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 12, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    "• • • • • • • •", 
                    style: TextStyle(color: Colors.grey.shade400, letterSpacing: 2),
                  ),
                ],
              ),
            )
          else
            Text(
              content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.kTextGrey,
                fontSize: 13,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}