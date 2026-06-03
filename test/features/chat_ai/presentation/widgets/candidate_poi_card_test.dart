import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ruta_viva/features/chat_ai/domain/entities/message_entity.dart';
import 'package:ruta_viva/features/chat_ai/presentation/widgets/candidate_poi_card.dart';

void main() {
  const candidate = MessageCandidatePoi(
    id: 'poi-1',
    name: 'Parque Nacional Villarrica',
    categoryIds: [10],
    latitude: -39.4,
    longitude: -71.9,
    distanceMeters: 1450,
  );

  Widget buildSubject({
    bool actionsLocked = false,
    ValueChanged<MessageCandidatePoi>? onOpenPoi,
    ValueChanged<MessageCandidatePoi>? onShowPoiOnMap,
    ValueChanged<MessageCandidatePoi>? onUseCandidate,
    int? currentDayFocus,
    MessageCandidatePoi value = candidate,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 380,
          child: CandidatePoiCard(
            candidate: value,
            actionsLocked: actionsLocked,
            onOpenPoi: onOpenPoi,
            onShowPoiOnMap: onShowPoiOnMap,
            onUseCandidate: onUseCandidate,
            currentDayFocus: currentDayFocus,
          ),
        ),
      ),
    );
  }

  testWidgets('renderiza nombre, categoría, distancia y acción primaria', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(currentDayFocus: 2));

    expect(find.text('Parque Nacional Villarrica'), findsOneWidget);
    expect(find.text('Parques/Reservas'), findsOneWidget);
    expect(find.text('1.4 km'), findsOneWidget);
    expect(find.text('Agregar al Día 2'), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
  });

  testWidgets('ejecuta acción primaria y respeta bloqueo', (tester) async {
    MessageCandidatePoi? used;

    await tester.pumpWidget(
      buildSubject(onUseCandidate: (candidate) => used = candidate),
    );
    await tester.tap(find.text('Agregar al itinerario'));
    await tester.pump();

    expect(used?.id, equals('poi-1'));

    used = null;
    await tester.pumpWidget(
      buildSubject(actionsLocked: true, onUseCandidate: (c) => used = c),
    );
    await tester.tap(find.text('Agregar al itinerario'));
    await tester.pump();

    expect(used, isNull);
  });

  testWidgets('abre detalle al tocar la card y desde el menú secundario', (
    tester,
  ) async {
    final opened = <String>[];

    await tester.pumpWidget(
      buildSubject(onOpenPoi: (candidate) => opened.add(candidate.id)),
    );

    await tester.tap(find.text('Parque Nacional Villarrica'));
    await tester.pump();
    expect(opened, equals(['poi-1']));

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver detalle'));
    await tester.pumpAndSettle();

    expect(opened, equals(['poi-1', 'poi-1']));
  });

  testWidgets(
    'muestra opción de mapa solo con coordenadas y ejecuta callback',
    (tester) async {
      MessageCandidatePoi? mapped;

      await tester.pumpWidget(
        buildSubject(onShowPoiOnMap: (candidate) => mapped = candidate),
      );
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Ver mapa'), findsNothing);
      expect(find.text('Ver en mapa'), findsOneWidget);

      await tester.tap(find.text('Ver en mapa'));
      await tester.pumpAndSettle();

      expect(mapped?.id, equals('poi-1'));

      await tester.pumpWidget(
        buildSubject(
          value: const MessageCandidatePoi(
            id: 'poi-2',
            name: 'Café local',
            categoryIds: [2],
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Ver detalle'), findsOneWidget);
      expect(find.text('Ver en mapa'), findsNothing);
    },
  );
}
