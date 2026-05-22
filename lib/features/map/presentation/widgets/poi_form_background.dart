import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PoiFormBackground extends StatelessWidget {
  final Widget child;

  const PoiFormBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDark
                ? theme.colorScheme.surfaceContainerLowest
                : theme.colorScheme.surface,
            isDark
                ? AppColors.deepForest
                : AppColors.mint.withValues(alpha: 0.42),
            isDark
                ? theme.colorScheme.surfaceContainerLowest
                : theme.colorScheme.surface,
          ],
        ),
      ),
      child: child,
    );
  }
}
