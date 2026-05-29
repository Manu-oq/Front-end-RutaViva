import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_viva/features/itinerary/data/models/itinerary_model.dart';
import 'package:ruta_viva/features/itinerary/data/models/itinerary_reorder_payload.dart';

void main() {
  group('buildReorderWithTimesPayload', () {
    test(
      'includes all steps once with 1-based day indexes and 0-based positions',
      () {
        final steps = [
          _step(id: 'day-2-first', stepOrder: 1, dayIndex: 2),
          _step(id: 'day-1-second', stepOrder: 2, dayIndex: 1),
          _step(id: 'day-1-first', stepOrder: 1, dayIndex: 1),
        ];

        final payload = buildReorderWithTimesPayload(
          steps: steps,
          dayIndexForStep: (step) => step.dayIndex!,
        );

        expect(payload, [
          {'step_id': 'day-1-first', 'day_index': 1, 'position': 0},
          {'step_id': 'day-1-second', 'day_index': 1, 'position': 1},
          {'step_id': 'day-2-first', 'day_index': 2, 'position': 0},
        ]);
        expect(payload.map((item) => item['step_id']).toSet(), hasLength(3));
      },
    );
  });
}

ItineraryStepModel _step({
  required String id,
  required int stepOrder,
  required int dayIndex,
}) {
  return ItineraryStepModel(
    id: id,
    itineraryId: 'itinerary-1',
    poiId: 'poi-$id',
    stepOrder: stepOrder,
    dayIndex: dayIndex,
  );
}
