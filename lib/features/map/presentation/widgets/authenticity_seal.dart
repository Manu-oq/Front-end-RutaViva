import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AuthenticitySeal extends StatelessWidget {
  const AuthenticitySeal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFFFC46B) : AppColors.earth;
    final fill = isDark
        ? const Color(0xFFFFC46B).withValues(alpha: 0.18)
        : AppColors.sun.withValues(alpha: 0.16);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 15, color: accent),
          const SizedBox(width: 6),
          Text(
            'Auténtico local',
            style: theme.textTheme.labelMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
