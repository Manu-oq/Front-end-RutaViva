import 'package:flutter/material.dart';
import 'trail_painter.dart';

class ItineraryStepWidget extends StatelessWidget {
  final String time;
  final String description;
  final Widget child;

  const ItineraryStepWidget({
    super.key,
    required this.time,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(color: theme.colorScheme.secondary, shape: BoxShape.circle),
              ),
              Expanded(
                child: CustomPaint(
                  painter: TrailPainter(color: theme.colorScheme.secondary),
                  child: const SizedBox(width: 2),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (time.isNotEmpty) Text(time, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18)),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(description, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 16),
                child,
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}