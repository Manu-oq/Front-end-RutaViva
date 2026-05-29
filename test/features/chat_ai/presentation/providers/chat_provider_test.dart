import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ruta_viva/core/error/api_exception.dart';
import 'package:ruta_viva/core/network/dio_client.dart';
import 'package:ruta_viva/core/storage/local_storage_provider.dart';
import 'package:ruta_viva/features/chat_ai/data/models/ara_session_model.dart';
import 'package:ruta_viva/features/chat_ai/data/repositories/ara_repository.dart';
import 'package:ruta_viva/features/chat_ai/domain/entities/message_entity.dart';
import 'package:ruta_viva/features/chat_ai/presentation/providers/chat_provider.dart';

void main() {
  group('ChatNotifier estado inicial', () {
    test('build retorna lista con mensaje de saludo', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(chatProvider);

      expect(state, isNotEmpty);
      expect(state.length, equals(1));

      final greeting = state.first;
      expect(greeting.isUser, isFalse);
      expect(greeting.text, contains('Hola'));
      expect(greeting.text, contains('Ara'));
      expect(greeting.actions, isEmpty);
      expect(greeting.actionsLocked, isFalse);
    });

    test('mensaje de saludo tiene acciones no bloqueadas', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final greeting = container.read(chatProvider).first;

      expect(greeting.actionsLocked, isFalse);
      expect(greeting.selectedActionId, isNull);
    });
  });

  group('ChatNotifier getters', () {
    test('isInputLocked es false en estado idle inicial', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);

      expect(notifier.isInputLocked, isFalse);
    });

    test('hasActiveSession es false sin sesión iniciada', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);

      expect(notifier.hasActiveSession, isFalse);
    });

    test('uiState retorna idle en estado inicial', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);

      expect(notifier.uiState, equals(AraChatUiState.idle));
    });

    test('isBusy es false en estado inicial', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);

      expect(notifier.isBusy, isFalse);
    });
  });

  group('mensajes de error UX', () {
    test('convierte invalid candidate selection a mensaje usable', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);

      final message = notifier.readableErrorForTest(
        const ApiException(message: 'Invalid candidate selection.'),
      );

      expect(message, isNot(contains('Invalid candidate selection')));
      expect(message, contains('No pude seleccionar ese lugar'));
    });
  });

  group('sendMessage', () {
    test('con texto vacio retorna false y no modifica el estado', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      final estadoInicial = container.read(chatProvider);

      final result = notifier.sendMessage('   ');

      expect(result, completion(isFalse));
      final estadoFinal = container.read(chatProvider);
      expect(estadoFinal.length, equals(estadoInicial.length));
    });

    test('con texto vacio mantiene isInputLocked en false', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);

      await notifier.sendMessage('');

      expect(notifier.isInputLocked, isFalse);
    });
  });

  group('lockExistingActions', () {
    test('bloquea acciones en mensajes con acciones interactivas', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);

      container.read(chatProvider.notifier).state = [
        MessageEntity(
          text: 'Pregunta',
          isUser: false,
          timestamp: DateTime.now(),
          actions: const [
            MessageAction(label: 'Opcion 1', prompt: 'opcion1'),
            MessageAction(label: 'Opcion 2', prompt: 'opcion2'),
          ],
        ),
      ];

      const action = MessageAction(
        id: 'id1',
        label: 'Opcion 1',
        prompt: 'opcion1',
      );
      notifier.lockExistingActions(action);

      final state = container.read(chatProvider);
      expect(state.first.actionsLocked, isTrue);
    });

    test('establece selectedActionId cuando la accion coincide', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      container.read(chatProvider.notifier).state = [
        MessageEntity(
          text: 'Pregunta',
          isUser: false,
          timestamp: DateTime.now(),
          actions: const [
            MessageAction(
              id: 'id-accion',
              label: 'Seleccionar',
              prompt: 'seleccionar',
            ),
          ],
        ),
      ];

      const action = MessageAction(
        id: 'id-accion',
        label: 'Seleccionar',
        prompt: 'seleccionar',
      );
      notifier.lockExistingActions(action);

      final state = container.read(chatProvider);
      expect(state.first.selectedActionId, equals('id-accion'));
    });

    test('no modifica selectedActionId de mensajes sin la accion', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      container.read(chatProvider.notifier).state = [
        MessageEntity(
          text: 'Pregunta',
          isUser: false,
          timestamp: DateTime.now(),
          actions: const [
            MessageAction(id: 'otra-accion', label: 'Otra', prompt: 'otra'),
          ],
        ),
      ];

      const action = MessageAction(
        id: 'no-existe',
        label: 'No existe',
        prompt: 'no_existe',
      );
      notifier.lockExistingActions(action);

      final state = container.read(chatProvider);
      expect(state.first.actionsLocked, isTrue);
      expect(state.first.selectedActionId, isNull);
    });

    test('no modifica mensajes que ya estan bloqueados', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      container.read(chatProvider.notifier).state = [
        MessageEntity(
          text: 'Pregunta',
          isUser: false,
          timestamp: DateTime.now(),
          actions: const [MessageAction(label: 'Opcion', prompt: 'opcion')],
          actionsLocked: true,
          selectedActionId: 'ya-bloqueado',
        ),
      ];

      const action = MessageAction(
        id: 'nueva',
        label: 'Nueva',
        prompt: 'nueva',
      );
      notifier.lockExistingActions(action);

      final state = container.read(chatProvider);
      expect(state.first.selectedActionId, equals('ya-bloqueado'));
    });

    test('usa prompt como id cuando el id esta vacio', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      container.read(chatProvider.notifier).state = [
        MessageEntity(
          text: 'Pregunta',
          isUser: false,
          timestamp: DateTime.now(),
          actions: const [
            MessageAction(label: 'Opcion', prompt: 'usar-prompt'),
          ],
        ),
      ];

      const action = MessageAction(
        id: '',
        label: 'Opcion',
        prompt: 'usar-prompt',
      );
      notifier.lockExistingActions(action);

      final state = container.read(chatProvider);
      expect(state.first.selectedActionId, equals('usar-prompt'));
    });
  });

  group('buildActions', () {
    test('retorna lista vacia para entrada vacia', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);

      final result = notifier.buildActions([]);

      expect(result, isEmpty);
    });

    test('convierte AraQuickReplyModel en MessageAction', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);

      final replies = [
        const AraQuickReplyModel(
          id: 'qr1',
          label: 'Opcion 1',
          value: 'valor1',
          type: 'refinement',
        ),
        const AraQuickReplyModel(
          id: 'qr2',
          label: 'Opcion 2',
          value: 'valor2',
          type: 'generate',
        ),
      ];

      final result = notifier.buildActions(replies);

      expect(result.length, equals(2));
      expect(result[0].id, equals('qr1'));
      expect(result[0].label, equals('Opcion 1'));
      expect(result[0].prompt, equals('valor1'));
      expect(result[0].type, equals('refinement'));
      expect(result[1].id, equals('qr2'));
      expect(result[1].label, equals('Opcion 2'));
      expect(result[1].prompt, equals('valor2'));
      expect(result[1].type, equals('generate'));
    });

    test('deduplica acciones con el mismo id', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);

      final replies = [
        const AraQuickReplyModel(
          id: 'mismo-id',
          label: 'Primero',
          value: 'valor1',
          type: 'refinement',
        ),
        const AraQuickReplyModel(
          id: 'mismo-id',
          label: 'Segundo',
          value: 'valor2',
          type: 'refinement',
        ),
      ];

      final result = notifier.buildActions(replies);

      expect(result.length, equals(1));
      expect(result.first.label, equals('Primero'));
    });

    test('deduplica acciones por label+prompt+type cuando id esta vacio', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);

      final replies = [
        const AraQuickReplyModel(
          id: '',
          label: 'Opcion',
          value: 'valor',
          type: 'refinement',
        ),
        const AraQuickReplyModel(
          id: '',
          label: 'Opcion',
          value: 'valor',
          type: 'refinement',
        ),
      ];

      final result = notifier.buildActions(replies);

      expect(result.length, equals(1));
    });

    test('no deduplica acciones con distinto id', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);

      final replies = [
        const AraQuickReplyModel(
          id: 'id-a',
          label: 'Opcion',
          value: 'valor',
          type: 'refinement',
        ),
        const AraQuickReplyModel(
          id: 'id-b',
          label: 'Opcion',
          value: 'valor',
          type: 'refinement',
        ),
      ];

      final result = notifier.buildActions(replies);

      expect(result.length, equals(2));
    });

    test('deduplica ids con diferente casing porque aplica toLowerCase', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);

      final replies = [
        const AraQuickReplyModel(
          id: 'Mi-ID',
          label: 'Opcion',
          value: 'valor',
          type: 'refinement',
        ),
        const AraQuickReplyModel(
          id: 'mi-id',
          label: 'Opcion',
          value: 'valor',
          type: 'refinement',
        ),
      ];

      final result = notifier.buildActions(replies);

      expect(result.length, equals(1));
    });
  });

  group('Ara v2 generation signals', () {
    test('turn_type generate_request por si solo no solicita generacion', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      const session = AraSessionModel(
        sessionId: 'session-1',
        status: 'clarifying',
        assistantMessage: AraChatMessageModel(
          role: 'assistant',
          content: 'Dale, puedo armarlo.',
          metadata: {'turn_type': 'generate_request'},
        ),
      );

      expect(notifier.sessionRequestsGenerationForTest(session), isFalse);
    });

    test('status ready_to_generate solicita generacion', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      const session = AraSessionModel(
        sessionId: 'session-1',
        status: 'ready_to_generate',
        assistantMessage: AraChatMessageModel(
          role: 'assistant',
          content: 'Perfecto, lo armo.',
        ),
      );

      expect(notifier.sessionRequestsGenerationForTest(session), isTrue);
    });

    test('trip_draft ready_to_generate solicita generacion', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      const session = AraSessionModel(
        sessionId: 'session-1',
        status: 'clarifying',
        preferences: AraPreferencesModel(
          tripDraft: {'ready_to_generate': true},
        ),
      );

      expect(notifier.sessionRequestsGenerationForTest(session), isTrue);
    });
  });

  group('TripProgressData', () {
    test('fromAraProgress con null retorna datos vacios', () {
      final result = TripProgressData.fromAraProgress(null);

      expect(result.totalDays, equals(0));
      expect(result.currentDayFocus, equals(0));
      expect(result.days, isEmpty);
      expect(result.lodgingName, isNull);
    });

    test('fromAraProgress convierte correctamente dias y lodging', () {
      const progress = AraProgressModel(
        totalDays: 3,
        currentDayFocus: 0,
        days: [
          AraDayProgressModel(
            label: 'Viernes 22',
            date: '2026-05-22',
            dayIndex: 0,
            status: 'in_progress',
            isFocus: true,
            steps: 2,
          ),
          AraDayProgressModel(
            label: 'Sabado 23',
            date: '2026-05-23',
            dayIndex: 1,
            status: 'pending',
            isFocus: false,
            steps: 0,
          ),
        ],
        lodging: AraLodgingModel(
          poiId: 'abc',
          name: 'Hotel Patagonia',
          mode: 'all_days',
        ),
      );

      final result = TripProgressData.fromAraProgress(progress);

      expect(result.totalDays, equals(3));
      expect(result.currentDayFocus, equals(0));
      expect(result.days.length, equals(2));
      expect(result.days[0].label, equals('Viernes 22'));
      expect(result.days[0].status, equals('in_progress'));
      expect(result.days[0].isFocus, isTrue);
      expect(result.days[0].steps, equals(2));
      expect(result.days[1].label, equals('Sabado 23'));
      expect(result.days[1].status, equals('pending'));
      expect(result.days[1].isFocus, isFalse);
      expect(result.lodgingName, equals('Hotel Patagonia'));
    });
  });

  group('isGenerating getter', () {
    test('isGenerating es false en estado idle inicial', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);

      expect(notifier.isGenerating, isFalse);
    });
  });

  group('_phaseIcon', () {
    test('searching retorna lupa', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);

      expect(notifier.phaseIconForTest('searching'), equals('🔍'));
    });

    test('weather retorna nube', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);

      expect(notifier.phaseIconForTest('weather'), equals('🌤'));
    });

    test('generating retorna cerebro', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);

      expect(notifier.phaseIconForTest('generating'), equals('🧠'));
    });

    test('validating retorna check', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);

      expect(notifier.phaseIconForTest('validating'), equals('✓'));
    });

    test('saving retorna disco', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);

      expect(notifier.phaseIconForTest('saving'), equals('💾'));
    });

    test('fase desconocida retorna default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);

      expect(notifier.phaseIconForTest('unknown'), equals('🔄'));
    });
  });

  group('chatProgressProvider', () {
    test('retorna null cuando el notifier no tiene progress', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final progress = container.read(chatProgressProvider);

      expect(progress, isNull);
    });
  });

  group('TripProgressData dias con distintos status', () {
    test('completed y skipped se parsean correctamente', () {
      const progress = AraProgressModel(
        totalDays: 2,
        currentDayFocus: 1,
        days: [
          AraDayProgressModel(
            label: 'Viernes',
            date: '2026-05-22',
            dayIndex: 0,
            status: 'completed',
            isFocus: false,
            steps: 3,
          ),
          AraDayProgressModel(
            label: 'Sabado',
            date: '2026-05-23',
            dayIndex: 1,
            status: 'skipped',
            isFocus: false,
            steps: 0,
          ),
        ],
      );

      final result = TripProgressData.fromAraProgress(progress);

      expect(result.days[0].status, equals('completed'));
      expect(result.days[1].status, equals('skipped'));
    });
  });

  group('selección de candidate POI', () {
    test('construye prompt técnico usando UUID cuando existe', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      const candidate = MessageCandidatePoi(
        id: '123e4567-e89b-12d3-a456-426614174000',
        name: 'Pucón Outdoor',
        actionValue: 'Quiero ir a Pucón Outdoor',
      );

      final prompt = notifier.buildCandidateSelectionPrompt(candidate);

      expect(
        prompt,
        equals('Seleccionar POI 123e4567-e89b-12d3-a456-426614174000'),
      );
    });

    test('usa actionValue solo si no hay UUID', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      const candidate = MessageCandidatePoi(
        id: '',
        name: 'Pucón Outdoor',
        actionValue: 'usar-poi-pucon-outdoor',
      );

      final prompt = notifier.buildCandidateSelectionPrompt(candidate);

      expect(prompt, equals('usar-poi-pucon-outdoor'));
    });
  });

  group('candidate_pois vacíos limpian cards previas', () {
    test(
      'elimina candidatePois antiguos cuando la nueva respuesta no trae POIs',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(chatProvider.notifier);
        container.read(chatProvider.notifier).state = [
          MessageEntity(
            text: 'Opciones anteriores',
            isUser: false,
            timestamp: DateTime.now(),
            candidatePois: const [
              MessageCandidatePoi(id: 'poi-1', name: 'Pucón Outdoor'),
            ],
          ),
        ];

        const session = AraSessionModel(
          sessionId: 'session-1',
          status: 'clarifying',
          assistantMessage: AraChatMessageModel(
            role: 'assistant',
            content: 'Perfecto, tomo esa selección.',
          ),
          candidatePois: [],
        );

        await notifier.replaceThinkingWithSessionForTest(session);

        final state = container.read(chatProvider);
        expect(state.first.candidatePois, isEmpty);
        expect(state.last.text, equals('Perfecto, tomo esa selección.'));
        expect(state.last.candidatePois, isEmpty);
      },
    );
  });

  group('streaming_itinerary', () {
    test(
      'agrega quick reply Ver progreso y agenda inicio automático',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(chatProvider.notifier);
        const session = AraSessionModel(
          sessionId: 'session-1',
          status: 'streaming_itinerary',
          assistantMessage: AraChatMessageModel(
            role: 'assistant',
            content: 'Perfecto, estoy armando tu itinerario...',
          ),
        );

        await notifier.replaceThinkingWithSessionForTest(session);

        final last = container.read(chatProvider).last;
        expect(last.text, equals('Perfecto, estoy armando tu itinerario...'));
        expect(last.actions.any((action) => action.isViewProgress), isTrue);
        expect(notifier.hasPendingStreamingStartForTest, isTrue);
      },
    );

    test(
      'no solicita auto-generation legacy cuando status es streaming_itinerary',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(chatProvider.notifier);
        const session = AraSessionModel(
          sessionId: 'session-1',
          status: 'streaming_itinerary',
        );

        expect(notifier.sessionRequestsGenerationForTest(session), isFalse);
      },
    );

    test('procesa evento status y result del SSE', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = StreamController<AraGenerationStreamEvent>();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          araRepositoryProvider.overrideWith(
            (ref) => _FakeAraRepository(
              streamFactory: ({required sessionId, finalInstruction}) =>
                  controller.stream,
            ),
          ),
        ],
      );
      addTearDown(() async {
        if (!controller.isClosed) {
          await controller.close();
        }
        container.dispose();
      });

      final notifier = container.read(chatProvider.notifier);
      const session = AraSessionModel(
        sessionId: 'session-1',
        status: 'streaming_itinerary',
        assistantMessage: AraChatMessageModel(
          role: 'assistant',
          content: 'Perfecto, estoy armando tu itinerario...',
        ),
      );

      await notifier.replaceThinkingWithSessionForTest(session);

      final future = notifier.startPendingStreamingItinerary();
      await Future<void>.delayed(Duration.zero);

      controller.add(
        const AraGenerationStatusEvent(
          phase: 'generating',
          message: 'Generando itinerario...',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(notifier.streamingProgressForTest?.phase, equals('generating'));
      final progressMessage = container
          .read(chatProvider)
          .lastWhere((message) => message.messageType == 'streaming_progress');
      expect(progressMessage.progressPhase, equals('generating'));

      controller.add(
        AraGenerationResultEvent(
          AraGenerateItineraryResponse.fromJson({
            'session_id': 'session-1',
            'status': 'completed',
            'itinerary': {
              'id': 'iti-1',
              'tourist_id': 'tourist-1',
              'title': 'Ruta Villarrica',
              'status': 'draft',
              'steps': [],
            },
          }),
        ),
      );
      await controller.close();
      await future;

      expect(container.read(chatPendingNavigationProvider), equals('iti-1'));
      expect(
        container
            .read(chatProvider)
            .any((message) => message.messageType == 'streaming_progress'),
        isFalse,
      );
    });

    test('procesa event warning y muestra acciones al usuario', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = StreamController<AraGenerationStreamEvent>();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          araRepositoryProvider.overrideWith(
            (ref) => _FakeAraRepository(
              streamFactory: ({required sessionId, finalInstruction}) =>
                  controller.stream,
            ),
          ),
        ],
      );
      addTearDown(() async {
        if (!controller.isClosed) {
          await controller.close();
        }
        container.dispose();
      });

      final notifier = container.read(chatProvider.notifier);
      const session = AraSessionModel(
        sessionId: 'session-1',
        status: 'streaming_itinerary',
        assistantMessage: AraChatMessageModel(
          role: 'assistant',
          content: 'Perfecto, estoy armando tu itinerario...',
        ),
      );

      await notifier.replaceThinkingWithSessionForTest(session);
      final future = notifier.startPendingStreamingItinerary();
      await Future<void>.delayed(Duration.zero);

      controller.add(
        const AraGenerationWarningEvent(
          message: 'No encontré suficientes lugares. ¿Amplío la búsqueda?',
          quickReplies: [
            AraQuickReplyModel(
              id: 'expand-search',
              label: 'Sí, amplía la búsqueda',
              value: 'Sí, amplía la búsqueda',
              type: 'refinement',
            ),
          ],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final state = container.read(chatProvider);
      final warningMessage = state.lastWhere(
        (message) => message.actions.isNotEmpty,
      );
      expect(warningMessage.text, contains('No encontré suficientes lugares'));
      expect(
        warningMessage.actions.single.label,
        equals('Sí, amplía la búsqueda'),
      );
      expect(
        state.any((message) => message.messageType == 'streaming_progress'),
        isTrue,
      );

      await controller.close();
      await future;
    });
  });
}

class _FakeAraRepository extends AraRepository {
  final Stream<AraGenerationStreamEvent> Function({
    required String sessionId,
    String? finalInstruction,
  })
  streamFactory;

  _FakeAraRepository({required this.streamFactory}) : super(DioClient(Dio()));

  @override
  Stream<AraGenerationStreamEvent> generateItineraryStream({
    required String sessionId,
    String? finalInstruction,
  }) {
    return streamFactory(
      sessionId: sessionId,
      finalInstruction: finalInstruction,
    );
  }
}
