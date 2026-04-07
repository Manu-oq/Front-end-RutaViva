import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CulturalInsightCard extends StatelessWidget {
  final String text;
  final String label;
  final IconData icon;

  const CulturalInsightCard({
    super.key, 
    required this.text, 
    required this.label,
    this.icon = Icons.auto_awesome, 
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(), 
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                  letterSpacing: 1.2,
                )
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"$text"',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}