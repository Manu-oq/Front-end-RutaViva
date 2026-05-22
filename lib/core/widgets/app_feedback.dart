import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/app_durations.dart';
import '../utils/responsive.dart';

enum AppFeedbackType { error, warning, info, success }

class AppFeedbackBanner extends StatelessWidget {
  final String message;
  final AppFeedbackType type;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;
  final bool compact;

  const AppFeedbackBanner({
    super.key,
    required this.message,
    this.type = AppFeedbackType.error,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _feedbackColors(theme, type);
    final isMobile = AppResponsive.isMobile(context);

    return Semantics(
      liveRegion: true,
      child: AnimatedSwitcher(
        duration: AppDurations.short,
        child: Container(
          key: ValueKey('$type-$message'),
          width: double.infinity,
          padding: EdgeInsets.all(compact || isMobile ? 12 : 14),
          decoration: BoxDecoration(
            color: colors.color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(isMobile ? 16 : 18),
            border: Border.all(color: colors.color.withValues(alpha: 0.34)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(colors.icon, color: colors.color, size: compact ? 20 : 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.color,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
              if (onAction != null && actionLabel != null) ...[
                const SizedBox(width: 8),
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
              if (onDismiss != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Cerrar mensaje',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDismiss,
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.color,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

({Color color, IconData icon}) _feedbackColors(
  ThemeData theme,
  AppFeedbackType type,
) {
  return switch (type) {
    AppFeedbackType.error => (
      color: theme.colorScheme.error,
      icon: Icons.error_outline_rounded,
    ),
    AppFeedbackType.warning => (
      color: AppColors.sun,
      icon: Icons.warning_amber_rounded,
    ),
    AppFeedbackType.info => (
      color: theme.colorScheme.primary,
      icon: Icons.info_outline_rounded,
    ),
    AppFeedbackType.success => (
      color: AppColors.leaf,
      icon: Icons.check_circle_outline_rounded,
    ),
  };
}
