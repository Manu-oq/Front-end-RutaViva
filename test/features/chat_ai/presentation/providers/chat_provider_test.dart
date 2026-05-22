import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ruta_viva/features/chat_ai/data/models/ara_session_model.dart';
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
      expect(greeting.actions, isNotEmpty);
      expect(greeting.actions.length, equals(3));
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
}
