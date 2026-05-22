import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_durations.dart';
import '../providers/chat_provider.dart';

class TripProgressBar extends ConsumerWidget {
  const TripProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(chatProgressProvider);
    final theme = Theme.of(context);

    if (progress == null || progress.totalDays == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (progress.lodgingName != null) ...[
              _LodgingPill(name: progress.lodgingName!, theme: theme),
              const SizedBox(width: 12),
              _Separator(theme: theme),
              const SizedBox(width: 12),
            ],
            for (var i = 0; i < progress.days.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _DayPill(
                day: progress.days[i],
                theme: theme,
                onTap: () => ref
                    .read(chatProvider.notifier)
                    .sendMessage(
                      'Quiero planificar el ${progress.days[i].label.toLowerCase()}',
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LodgingPill extends StatelessWidget {
  final String name;
  final ThemeData theme;

  const _LodgingPill({required this.name, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hotel_rounded, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  final DayProgressData day;
  final ThemeData theme;
  final VoidCallback onTap;

  const _DayPill({required this.day, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = day.isFocus;
    final statusIcon = _statusIcon(day.status);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.medium,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? theme.colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(statusIcon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Text(
              day.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusIcon(String status) {
    return switch (status) {
      'completed' => '●',
      'in_progress' => '◐',
      'skipped' => '—',
      _ => '○',
    };
  }
}

class _Separator extends StatelessWidget {
  final ThemeData theme;

  const _Separator({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      color: theme.dividerColor.withValues(alpha: 0.4),
    );
  }
}
