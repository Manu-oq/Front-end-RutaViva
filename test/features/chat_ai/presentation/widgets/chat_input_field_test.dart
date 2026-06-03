import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:ruta_viva/core/network/dio_client.dart';
import 'package:ruta_viva/features/chat_ai/data/models/ara_session_model.dart';
import 'package:ruta_viva/features/chat_ai/data/repositories/ara_repository.dart';
import 'package:ruta_viva/features/chat_ai/presentation/providers/chat_provider.dart';
import 'package:ruta_viva/features/chat_ai/presentation/widgets/chat_input_field.dart';

void main() {
  Widget buildSubject(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: ChatInputField())),
    );
  }

  testWidgets('muestra placeholder dinámico desde el contexto del chat', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(chatProvider.notifier)
        .replaceThinkingWithSessionForTest(
          const AraSessionModel(
            sessionId: 'session-1',
            status: 'clarifying',
            preferences: AraPreferencesModel(
              tripDraft: {'destination': 'Villarrica'},
            ),
          ),
        );

    await tester.pumpWidget(buildSubject(container));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.decoration?.hintText,
      equals('¿Qué fechas tienes en mente para Villarrica?'),
    );
  });

  testWidgets('envía fechas elegidas al cambiar rango con sesión activa', (
    tester,
  ) async {
    final repository = _FakeAraRepository();
    final container = ProviderContainer(
      overrides: [araRepositoryProvider.overrideWith((ref) => repository)],
    );
    addTearDown(container.dispose);

    await container
        .read(chatProvider.notifier)
        .replaceThinkingWithSessionForTest(
          const AraSessionModel(
            sessionId: 'session-active',
            status: 'clarifying',
            startDate: null,
            endDate: null,
            assistantMessage: AraChatMessageModel(
              role: 'assistant',
              content: 'Elige fechas.',
            ),
          ),
        );

    await tester.pumpWidget(buildSubject(container));

    await tester.tap(find.byType(ActionChip).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('7 días'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Usar fechas'));
    await tester.pumpAndSettle();

    expect(repository.lastSessionId, equals('session-active'));
    expect(repository.lastMessage, startsWith('Voy a ir del '));
    expect(repository.lastStartDate, isNotNull);
    expect(repository.lastEndDate, isNotNull);
    expect(
      repository.lastEndDate!.difference(repository.lastStartDate!).inDays,
      equals(6),
    );
  });

  testWidgets('bloquea input mientras se envía un mensaje inicial', (
    tester,
  ) async {
    final repository = _FakeAraRepository(blockCreateSession: true);
    final container = ProviderContainer(
      overrides: [araRepositoryProvider.overrideWith((ref) => repository)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildSubject(container));
    await tester.enterText(find.byType(TextField), 'Quiero ir a Pucón');
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pump();

    final fieldWhileSubmitting = tester.widget<TextField>(
      find.byType(TextField),
    );
    expect(fieldWhileSubmitting.enabled, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.completeCreateSession();
    await tester.pumpAndSettle();

    final fieldAfterSubmit = tester.widget<TextField>(find.byType(TextField));
    expect(fieldAfterSubmit.enabled, isTrue);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

class _FakeAraRepository extends AraRepository {
  final bool blockCreateSession;
  final Completer<AraSessionModel> _createSessionCompleter =
      Completer<AraSessionModel>();

  String? lastSessionId;
  String? lastMessage;
  DateTime? lastStartDate;
  DateTime? lastEndDate;

  _FakeAraRepository({this.blockCreateSession = false})
    : super(DioClient(Dio()));

  @override
  Future<AraSessionModel> createSession({
    required String initialMessage,
    required LatLng center,
    required double radius,
    required DateTime startDate,
    required DateTime endDate,
    Map<String, dynamic>? metadata,
  }) async {
    lastMessage = initialMessage;
    lastStartDate = startDate;
    lastEndDate = endDate;
    if (blockCreateSession) {
      return _createSessionCompleter.future;
    }
    return AraSessionModel(
      sessionId: 'created-session',
      status: 'clarifying',
      startDate: startDate,
      endDate: endDate,
      assistantMessage: const AraChatMessageModel(
        role: 'assistant',
        content: 'Listo.',
      ),
    );
  }

  @override
  Future<AraSessionModel> sendMessage({
    required String sessionId,
    required String message,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    lastSessionId = sessionId;
    lastMessage = message;
    lastStartDate = startDate;
    lastEndDate = endDate;
    return AraSessionModel(
      sessionId: sessionId,
      status: 'clarifying',
      startDate: startDate,
      endDate: endDate,
      assistantMessage: const AraChatMessageModel(
        role: 'assistant',
        content: 'Fechas actualizadas.',
      ),
    );
  }

  void completeCreateSession() {
    if (_createSessionCompleter.isCompleted) return;
    _createSessionCompleter.complete(
      AraSessionModel(
        sessionId: 'created-session',
        status: 'clarifying',
        startDate: lastStartDate,
        endDate: lastEndDate,
        assistantMessage: const AraChatMessageModel(
          role: 'assistant',
          content: 'Listo.',
        ),
      ),
    );
  }
}
