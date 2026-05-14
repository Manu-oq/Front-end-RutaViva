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
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.28),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CustomPaint(
                  painter: TrailPainter(
                    color: theme.colorScheme.outlineVariant,
                  ),
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
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 17,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(description, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 12),
                child,
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
