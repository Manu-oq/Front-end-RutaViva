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
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
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

class DayDropSection extends StatefulWidget {
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
  State<DayDropSection> createState() => _DayDropSectionState();
}

class _DayDropSectionState extends State<DayDropSection> {
  bool _pulseActive = false;

  void _pulse() {
    setState(() => _pulseActive = true);
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => _pulseActive = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DragTarget<ItineraryStepModel>(
      onWillAcceptWithDetails: (_) =>
          widget.isEditable && !widget.isSavingReorder,
      onAcceptWithDetails: widget.steps.isEmpty
          ? (details) {
              _pulse();
              widget.onDrop(details.data, widget.day, 0);
            }
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
                : _pulseActive
                ? theme.colorScheme.primary.withValues(alpha: 0.14)
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
              if (widget.isSavingReorder) ...[
                const LinearProgressIndicator(minHeight: 3),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(child: DayHeader(label: widget.label)),
                  TextButton.icon(
                    onPressed: widget.onOpenMap,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Ver día'),
                  ),
                ],
              ),
              if (widget.steps.isEmpty)
                StepDropTarget(
                  day: widget.day,
                  index: 0,
                  enabled: widget.isEditable && !widget.isSavingReorder,
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
                      for (final entry in widget.steps.indexed) ...[
                        StepDropTarget(
                          day: widget.day,
                          index: entry.$1,
                          enabled: widget.isEditable && !widget.isSavingReorder,
                          onDrop: _dropAt,
                          indicatorAlignment: Alignment.center,
                          child: const SizedBox(height: 36),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.elasticOut,
                          switchOutCurve: Curves.easeInBack,
                          layoutBuilder: (currentChild, previousChildren) {
                            return currentChild ?? const SizedBox.shrink();
                          },
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey('step-card-${entry.$2.id}'),
                            child: widget.stepBuilder(context, entry.$2),
                          ),
                        ),
                        if (entry.$1 == widget.steps.length - 1)
                          StepDropTarget(
                            day: widget.day,
                            index: entry.$1 + 1,
                            enabled:
                                widget.isEditable && !widget.isSavingReorder,
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
    _pulse();
    widget.onDrop(
      movedStep,
      day,
      _effectiveDropIndex(movedStep, requestedIndex),
    );
  }

  int _effectiveDropIndex(ItineraryStepModel movedStep, int requestedIndex) {
    final originalIndex = widget.steps.indexWhere(
      (step) => step.id == movedStep.id,
    );
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
