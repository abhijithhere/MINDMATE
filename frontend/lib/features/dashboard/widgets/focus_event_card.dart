import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class FocusEventCard extends StatelessWidget {
  final String title;
  final String time;
  final String location;
  final String imageUrl; // For the background/thumbnail

  const FocusEventCard({
    super.key,
    required this.title,
    required this.time,
    required this.location,
    this.imageUrl = 'https://picsum.photos/seed/lab/400/200', // Placeholder
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.kCardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Header
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
              ),
              gradient: const LinearGradient(
                colors: [Color(0xFF004D40), Color(0xFF00695C)], // Fallback gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            ),
          ),
          const SizedBox(height: 16),
          
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.kAccentGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              "HIGH PRIORITY", 
              style: TextStyle(color: AppTheme.kAccentGreen, fontSize: 10, fontWeight: FontWeight.bold)
            ),
          ),
          const SizedBox(height: 8),
          
          // Title
          Text(
            title, 
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 12),
          
          // Details
          _DetailRow(icon: Icons.access_time, text: time),
          const SizedBox(height: 8),
          _DetailRow(icon: Icons.location_on, text: location),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.kTextGrey, size: 16),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: AppTheme.kTextGrey, fontSize: 14)),
      ],
    );
  }
}