import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/models/itinerary_model.dart';
import '../../../../core/router/safe_navigation.dart';
import '../../../../core/router/app_routes.dart';
import 'cultural_insight_card.dart';
import 'drag_flying_proxy.dart';
import 'itinerary_step_widget.dart';

class GeneratedStep extends StatelessWidget {
  final ItineraryStepModel step;
  final bool isEditable;
  final bool isSavingReorder;
  final VoidCallback onDelete;
  final VoidCallback onChange;
  final VoidCallback onReschedule;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;
  final void Function(DragUpdateDetails)? onDragUpdate;

  const GeneratedStep({
    super.key,
    required this.step,
    required this.isEditable,
    this.isSavingReorder = false,
    required this.onDelete,
    required this.onChange,
    required this.onReschedule,
    this.onDragStarted,
    this.onDragEnded,
    this.onDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final infoParts = <String>[
      if (step.recommendedDuration.isNotEmpty) step.recommendedDuration,
      if (step.poiName != null && step.poiName!.isNotEmpty) step.poiName!,
    ];

    final card = ItineraryStepWidget(
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
                  Padding(
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
                  TextButton.icon(
                    onPressed: onReschedule,
                    icon: const Icon(Icons.schedule_rounded),
                    label: const Text('Horario'),
                  ),
                ],
                if (step.poiId != null)
                  TextButton.icon(
                    onPressed: () => context.pushNamedSafe(
                      AppRouteNames.poiDetail,
                      pathParameters: {'id': step.poiId!},
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

    if (!isEditable || isSavingReorder) return card;
    final childWhenDragging = Opacity(opacity: 0.3, child: card);
    if (_isDesktop) {
      return Draggable<ItineraryStepModel>(
        data: step,
        feedback: DragFlyingProxy(step: step),
        dragAnchorStrategy: _centeredFeedbackAnchor,
        childWhenDragging: childWhenDragging,
        onDragStarted: onDragStarted,
        onDragUpdate: onDragUpdate,
        onDragEnd: (_) => onDragEnded?.call(),
        onDraggableCanceled: (_, _) => onDragEnded?.call(),
        child: card,
      );
    }
    return LongPressDraggable<ItineraryStepModel>(
      delay: const Duration(milliseconds: 250),
      data: step,
      feedback: DragFlyingProxy(step: step),
      dragAnchorStrategy: _centeredFeedbackAnchor,
      childWhenDragging: childWhenDragging,
      onDragStarted: onDragStarted,
      onDragUpdate: onDragUpdate,
      onDragEnd: (_) => onDragEnded?.call(),
      onDraggableCanceled: (_, _) => onDragEnded?.call(),
      child: card,
    );
  }

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
