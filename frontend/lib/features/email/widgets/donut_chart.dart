import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class DonutChart extends StatelessWidget {
  final String label;
  final String count;
  final Color color;
  final double percentage;

  const DonutChart({
    super.key, 
    required this.label, 
    required this.count, 
    required this.color, 
    required this.percentage
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 60,
          width: 60,
          child: Stack(
            children: [
              Center(
                child: Text(
                  count, 
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold,
                    fontSize: 16
                  )
                )
              ),
              CircularProgressIndicator(
                value: percentage,
                strokeWidth: 6,
                color: color,
                backgroundColor: Colors.white10,
                strokeCap: StrokeCap.round,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(), 
          style: const TextStyle(
            color: AppTheme.kTextGrey, 
            fontSize: 10, 
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0
          )
        ),
      ],
    );
  }
}