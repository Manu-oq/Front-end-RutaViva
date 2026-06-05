import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_utils.dart';
import '../../data/models/itinerary_model.dart';

class InterDayDragDrawer extends StatelessWidget {
  final bool visible;
  final List<DateTime> days;
  final DateTime? currentDay;
  final bool enabled;
  final void Function(ItineraryStepModel step, DateTime targetDay) onDrop;

  const InterDayDragDrawer({
    super.key,
    required this.visible,
    required this.days,
    required this.currentDay,
    required this.enabled,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targets = days
        .where((day) => currentDay == null || !isSameDay(day, currentDay!))
        .toList(growable: false);
    final width = MediaQuery.sizeOf(context).width.clamp(180.0, 240.0);

    return IgnorePointer(
      ignoring: !visible || !enabled,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(1.08, 0),
        duration: Duration(milliseconds: visible ? 250 : 200),
        curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: Duration(milliseconds: visible ? 250 : 200),
          curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
          child: SafeArea(
            left: false,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: width,
                margin: const EdgeInsets.only(right: 10, top: 12, bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 28,
                      offset: const Offset(-8, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Mover a',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final day in targets) ...[
                      _InterDayTarget(day: day, onDrop: onDrop),
                      if (day != targets.last) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InterDayTarget extends StatelessWidget {
  final DateTime day;
  final void Function(ItineraryStepModel step, DateTime targetDay) onDrop;

  const _InterDayTarget({required this.day, required this.onDrop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DragTarget<ItineraryStepModel>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onDrop(details.data, day),
      builder: (context, candidateData, rejectedData) {
        final active = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(
              alpha: active ? 0.30 : 0.10,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(
                alpha: active ? 0.70 : 0.18,
              ),
              width: active ? 1.6 : 1,
            ),
          ),
          child: Text(
            weekdayName(day),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      },
    );
  }
}
