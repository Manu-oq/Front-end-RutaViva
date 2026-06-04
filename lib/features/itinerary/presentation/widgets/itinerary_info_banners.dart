import 'package:flutter/material.dart';
import '../../../../core/widgets/app_feedback.dart';

class ReadOnlyItineraryBanner extends StatelessWidget {
  final bool isPast;

  const ReadOnlyItineraryBanner({super.key, required this.isPast});

  @override
  Widget build(BuildContext context) {
    return AppFeedbackBanner(
      type: AppFeedbackType.info,
      message: isPast
          ? 'Este itinerario ya pasó y solo está disponible para visualización.'
          : 'Este itinerario está disponible solo para visualización y ya no se puede editar.',
    );
  }
}

class EmptyDayCard extends StatelessWidget {
  const EmptyDayCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.free_breakfast_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ara dejó este día libre para descanso, traslado o exploración espontánea.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OutOfRangeWarning extends StatelessWidget {
  final int count;

  const OutOfRangeWarning({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              count == 1
                  ? 'Hay una parada con fecha fuera del rango del viaje.'
                  : 'Hay $count paradas con fecha fuera del rango del viaje.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
