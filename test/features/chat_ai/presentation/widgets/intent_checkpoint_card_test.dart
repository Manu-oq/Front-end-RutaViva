import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ruta_viva/features/chat_ai/data/models/ara_session_model.dart';
import 'package:ruta_viva/features/chat_ai/presentation/providers/chat_provider.dart';
import 'package:ruta_viva/features/chat_ai/presentation/widgets/intent_checkpoint_card.dart';

void main() {
  testWidgets('IntentCheckpointCard oculta ritmo y fechas del checkpoint', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(chatProvider.notifier)
        .replaceThinkingWithSessionForTest(
          const AraSessionModel(
            sessionId: 'session-intent',
            status: 'clarifying',
            preferences: AraPreferencesModel(
              routeReadyScore: 0.62,
              tripDraft: {
                'destination': 'Villarrica',
                'start_date': '2026-06-10',
                'end_date': '2026-06-12',
                'pace': 'moderate',
                'interests': ['naturaleza', 'gastronomía'],
              },
            ),
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: IntentCheckpointCard())),
      ),
    );

    expect(find.text('Villarrica'), findsOneWidget);
    expect(find.text('naturaleza, gastronomía'), findsOneWidget);
    expect(find.textContaining('2026-06'), findsNothing);
    expect(find.textContaining('Ritmo'), findsNothing);
    expect(find.textContaining('moderado'), findsNothing);

    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Destino'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Intereses'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Fecha inicio'), findsNothing);
    expect(find.widgetWithText(TextField, 'Fecha fin'), findsNothing);
    expect(find.textContaining('Ritmo'), findsNothing);
  });
}
