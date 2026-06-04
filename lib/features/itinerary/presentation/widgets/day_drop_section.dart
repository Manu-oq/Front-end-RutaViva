import 'package:flutter/material.dart';
import '../../data/models/itinerary_model.dart';
import 'itinerary_info_banners.dart';

class DayHeader extends StatelessWidget {
  final String label;

  const DayHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
        ],
      ),
    );
  }
}

class DayDropSection extends StatelessWidget {
  final String label;
  final DateTime day;
  final List<ItineraryStepModel> steps;
  final bool isEditable;
  final bool isSavingReorder;
  final void Function(ItineraryStepModel step, DateTime day, int index) onDrop;
  final VoidCallback? onOpenMap;
  final Widget Function(BuildContext context, ItineraryStepModel step)
  stepBuilder;

  const DayDropSection({
    super.key,
    required this.label,
    required this.day,
    required this.steps,
    required this.isEditable,
    required this.isSavingReorder,
    required this.onDrop,
    required this.onOpenMap,
    required this.stepBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DragTarget<ItineraryStepModel>(
      onWillAcceptWithDetails: (_) => isEditable && !isSavingReorder,
      builder: (context, candidateData, rejectedData) {
        final isDragTarget = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDragTarget
                ? theme.colorScheme.primary.withValues(alpha: 0.10)
                : theme.colorScheme.surface.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDragTarget
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: isDragTarget ? 2 : 1,
            ),
            boxShadow: isDragTarget
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSavingReorder) ...[
                const LinearProgressIndicator(minHeight: 3),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(child: DayHeader(label: label)),
                  TextButton.icon(
                    onPressed: onOpenMap,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Ver día'),
                  ),
                ],
              ),
              if (steps.isEmpty)
                StepDropTarget(
                  day: day,
                  index: 0,
                  enabled: isEditable && !isSavingReorder,
                  onDrop: onDrop,
                  child: const EmptyDayCard(),
                )
              else
                for (final entry in steps.indexed) ...[
                  StepDropTarget(
                    day: day,
                    index: entry.$1,
                    enabled: isEditable && !isSavingReorder,
                    onDrop: onDrop,
                    child: const SizedBox(height: 8),
                  ),
                  DraggableStepCard(
                    step: entry.$2,
                    enabled: isEditable && !isSavingReorder,
                    child: stepBuilder(context, entry.$2),
                  ),
                  if (entry.$1 == steps.length - 1)
                    StepDropTarget(
                      day: day,
                      index: steps.length,
                      enabled: isEditable && !isSavingReorder,
                      onDrop: onDrop,
                      child: const SizedBox(height: 8),
                    ),
                ],
            ],
          ),
        );
      },
    );
  }
}

class StepDropTarget extends StatelessWidget {
  final DateTime day;
  final int index;
  final bool enabled;
  final void Function(ItineraryStepModel step, DateTime day, int index) onDrop;
  final Widget child;

  const StepDropTarget({
    super.key,
    required this.day,
    required this.index,
    required this.enabled,
    required this.onDrop,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final theme = Theme.of(context);
    return DragTarget<ItineraryStepModel>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onDrop(details.data, day, index),
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isActive
                ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                : null,
          ),
          child: child,
        );
      },
    );
  }
}

class DraggableStepCard extends StatelessWidget {
  final ItineraryStepModel step;
  final bool enabled;
  final Widget child;

  const DraggableStepCard({
    super.key,
    required this.step,
    required this.enabled,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return LongPressDraggable<ItineraryStepModel>(
      data: step,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Opacity(opacity: 0.92, child: child),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: child),
      child: child,
    );
  }
}
