import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/models/itinerary_model.dart';
import '../../../../core/router/safe_navigation.dart';
import '../../../../core/router/app_routes.dart';
import 'cultural_insight_card.dart';
import 'itinerary_step_widget.dart';

class GeneratedStep extends StatelessWidget {
  final ItineraryStepModel step;
  final bool isEditable;
  final bool isSavingReorder;
  final VoidCallback onDelete;
  final VoidCallback onChange;
  final VoidCallback onReschedule;

  const GeneratedStep({
    super.key,
    required this.step,
    required this.isEditable,
    this.isSavingReorder = false,
    required this.onDelete,
    required this.onChange,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final infoParts = <String>[
      if (step.recommendedDuration.isNotEmpty) step.recommendedDuration,
      if (step.poiName != null && step.poiName!.isNotEmpty) step.poiName!,
    ];

    return ItineraryStepWidget(
      time: _stepTimeLabel(step),
      description: infoParts.join(' • '),
      child: CulturalInsightCard(
        label: step.title,
        text: step.tips.isNotEmpty
            ? '${step.reason}\n\nConsejo: ${step.tips}'
            : step.reason,
        action: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                if (isEditable) ...[
                  _DragHandle(
                    step: step,
                    enabled: !isSavingReorder,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: isSavingReorder
                            ? theme.colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.38,
                              )
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onReschedule,
                    icon: const Icon(Icons.schedule_rounded),
                    label: const Text('Horario'),
                  ),
                ],
                TextButton.icon(
                  onPressed: () => context.pushNamedSafe(
                    AppRouteNames.poiDetail,
                    pathParameters: {'id': step.poiId},
                  ),
                  icon: const Icon(Icons.place_outlined),
                  label: const Text('Ver lugar'),
                ),
                if (isEditable) ...[
                  TextButton.icon(
                    onPressed: onChange,
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: const Text('Cambiar lugar'),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Eliminar'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _stepTimeLabel(ItineraryStepModel step) {
    final arrival = step.arrivalTime;
    if (arrival == null) {
      return 'Parada ${step.stepOrder}';
    }
    final hour = arrival.hour.toString().padLeft(2, '0');
    final minute = arrival.minute.toString().padLeft(2, '0');
    return '$hour:$minute — Parada ${step.stepOrder}';
  }
}

class _DragHandle extends StatelessWidget {
  final ItineraryStepModel step;
  final bool enabled;
  final Widget child;

  const _DragHandle({
    required this.step,
    required this.enabled,
    required this.child,
  });

  static bool get _isDesktop {
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  static Offset _centeredFeedbackAnchor(
    Draggable<Object> draggable,
    BuildContext context,
    Offset position,
  ) {
    return const Offset(180, 44);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feedback = Material(
      elevation: 16,
      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.28),
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360, minWidth: 280),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.42),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (step.poiName?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          step.poiName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final childWhenDragging = Opacity(opacity: 0.35, child: child);

    if (!enabled) return child;
    if (_isDesktop) {
      return Draggable<ItineraryStepModel>(
        data: step,
        feedback: feedback,
        dragAnchorStrategy: _centeredFeedbackAnchor,
        childWhenDragging: childWhenDragging,
        child: child,
      );
    }
    return LongPressDraggable<ItineraryStepModel>(
      data: step,
      feedback: feedback,
      dragAnchorStrategy: _centeredFeedbackAnchor,
      childWhenDragging: childWhenDragging,
      child: child,
    );
  }
}
