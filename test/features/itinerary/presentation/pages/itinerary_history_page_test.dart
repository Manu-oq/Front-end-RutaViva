import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_viva/features/itinerary/data/models/itinerary_model.dart';
import 'package:ruta_viva/features/itinerary/data/repositories/itinerary_repository.dart';
import 'package:ruta_viva/features/itinerary/presentation/pages/itinerary_history_page.dart';

void main() {
  testWidgets('shows delete action for past read-only itinerary', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itineraryHistoryProvider.overrideWith((ref) async {
            return [
              _itinerary(title: 'Ruta pasada', isPast: true, isEditable: false),
            ];
          }),
        ],
        child: const MaterialApp(home: ItineraryHistoryPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ruta pasada'), findsOneWidget);
    expect(find.text('Pasado'), findsOneWidget);

    await tester.tap(find.byTooltip('Opciones de itinerario'));
    await tester.pumpAndSettle();

    expect(find.text('Eliminar'), findsOneWidget);
  });

  testWidgets('shows delete action for editable itinerary', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itineraryHistoryProvider.overrideWith((ref) async {
            return [
              _itinerary(title: 'Ruta futura', isPast: false, isEditable: true),
            ];
          }),
        ],
        child: const MaterialApp(home: ItineraryHistoryPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ruta futura'), findsOneWidget);

    await tester.tap(find.byTooltip('Opciones de itinerario'));
    await tester.pumpAndSettle();

    expect(find.text('Eliminar'), findsOneWidget);
  });
}

ItineraryModel _itinerary({
  required String title,
  required bool isPast,
  required bool isEditable,
}) {
  return ItineraryModel(
    id: 'itinerary-$title',
    touristId: 'user-1',
    title: title,
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 1, 2),
    status: 'planned',
    isPast: isPast,
    isEditable: isEditable,
    steps: const [],
  );
}
