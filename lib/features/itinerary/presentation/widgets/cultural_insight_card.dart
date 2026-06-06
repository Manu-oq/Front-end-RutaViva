import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CulturalInsightCard extends StatelessWidget {
  final String text;
  final String label;
  final IconData icon;
  final Widget? action;

  const CulturalInsightCard({
    super.key,
    required this.text,
    required this.label,
    this.icon = Icons.auto_awesome,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.primary,
                child: Icon(icon, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            text,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge,
          ),
          if (action != null) ...[
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerRight, child: action!),
          ],
        ],
      ),
    );
  }
}
