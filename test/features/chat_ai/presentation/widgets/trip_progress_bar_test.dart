import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ruta_viva/features/chat_ai/data/models/ara_session_model.dart';
import 'package:ruta_viva/features/chat_ai/presentation/providers/chat_provider.dart';
import 'package:ruta_viva/features/chat_ai/presentation/widgets/trip_progress_bar.dart';

void main() {
  testWidgets('TripProgressBar renders when backend sends progress', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(chatProvider.notifier)
        .replaceThinkingWithSessionForTest(
          const AraSessionModel(
            sessionId: 'session-progress',
            status: 'clarifying',
            progress: AraProgressModel(
              totalDays: 2,
              currentDayFocus: 1,
              days: [
                AraDayProgressModel(
                  label: 'Día 1',
                  date: '2026-06-03',
                  dayIndex: 0,
                  status: 'in_progress',
                  isFocus: true,
                  steps: 4,
                ),
                AraDayProgressModel(
                  label: 'Día 2',
                  date: '2026-06-04',
                  dayIndex: 1,
                  status: 'pending',
                  isFocus: false,
                  steps: 0,
                ),
              ],
              lodging: AraLodgingModel(
                name: 'Hotel X',
                plan: 'Todas las noches',
              ),
            ),
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: TripProgressBar())),
      ),
    );

    expect(find.text('Hotel X · Todas las noches'), findsOneWidget);
    expect(find.text('Día 1'), findsOneWidget);
    expect(find.text('Día 2'), findsOneWidget);
  });
}
