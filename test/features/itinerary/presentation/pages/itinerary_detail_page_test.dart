import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:ruta_viva/core/network/dio_client.dart';
import 'package:ruta_viva/features/itinerary/data/models/itinerary_model.dart';
import 'package:ruta_viva/features/itinerary/data/repositories/itinerary_repository.dart';
import 'package:ruta_viva/features/itinerary/presentation/pages/itinerary_detail_page.dart';

void main() {
  testWidgets('drag step to another day updates state', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    final repo = _ReorderSpyRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itineraryRepositoryProvider.overrideWith((ref) => repo),
          itineraryDetailProvider.overrideWith((ref, itineraryId) async {
            return _itineraryWithTwoDays();
          }),
        ],
        child: const MaterialApp(
          home: ItineraryDetailPage(itineraryId: 'itinerary-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Día 1 — Paso 1'), findsAtLeastNWidgets(1));
    expect(
      find.text(
        'Ara dejó este día libre para descanso, traslado o exploración espontánea.',
      ),
      findsOneWidget,
    );

    final draggable = find
        .byWidgetPredicate((w) => w is LongPressDraggable)
        .first;
    final target = find.text(
      'Ara dejó este día libre para descanso, traslado o exploración espontánea.',
    );

    final gesture = await tester.startGesture(tester.getCenter(draggable));
    await tester.pump();
    await tester.pump(kLongPressTimeout);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text(
        'Ara dejó este día libre para descanso, traslado o exploración espontánea.',
      ),
      findsNothing,
    );
    expect(find.text('Día 1 — Paso 1'), findsAtLeastNWidgets(1));

    repo.completeReorder();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('drag step rejects when not editable', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itineraryDetailProvider.overrideWith((ref, itineraryId) async {
            return _itineraryNotEditable();
          }),
        ],
        child: const MaterialApp(
          home: ItineraryDetailPage(itineraryId: 'itinerary-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Este itinerario está disponible solo para visualización y ya no se puede editar.',
      ),
      findsOneWidget,
    );

    await _scrollToSteps(tester);

    expect(find.text('Paso bloqueado'), findsAtLeastNWidgets(1));
    expect(
      find.byWidgetPredicate((w) => w is LongPressDraggable),
      findsNothing,
    );
  });

  testWidgets('drag step rejects when saving reorder', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    final repo = _ReorderSpyRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itineraryRepositoryProvider.overrideWith((ref) => repo),
          itineraryDetailProvider.overrideWith((ref, itineraryId) async {
            return _itineraryWithTwoDays();
          }),
        ],
        child: const MaterialApp(
          home: ItineraryDetailPage(itineraryId: 'itinerary-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final draggable = find
        .byWidgetPredicate((w) => w is LongPressDraggable)
        .first;
    final target = find.text(
      'Ara dejó este día libre para descanso, traslado o exploración espontánea.',
    );

    final gesture = await tester.startGesture(tester.getCenter(draggable));
    await tester.pump();
    await tester.pump(kLongPressTimeout);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(LinearProgressIndicator), findsAtLeastNWidgets(1));
    expect(
      find.byWidgetPredicate((w) => w is LongPressDraggable),
      findsNothing,
    );

    repo.completeReorder();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('day highlights when drag enters', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itineraryDetailProvider.overrideWith((ref, itineraryId) async {
            return _itineraryWithTwoDays();
          }),
        ],
        child: const MaterialApp(
          home: ItineraryDetailPage(itineraryId: 'itinerary-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Mantén presionada una parada y arrástrala a otro día para reorganizarla.',
      ),
      findsOneWidget,
    );

    expect(
      find.byWidgetPredicate((w) => w is DragTarget),
      findsWidgets,
    );
    expect(
      find.byWidgetPredicate((w) => w is LongPressDraggable),
      findsWidgets,
    );
  });

  testWidgets('save reorder calls correct endpoint', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    final repo = _ReorderSpyRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itineraryRepositoryProvider.overrideWith((ref) => repo),
          itineraryDetailProvider.overrideWith((ref, itineraryId) async {
            return _itineraryWithTwoDays();
          }),
        ],
        child: const MaterialApp(
          home: ItineraryDetailPage(itineraryId: 'itinerary-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final draggable = find
        .byWidgetPredicate((w) => w is LongPressDraggable)
        .first;
    final target = find.text(
      'Ara dejó este día libre para descanso, traslado o exploración espontánea.',
    );

    final gesture = await tester.startGesture(tester.getCenter(draggable));
    await tester.pump();
    await tester.pump(kLongPressTimeout);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repo.calledItineraryId, equals('itinerary-1'));
    expect(repo.calledSteps, isNotNull);
    expect(repo.calledSteps!.length, equals(2));

    final movedStep = repo.calledSteps!.firstWhere(
      (s) => s['step_id'] == 'step-1',
    );
    expect(movedStep['day_index'], equals(2));
    expect(movedStep['position'], equals(0));

    final stayedStep = repo.calledSteps!.firstWhere(
      (s) => s['step_id'] == 'step-2',
    );
    expect(stayedStep['day_index'], equals(1));
    expect(stayedStep['position'], equals(0));

    repo.completeReorder();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('muestra aviso fuera de rango sobre las paradas del día', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itineraryDetailProvider.overrideWith((ref, itineraryId) async {
            return _itineraryWithOutOfRangeStep();
          }),
        ],
        child: const MaterialApp(
          home: ItineraryDetailPage(itineraryId: 'itinerary-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final warning = find.text(
      'Hay una parada con fecha fuera del rango del viaje.',
    );
    final sectionTitle = find.text('Recorrido sugerido');

    expect(warning, findsOneWidget);
    expect(sectionTitle, findsOneWidget);
    expect(
      tester.getTopLeft(warning).dy,
      lessThan(tester.getTopLeft(sectionTitle).dy),
    );
  });

  testWidgets('renderiza paso y muestra acciones de edición', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itineraryDetailProvider.overrideWith((ref, itineraryId) async {
            return _itineraryWithOneStep();
          }),
        ],
        child: const MaterialApp(
          home: ItineraryDetailPage(itineraryId: 'itinerary-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _scrollToSteps(tester);

    expect(find.text('Mirador Test'), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.drag_handle_rounded), findsOneWidget);
    expect(find.text('Horario'), findsOneWidget);
    expect(find.text('Ver lugar'), findsOneWidget);
  });

  testWidgets('botón cambiar lugar inicia chat para reemplazo', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itineraryDetailProvider.overrideWith((ref, itineraryId) async {
            return _itineraryWithOneStep();
          }),
        ],
        child: const MaterialApp(
          home: ItineraryDetailPage(itineraryId: 'itinerary-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _scrollToSteps(tester);

    expect(find.text('Mirador Test'), findsAtLeastNWidgets(1));
    expect(find.text('Cambiar lugar'), findsOneWidget);
  });
}

Future<void> _scrollToSteps(WidgetTester tester) async {
  await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
  await tester.pumpAndSettle();
}

ItineraryModel _itineraryWithOutOfRangeStep() {
  return ItineraryModel(
    id: 'itinerary-1',
    touristId: 'user-1',
    title: 'Ruta de prueba',
    startDate: DateTime(2026, 1, 2),
    endDate: DateTime(2026, 1, 2),
    status: 'planned',
    isEditable: true,
    steps: [
      ItineraryStepModel(
        id: 'step-visible',
        itineraryId: 'itinerary-1',
        poiId: 'poi-visible',
        poiName: 'POI visible',
        stepOrder: 1,
        arrivalTime: DateTime(2026, 1, 2, 9),
        aiContext: const {
          'title': 'Paso del viaje',
          'reason': 'Actividad dentro del rango.',
        },
      ),
      ItineraryStepModel(
        id: 'step-outside',
        itineraryId: 'itinerary-1',
        poiId: 'poi-outside',
        poiName: 'POI fuera de rango',
        stepOrder: 2,
        arrivalTime: DateTime(2026, 1, 1, 9),
        aiContext: const {
          'title': 'Paso fuera de rango',
          'reason': 'Actividad fuera del rango.',
        },
      ),
    ],
  );
}

ItineraryModel _itineraryWithOneStep() {
  return ItineraryModel(
    id: 'itinerary-1',
    touristId: 'user-1',
    title: 'Ruta simple',
    startDate: DateTime(2026, 1, 2),
    endDate: DateTime(2026, 1, 2),
    status: 'planned',
    isEditable: true,
    steps: [
      ItineraryStepModel(
        id: 'step-1',
        itineraryId: 'itinerary-1',
        poiId: 'poi-1',
        poiName: 'Mirador Test',
        stepOrder: 1,
        arrivalTime: DateTime(2026, 1, 2, 10),
        dayDate: DateTime(2026, 1, 2),
        dayIndex: 1,
        aiContext: const {
          'title': 'Mirador Test',
          'reason': 'Buena vista.',
          'tips': 'Llevar agua.',
        },
      ),
    ],
  );
}

ItineraryModel _itineraryWithTwoDays() {
  return ItineraryModel(
    id: 'itinerary-1',
    touristId: 'user-1',
    title: 'Ruta de dos días',
    startDate: DateTime(2026, 1, 2),
    endDate: DateTime(2026, 1, 3),
    status: 'planned',
    isEditable: true,
    steps: [
      ItineraryStepModel(
        id: 'step-1',
        itineraryId: 'itinerary-1',
        poiId: 'poi-1',
        poiName: 'Día 1 — Paso 1',
        stepOrder: 1,
        arrivalTime: DateTime(2026, 1, 2, 9),
        dayDate: DateTime(2026, 1, 2),
        dayIndex: 1,
        aiContext: const {
          'title': 'Día 1 — Paso 1',
          'reason': 'Primer paso del día 1.',
        },
      ),
      ItineraryStepModel(
        id: 'step-2',
        itineraryId: 'itinerary-1',
        poiId: 'poi-2',
        poiName: 'Día 1 — Paso 2',
        stepOrder: 2,
        arrivalTime: DateTime(2026, 1, 2, 15),
        dayDate: DateTime(2026, 1, 2),
        dayIndex: 1,
        aiContext: const {
          'title': 'Día 1 — Paso 2',
          'reason': 'Segundo paso del día 1.',
        },
      ),
    ],
  );
}

ItineraryModel _itineraryNotEditable() {
  return ItineraryModel(
    id: 'itinerary-1',
    touristId: 'user-1',
    title: 'Ruta no editable',
    startDate: DateTime(2026, 1, 2),
    endDate: DateTime(2026, 1, 3),
    status: 'completed',
    isEditable: false,
    steps: [
      ItineraryStepModel(
        id: 'step-1',
        itineraryId: 'itinerary-1',
        poiId: 'poi-1',
        poiName: 'Paso bloqueado',
        stepOrder: 1,
        arrivalTime: DateTime(2026, 1, 2, 9),
        dayDate: DateTime(2026, 1, 2),
        dayIndex: 1,
        aiContext: const {
          'title': 'Paso bloqueado',
          'reason': 'No editable.',
        },
      ),
    ],
  );
}

class _ReorderSpyRepository extends ItineraryRepository {
  final _completer = Completer<ItineraryModel>();
  String? calledItineraryId;
  List<Map<String, dynamic>>? calledSteps;

  _ReorderSpyRepository() : super(DioClient(Dio()));

  @override
  Future<ItineraryModel> reorderStepsWithTimes({
    required String itineraryId,
    required List<Map<String, dynamic>> steps,
  }) {
    calledItineraryId = itineraryId;
    calledSteps = steps;
    return _completer.future;
  }

  void completeReorder() {
    if (_completer.isCompleted) return;
    _completer.complete(
      ItineraryModel(
        id: calledItineraryId ?? 'itinerary-1',
        touristId: 'user-1',
        title: 'Ruta de dos días',
        startDate: DateTime(2026, 1, 2),
        endDate: DateTime(2026, 1, 3),
        status: 'planned',
        isEditable: true,
        steps: [],
      ),
    );
  }
}
