import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/error/api_exception.dart';
import '../../../itinerary/data/models/itinerary_model.dart';
import '../../../itinerary/presentation/providers/itinerary_provider.dart';
import '../../../itinerary/data/repositories/itinerary_repository.dart';
import '../../../map/data/repositories/poi_repository.dart';
import '../../../map/presentation/providers/map_provider.dart';
import '../../data/models/ara_session_model.dart';
import '../../data/repositories/ara_repository.dart';
import '../../domain/entities/message_entity.dart';

enum AraChatUiState {
  idle,
  sendingMessage,
  araTyping,
  generatingItinerary,
  pollingGeneration,
  error,
}

class ChatNotifier extends Notifier<List<MessageEntity>> {
  static const _generationPollingInterval = Duration(milliseconds: 2500);
  static const _generationMaxPollingAttempts = 48;

  String? _sessionId;
  DateTime? _sessionStartDate;
  DateTime? _sessionEndDate;
  bool _isBusy = false;
  AraChatUiState _uiState = AraChatUiState.idle;
  final Random _random = Random();

  @override
  List<MessageEntity> build() {
    return [
      MessageEntity(
        text:
            '¡Hola! Soy Ara. Cuéntame qué tipo de recorrido quieres hacer hoy o elige una idea rápida.',
        isUser: false,
        timestamp: DateTime.now(),
        actions: const [
          MessageAction(
            label: 'Elige tú',
            prompt: 'Elige una ruta sorpresa para hoy',
          ),
          MessageAction(
            label: 'Comida local',
            prompt: 'Quiero ver opciones de comida local',
          ),
          MessageAction(
            label: 'Tips de viaje',
            prompt: 'Dame tips de viaje para La Araucanía',
          ),
        ],
      ),
    ];
  }

  bool get isBusy => _isBusy;
  AraChatUiState get uiState => _uiState;
  bool get isInputLocked =>
      _uiState == AraChatUiState.sendingMessage ||
      _uiState == AraChatUiState.araTyping ||
      _uiState == AraChatUiState.generatingItinerary ||
      _uiState == AraChatUiState.pollingGeneration;
  DateTime? get sessionStartDate => _sessionStartDate;
  DateTime? get sessionEndDate => _sessionEndDate;

  Future<bool> startSessionFromHome({
    required String initialMessage,
    required LatLng center,
    double radius = defaultSearchRadiusMeters,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? metadata,
    String? visibleText,
  }) async {
    final text = initialMessage.trim();
    if (text.isEmpty || _isBusy) return false;
    final displayText = _visibleMessageText(text, visibleText: visibleText);

    _sessionId = null;
    final now = DateTime.now();
    final start =
        startDate ??
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final end = endDate ?? start;
    _sessionStartDate = start;
    _sessionEndDate = end;

    _uiState = AraChatUiState.sendingMessage;
    state = [
      for (final item in state)
        if (_hasInteractiveChoices(item) && !item.actionsLocked)
          item.copyWith(actionsLocked: true)
        else
          item,
      MessageEntity(text: displayText, isUser: true, timestamp: DateTime.now()),
      ..._localThinkingMessages(),
    ];
    _isBusy = true;
    _uiState = AraChatUiState.araTyping;

    try {
      final session = await ref
          .read(araRepositoryProvider)
          .createSession(
            initialMessage: text,
            center: center,
            radius: radius,
            startDate: start,
            endDate: end,
            metadata: metadata,
          );
      _sessionId = session.sessionId;
      await _replaceThinkingWithSession(session);
      return true;
    } catch (error) {
      _replaceThinkingWithError(_readableError(error));
      return false;
    } finally {
      _isBusy = false;
      if (_uiState != AraChatUiState.error) {
        _uiState = AraChatUiState.idle;
      }
    }
  }

  bool get hasActiveSession => _sessionId != null;

  Future<bool> sendMessage(
    String text, {
    DateTime? startDate,
    DateTime? endDate,
    String? visibleText,
  }) async {
    final message = text.trim();
    if (message.isEmpty || _isBusy) return false;
    final displayText = _visibleMessageText(message, visibleText: visibleText);

    if (_sessionId == null) {
      return startSessionFromHome(
        initialMessage: message,
        center: ref.read(mapProvider).center,
        startDate: startDate,
        endDate: endDate,
        visibleText: displayText,
      );
    }

    _uiState = AraChatUiState.sendingMessage;
    state = [
      for (final item in state)
        if (_hasInteractiveChoices(item) && !item.actionsLocked)
          item.copyWith(actionsLocked: true)
        else
          item,
      MessageEntity(text: displayText, isUser: true, timestamp: DateTime.now()),
      ..._localThinkingMessages(),
    ];
    _isBusy = true;
    _uiState = AraChatUiState.araTyping;

    try {
      final session = await ref
          .read(araRepositoryProvider)
          .sendMessage(sessionId: _sessionId!, message: message);
      _sessionId = session.sessionId.isEmpty ? _sessionId : session.sessionId;
      await _replaceThinkingWithSession(session);
      return true;
    } catch (error) {
      _replaceThinkingWithError(_readableError(error));
      return false;
    } finally {
      _isBusy = false;
      if (_uiState != AraChatUiState.error) {
        _uiState = AraChatUiState.idle;
      }
    }
  }

  Future<bool> handleAction(MessageAction action) {
    _lockExistingActions(action);
    return sendMessage(action.prompt, visibleText: _visibleActionText(action));
  }

  String _visibleMessageText(String payload, {String? visibleText}) {
    final visible = visibleText?.trim();
    if (visible != null && visible.isNotEmpty) {
      return visible;
    }
    return payload;
  }

  String? _visibleActionText(MessageAction action) {
    final label = action.label.trim();
    final prompt = action.prompt.trim();
    if (label.isEmpty || label == prompt) {
      return null;
    }

    final normalizedPrompt = prompt.toLowerCase();
    final looksTechnical =
        RegExp(
          r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
          caseSensitive: false,
        ).hasMatch(prompt) ||
        normalizedPrompt.startsWith('seleccionar poi') ||
        normalizedPrompt.startsWith('usar poi') ||
        action.type == 'generate' ||
        action.type == 'replace_step' ||
        action.type == 'select_poi';

    return looksTechnical ? label : null;
  }

  void _lockExistingActions(MessageAction selectedAction) {
    final selectedId = selectedAction.id.trim().isNotEmpty
        ? selectedAction.id.trim()
        : selectedAction.prompt;
    state = [
      for (final message in state)
        if (_hasInteractiveChoices(message) && !message.actionsLocked)
          message.copyWith(
            actionsLocked: true,
            selectedActionId: message.actions.contains(selectedAction)
                ? selectedId
                : message.selectedActionId,
          )
        else
          message,
    ];
  }

  bool _hasInteractiveChoices(MessageEntity message) {
    return message.actions.isNotEmpty || message.candidatePois.isNotEmpty;
  }

  Future<bool> generateItinerary({String? finalInstruction}) async {
    if (_sessionId == null || _isBusy) return false;
    _isBusy = true;
    return _runItineraryGeneration(finalInstruction: finalInstruction);
  }

  Future<bool> _runItineraryGeneration({String? finalInstruction}) async {
    _uiState = AraChatUiState.generatingItinerary;
    final typing = MessageEntity(
      text:
          'Ara está armando tu itinerario…\nPuedes seguir navegando mientras preparo la ruta.',
      isUser: false,
      timestamp: DateTime.now(),
      isTyping: true,
    );
    state = [...state, typing];

    try {
      await ref
          .read(araRepositoryProvider)
          .startItineraryGenerationAsync(
            sessionId: _sessionId!,
            finalInstruction: finalInstruction,
          );
      _uiState = AraChatUiState.pollingGeneration;
      final response = await _pollGeneratedItinerary(_sessionId!);
      ref.read(itineraryProvider.notifier).setCurrent(response.itinerary);
      _uiState = AraChatUiState.idle;
      _isBusy = false;
      state = [
        for (final message in state)
          if (!identical(message, typing)) message,
        MessageEntity(
          text: 'Listo. Preparé tu itinerario personalizado.',
          isUser: false,
          timestamp: DateTime.now(),
          itineraryCard: MessageItineraryCard(
            id: response.itinerary.id,
            title: response.itinerary.title,
            stepsCount: response.itinerary.steps.length,
          ),
        ),
      ];
      return true;
    } catch (error) {
      final readable = _readableGenerationError(error);
      _uiState = AraChatUiState.error;
      _isBusy = false;
      state = [
        for (final message in state)
          if (!identical(message, typing)) message,
        MessageEntity(
          text: readable,
          isUser: false,
          timestamp: DateTime.now(),
          actions: const [
            MessageAction(
              label: 'Reintentar',
              prompt: 'Haz una ruta sorpresa equilibrada',
              type: 'generate',
            ),
          ],
        ),
      ];
      return false;
    }
  }

  Future<AraGenerateItineraryResponse> _pollGeneratedItinerary(
    String sessionId,
  ) async {
    var transientFailures = 0;
    for (var attempt = 0; attempt < _generationMaxPollingAttempts; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(_generationPollingInterval);
      }

      late final AraItineraryGenerationStatus status;
      try {
        status = await ref
            .read(araRepositoryProvider)
            .getGenerationStatus(sessionId: sessionId);
        transientFailures = 0;
      } catch (error) {
        transientFailures++;
        if (transientFailures <= 3) {
          continue;
        }
        rethrow;
      }
      final normalized = status.status.trim().toLowerCase();

      if (normalized == 'queued' || normalized == 'generating') {
        continue;
      }

      if (normalized == 'completed') {
        final itinerary =
            status.itinerary ??
            await _fetchGeneratedItinerary(status.generatedItineraryId);
        if (itinerary == null) {
          throw const ApiException(
            message:
                'Ara terminó la generación, pero no recibimos el itinerario.',
          );
        }
        return AraGenerateItineraryResponse(
          sessionId: status.sessionId,
          status: status.status,
          itinerary: itinerary,
        );
      }

      if (normalized == 'failed') {
        throw ApiException(
          message:
              status.detail ??
              'No pude armar el itinerario esta vez. Intenta ajustar tu búsqueda o vuelve a intentarlo.',
        );
      }
    }

    throw const ApiException(
      message:
          'Ara sigue preparando tu itinerario. Vuelve a intentarlo en unos segundos.',
    );
  }

  Future<ItineraryModel?> _fetchGeneratedItinerary(String? itineraryId) {
    if (itineraryId == null || itineraryId.trim().isEmpty) {
      return Future<ItineraryModel?>.value(null);
    }
    return ref.read(itineraryRepositoryProvider).getItineraryById(itineraryId);
  }

  List<MessageEntity> _localThinkingMessages() {
    final now = DateTime.now();
    const messages = [
      'Estoy buscando lugares para ti…',
      'Déjame revisar las mejores opciones…',
      'Estoy armando un recorrido personalizado…',
    ];
    return [
      MessageEntity(
        text: messages[_random.nextInt(messages.length)],
        isUser: false,
        timestamp: now,
        isTyping: true,
      ),
    ];
  }

  Future<void> _replaceThinkingWithSession(AraSessionModel session) async {
    final assistantMessage = session.assistantMessage;
    final assistantText = assistantMessage?.content.trim() ?? '';
    final turnType = assistantMessage?.turnType?.trim().toLowerCase();
    final normalizedStatus = session.status.trim().toLowerCase();
    final isStepReplacementCompleted = normalizedStatus == 'step_replaced';
    _syncSearchCenterIfNeeded(session);
    final updatedItinerary = session.updatedItinerary;
    if (updatedItinerary != null) {
      ref.read(itineraryProvider.notifier).setCurrent(updatedItinerary);
      ref.invalidate(itineraryHistoryProvider);
      ref.invalidate(itineraryDetailProvider(updatedItinerary.id));
      ref.invalidate(itineraryPoisProvider(updatedItinerary.id));
      _refreshFilteredMapIfNeeded(updatedItinerary.id);
    } else if (isStepReplacementCompleted) {
      final itineraryId = session.assistantMessage?.metadata?['itinerary_id']
          ?.toString();
      if (itineraryId != null && itineraryId.isNotEmpty) {
        ref.invalidate(itineraryHistoryProvider);
        ref.invalidate(itineraryDetailProvider(itineraryId));
        ref.invalidate(itineraryPoisProvider(itineraryId));
        _refreshFilteredMapIfNeeded(itineraryId);
      }
    }

    if (turnType == 'reset_or_new_trip') {
      ref.read(itineraryProvider.notifier).clearCurrent();
    }

    _uiState = AraChatUiState.idle;
    _isBusy = false;
    state = [
      for (final message in state)
        if (!message.isTyping) message,
      if (assistantText.isNotEmpty)
        MessageEntity(
          text: assistantText,
          isUser: false,
          timestamp: DateTime.now(),
          turnType: turnType,
          evidenceLevel: assistantMessage?.evidenceLevel,
          actions: isStepReplacementCompleted
              ? const []
              : _buildActions(session.quickReplies),
          itineraryCard: _buildUpdatedItineraryCard(
            updatedItinerary,
            fallbackItineraryId: assistantMessage?.metadata?['itinerary_id']
                ?.toString(),
          ),
          candidatePois: isStepReplacementCompleted
              ? const []
              : _buildCandidatePois(session.candidatePois),
        ),
    ];

    if (turnType == 'generate_request') {
      final instruction = session.userMessage?.content.trim().isNotEmpty == true
          ? session.userMessage!.content
          : 'Haz una ruta sorpresa equilibrada';
      _isBusy = true;
      await _runItineraryGeneration(finalInstruction: instruction);
    }
  }

  void _syncSearchCenterIfNeeded(AraSessionModel session) {
    final searchCenter = session.searchCenter;
    if (searchCenter == null) {
      return;
    }

    final mapState = ref.read(mapProvider);
    if (!mapState.isGlobalMode || mapState.isLoading) {
      return;
    }

    final center = LatLng(searchCenter.lat, searchCenter.lon);
    final alreadyCentered =
        (mapState.center.latitude - center.latitude).abs() < 0.001 &&
        (mapState.center.longitude - center.longitude).abs() < 0.001;
    if (alreadyCentered) {
      return;
    }

    Future.microtask(() {
      ref.read(mapProvider.notifier).loadNearby(center: center);
    });
  }

  void _refreshFilteredMapIfNeeded(String itineraryId) {
    if (ref.read(mapProvider).filteredItineraryId != itineraryId) {
      return;
    }
    Future.microtask(() async {
      try {
        final points = await ref.read(
          itineraryPoisProvider(itineraryId).future,
        );
        ref
            .read(mapProvider.notifier)
            .showItineraryPois(itineraryId: itineraryId, points: points);
      } catch (_) {}
    });
  }

  List<MessageAction> _buildActions(List<AraQuickReplyModel> replies) {
    final actions = <MessageAction>[];
    final seen = <String>{};

    void add(MessageAction action) {
      final id = action.id.trim().toLowerCase();
      final key = id.isNotEmpty
          ? id
          : '${action.label.trim().toLowerCase()}|${action.prompt.trim().toLowerCase()}|${action.type.trim().toLowerCase()}';
      if (seen.add(key)) {
        actions.add(action);
      }
    }

    for (final reply in replies) {
      add(
        MessageAction(
          label: reply.label,
          id: reply.id,
          prompt: reply.value,
          type: reply.type,
        ),
      );
    }

    return actions;
  }

  List<MessageCandidatePoi> _buildCandidatePois(
    List<AraCandidatePoiModel> candidates,
  ) {
    final seen = <String>{};
    return [
      for (final candidate in candidates)
        if (candidate.id.trim().isNotEmpty && seen.add(candidate.id))
          MessageCandidatePoi(
            id: candidate.id,
            name: candidate.name,
            description: candidate.description,
            categoryIds: candidate.categoryIds,
            latitude: candidate.latitude,
            longitude: candidate.longitude,
            imageUrl: candidate.imageUrl,
            distanceMeters: candidate.distanceMeters,
            actionValue: candidate.actionValue,
          ),
    ];
  }

  MessageItineraryCard? _buildUpdatedItineraryCard(
    ItineraryModel? updatedItinerary, {
    String? fallbackItineraryId,
  }) {
    if (updatedItinerary != null) {
      return MessageItineraryCard(
        id: updatedItinerary.id,
        title: updatedItinerary.title,
        stepsCount: updatedItinerary.steps.length,
      );
    }

    final current = ref.read(itineraryProvider).current;
    final itineraryId = fallbackItineraryId?.trim();
    if (current != null &&
        itineraryId != null &&
        itineraryId.isNotEmpty &&
        current.id == itineraryId) {
      return MessageItineraryCard(
        id: current.id,
        title: current.title,
        stepsCount: current.steps.length,
      );
    }

    return null;
  }

  void _replaceThinkingWithError(String message) {
    _uiState = AraChatUiState.error;
    state = [
      for (final item in state)
        if (!item.isTyping) item,
      MessageEntity(text: message, isUser: false, timestamp: DateTime.now()),
    ];
  }

  String _readableError(Object error) {
    if (error is ApiException) return error.message;
    return 'No pude continuar la conversación. Intenta nuevamente.';
  }

  String _readableGenerationError(Object error) {
    if (error is ApiException) {
      final normalized = error.message.toLowerCase();
      if (normalized.contains('failed') ||
          normalized.contains('generation failed')) {
        return 'No pude armar el itinerario esta vez. Intenta ajustar tu búsqueda o vuelve a intentarlo.';
      }
      return error.message;
    }
    return 'No pude armar el itinerario esta vez. Intenta ajustar tu búsqueda o vuelve a intentarlo.';
  }
}

final chatProvider = NotifierProvider<ChatNotifier, List<MessageEntity>>(
  ChatNotifier.new,
);

final chatUiStateProvider = Provider<AraChatUiState>((ref) {
  ref.watch(chatProvider);
  return ref.read(chatProvider.notifier).uiState;
});
