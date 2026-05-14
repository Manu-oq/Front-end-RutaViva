import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AuthenticitySeal extends StatelessWidget {
  const AuthenticitySeal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.sun.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.sun.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 15, color: AppColors.earth),
          const SizedBox(width: 6),
          Text(
            'Auténtico local',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.earth,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
