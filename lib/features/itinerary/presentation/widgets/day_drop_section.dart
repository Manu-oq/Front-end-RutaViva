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
      onAcceptWithDetails: steps.isEmpty
          ? (details) => onDrop(details.data, day, 0)
          : null,
      builder: (context, candidateData, rejectedData) {
        final isDragTarget = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
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
                  onDrop: _dropAt,
                  child: const EmptyDayCard(),
                )
              else
                AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      for (final entry in steps.indexed) ...[
                        StepDropTarget(
                          day: day,
                          index: entry.$1,
                          enabled: isEditable && !isSavingReorder,
                          onDrop: _dropAt,
                          indicatorAlignment: Alignment.center,
                          child: const SizedBox(height: 36),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: KeyedSubtree(
                            key: ValueKey('step-card-${entry.$2.id}'),
                            child: stepBuilder(context, entry.$2),
                          ),
                        ),
                        if (entry.$1 == steps.length - 1)
                          StepDropTarget(
                            day: day,
                            index: entry.$1 + 1,
                            enabled: isEditable && !isSavingReorder,
                            onDrop: _dropAt,
                            indicatorAlignment: Alignment.center,
                            child: const SizedBox(height: 36),
                          ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _dropAt(ItineraryStepModel movedStep, DateTime day, int requestedIndex) {
    onDrop(movedStep, day, _effectiveDropIndex(movedStep, requestedIndex));
  }

  int _effectiveDropIndex(ItineraryStepModel movedStep, int requestedIndex) {
    final originalIndex = steps.indexWhere((step) => step.id == movedStep.id);
    if (originalIndex < 0 || originalIndex >= requestedIndex) {
      return requestedIndex;
    }
    return requestedIndex - 1;
  }
}

class StepDropTarget extends StatelessWidget {
  final DateTime day;
  final int index;
  final bool enabled;
  final void Function(ItineraryStepModel step, DateTime day, int index) onDrop;
  final Widget child;
  final Alignment indicatorAlignment;

  const StepDropTarget({
    super.key,
    required this.day,
    required this.index,
    required this.enabled,
    required this.onDrop,
    required this.child,
    this.indicatorAlignment = Alignment.center,
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
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            children: [
              child,
              Align(
                alignment: indicatorAlignment,
                child: _DropPositionIndicator(active: isActive),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DropPositionIndicator extends StatelessWidget {
  final bool active;

  const _DropPositionIndicator({required this.active});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: width,
          height: active ? 5 : 0,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}
