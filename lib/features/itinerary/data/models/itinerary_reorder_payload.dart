import 'itinerary_model.dart';

typedef ItineraryStepDayIndexResolver = int Function(ItineraryStepModel step);

List<Map<String, dynamic>> buildReorderWithTimesPayload({
  required List<ItineraryStepModel> steps,
  required ItineraryStepDayIndexResolver dayIndexForStep,
}) {
  final sorted = [...steps]
    ..sort((a, b) {
      final dayComparison = dayIndexForStep(a).compareTo(dayIndexForStep(b));
      if (dayComparison != 0) {
        return dayComparison;
      }
      return a.stepOrder.compareTo(b.stepOrder);
    });

  final nextPositionByDay = <int, int>{};
  return sorted
      .map((step) {
        final dayIndex = dayIndexForStep(step);
        final position = nextPositionByDay[dayIndex] ?? 0;
        nextPositionByDay[dayIndex] = position + 1;
        return {
          'step_id': step.id,
          'day_index': dayIndex,
          'position': position,
        };
      })
      .toList(growable: false);
}
