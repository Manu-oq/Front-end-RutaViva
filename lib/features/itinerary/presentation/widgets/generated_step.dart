import 'package:flutter/material.dart';
import '../../data/models/itinerary_model.dart';
import '../../../../core/router/safe_navigation.dart';
import '../../../../core/router/app_routes.dart';
import 'cultural_insight_card.dart';
import 'itinerary_step_widget.dart';

class GeneratedStep extends StatelessWidget {
  final ItineraryStepModel step;
  final bool isEditable;
  final VoidCallback onDelete;
  final VoidCallback onChange;
  final VoidCallback onReschedule;

  const GeneratedStep({
    super.key,
    required this.step,
    required this.isEditable,
    required this.onDelete,
    required this.onChange,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
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
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.drag_handle_rounded),
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
