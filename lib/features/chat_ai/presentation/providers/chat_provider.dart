import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
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

class TripProgressData {
  final int totalDays;
  final int currentDayFocus;
  final List<DayProgressData> days;
  final String? lodgingName;

  const TripProgressData({
    required this.totalDays,
    required this.currentDayFocus,
    this.days = const [],
    this.lodgingName,
  });

  factory TripProgressData.fromAraProgress(AraProgressModel? p) {
    if (p == null) {
      return const TripProgressData(totalDays: 0, currentDayFocus: 0);
    }
    return TripProgressData(
      totalDays: p.totalDays,
      currentDayFocus: p.currentDayFocus,
      days: p.days
          .map(
            (d) => DayProgressData(
              label: d.label,
              date: d.date,
              dayIndex: d.dayIndex,
              status: d.status,
              isFocus: d.isFocus,
              steps: d.steps,
            ),
          )
          .toList(growable: false),
      lodgingName: p.lodging?.name,
    );
  }
}

class DayProgressData {
  final String label;
  final String date;
  final int dayIndex;
  final String status;
  final bool isFocus;
  final int steps;

  const DayProgressData({
    required this.label,
    required this.date,
    required this.dayIndex,
    required this.status,
    required this.isFocus,
    required this.steps,
  });
}

class ChatStreamingProgressData {
  final String phase;
  final String message;
  final bool isActive;

  const ChatStreamingProgressData({
    required this.phase,
    required this.message,
    required this.isActive,
  });
}

class ChatNotifier extends Notifier<List<MessageEntity>> {
  static const _streamingProgressMessageType = 'streaming_progress';
  static const _viewProgressActionId = 'view_progress';
  static const _retryStreamingActionId = 'retry_streaming_itinerary';

  String? _sessionId;
  DateTime? _sessionStartDate;
  DateTime? _sessionEndDate;
  bool _isBusy = false;
  AraChatUiState _uiState = AraChatUiState.idle;
  TripProgressData? _progress;
  bool _lodgingDisclaimerShown = false;
  final Random _random = Random();
  Timer? _pendingStreamingTimer;
  bool _hasPendingStreamingStart = false;
  bool _isStreamingInBackground = false;
  String? _pendingStreamingFinalInstruction;
  ChatStreamingProgressData? _streamingProgress;
  String? _pendingNavigationItineraryId;
  String? _pendingDirectItineraryNavigationId;

  TripProgressData? get progress => _progress;
  ChatStreamingProgressData? get streamingProgress => _streamingProgress;
  bool get hasPendingStreamingStart => _hasPendingStreamingStart;
  String? get pendingNavigationItineraryId => _pendingNavigationItineraryId;
  String? get pendingDirectItineraryNavigationId =>
      _pendingDirectItineraryNavigationId;

  @override
  List<MessageEntity> build() {
    ref.onDispose(() {
      _pendingStreamingTimer?.cancel();
    });
    return [
      MessageEntity(
        text:
            '¡Hola! Soy Ara. Cuéntame qué viaje quieres hacer, con fechas, destino o ritmo, y te ayudo a armarlo.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }

  bool get isBusy => _isBusy;
  AraChatUiState get uiState => _uiState;
  bool get isGenerating =>
      _uiState == AraChatUiState.generatingItinerary ||
      _uiState == AraChatUiState.pollingGeneration;
  bool get isInputLocked =>
      _uiState == AraChatUiState.sendingMessage ||
      _uiState == AraChatUiState.araTyping ||
      (_uiState == AraChatUiState.generatingItinerary &&
          !_isStreamingInBackground) ||
      (_uiState == AraChatUiState.pollingGeneration &&
          !_isStreamingInBackground);
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
          .sendMessage(
            sessionId: _sessionId!,
            message: message,
            startDate: _sessionStartDate,
            endDate: _sessionEndDate,
          );
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
    lockExistingActions(action);
    return sendMessage(action.prompt, visibleText: _visibleActionText(action));
  }

  Future<void> startPendingStreamingItinerary() async {
    if (!_hasPendingStreamingStart || _isStreamingInBackground) {
      return;
    }
    _pendingStreamingTimer?.cancel();
    _pendingStreamingTimer = null;
    _hasPendingStreamingStart = false;
    _isBusy = true;
    await _runItineraryGeneration(
      finalInstruction: _pendingStreamingFinalInstruction,
      navigateOnComplete: true,
      backgroundMode: true,
    );
  }

  Future<void> retryStreamingItinerary() async {
    if (_sessionId == null || _isStreamingInBackground) {
      return;
    }
    _pendingStreamingTimer?.cancel();
    _pendingStreamingTimer = null;
    _hasPendingStreamingStart = false;
    _isBusy = true;
    await _runItineraryGeneration(
      finalInstruction: _pendingStreamingFinalInstruction,
      navigateOnComplete: true,
      backgroundMode: true,
    );
  }

  void consumePendingNavigation() {
    if (_pendingNavigationItineraryId == null) {
      return;
    }
    _pendingNavigationItineraryId = null;
    state = [...state];
  }

  void consumePendingDirectItineraryNavigation() {
    if (_pendingDirectItineraryNavigationId == null) {
      return;
    }
    _pendingDirectItineraryNavigationId = null;
    state = [...state];
  }

  Future<bool> handleCandidateSelection(MessageCandidatePoi candidate) {
    final prompt = buildCandidateSelectionPrompt(candidate);
    final visibleText = _candidateSelectionVisibleText(candidate);
    return sendMessage(prompt, visibleText: visibleText);
  }

  String _visibleMessageText(String payload, {String? visibleText}) {
    final visible = visibleText?.trim();
    if (visible != null && visible.isNotEmpty) {
      return visible;
    }
    return payload;
  }

  @visibleForTesting
  String buildCandidateSelectionPrompt(MessageCandidatePoi candidate) {
    final candidateId = candidate.id.trim();
    if (candidateId.isNotEmpty) {
      return candidateId;
    }

    final actionValue = candidate.actionValue?.trim();
    if (actionValue != null && actionValue.isNotEmpty) {
      return actionValue;
    }

    return 'Quiero ir a ${candidate.name}';
  }

  String _candidateSelectionVisibleText(MessageCandidatePoi candidate) {
    final name = candidate.name.trim();
    return name.isEmpty ? 'Seleccioné este lugar' : 'Seleccioné $name';
  }

  String? _visibleActionText(MessageAction action) {
    final label = action.label.trim();
    final prompt = action.prompt.trim();
    if (label.isEmpty || label == prompt) {
      return null;
    }

    return label;
  }

  @visibleForTesting
  void lockExistingActions(MessageAction selectedAction) {
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

  Future<String?> generateItinerary({String? finalInstruction}) async {
    if (_sessionId == null || _isBusy) return null;
    _pendingStreamingTimer?.cancel();
    _hasPendingStreamingStart = false;
    _pendingStreamingFinalInstruction = finalInstruction?.trim();
    _isBusy = true;
    return _runItineraryGeneration(finalInstruction: finalInstruction);
  }

  Future<String?> _runItineraryGeneration({
    String? finalInstruction,
    bool navigateOnComplete = false,
    bool backgroundMode = false,
  }) async {
    _uiState = AraChatUiState.generatingItinerary;
    _isStreamingInBackground = backgroundMode;
    _setStreamingProgress(
      phase: 'searching',
      message: 'Buscando lugares...',
      appendIfMissing: true,
    );

    try {
      AraGenerateItineraryResponse? response;
      await for (final event
          in ref
              .read(araRepositoryProvider)
              .generateItineraryStream(
                sessionId: _sessionId!,
                finalInstruction: finalInstruction,
              )) {
        switch (event) {
          case AraGenerationStatusEvent():
            _setStreamingProgress(
              phase: event.phase,
              message: event.message.trim().isEmpty
                  ? 'Ara está armando tu itinerario...'
                  : event.message.trim(),
            );
          case AraGenerationWarningEvent():
            final warningText = event.message.trim().isEmpty
                ? 'Ara necesita confirmar cómo seguir con tu itinerario.'
                : event.message.trim();
            state = [
              ...[
                for (final message in state)
                  if (!message.isTyping) message,
              ],
              MessageEntity(
                text: '⚠️ $warningText',
                isUser: false,
                timestamp: DateTime.now(),
                actions: buildActions(event.quickReplies),
              ),
              ...[
                for (final message in state)
                  if (message.isTyping &&
                      message.messageType == _streamingProgressMessageType)
                    message,
              ],
            ];
          case AraGenerationResultEvent():
            response = event.response;
          case AraGenerationErrorEvent():
            throw ApiException(message: event.message);
        }
      }
      if (response == null) {
        throw const ApiException(
          message: 'Ara no entregó un itinerario al finalizar.',
        );
      }
      final itinerary = await _resolveStreamResultItinerary(response);
      ref.read(itineraryProvider.notifier).setCurrent(itinerary);
      _uiState = AraChatUiState.idle;
      _isBusy = false;
      _isStreamingInBackground = false;
      _streamingProgress = null;
      if (navigateOnComplete) {
        _pendingNavigationItineraryId = itinerary.id;
      }
      state = [
        for (final message in state)
          if (message.messageType != _streamingProgressMessageType) message,
        MessageEntity(
          text: '✅ Listo. Preparé tu itinerario personalizado.',
          isUser: false,
          timestamp: DateTime.now(),
          itineraryCard: MessageItineraryCard(
            id: itinerary.id,
            title: itinerary.title,
            stepsCount: itinerary.steps.length,
          ),
        ),
      ];
      return itinerary.id;
    } catch (error) {
      final readable = _readableGenerationError(error);
      _uiState = AraChatUiState.error;
      _isBusy = false;
      _isStreamingInBackground = false;
      _streamingProgress = null;
      state = [
        for (final message in state)
          if (message.messageType != _streamingProgressMessageType) message,
        MessageEntity(
          text: '❌ $readable',
          isUser: false,
          timestamp: DateTime.now(),
          actions: const [
            MessageAction(
              id: _retryStreamingActionId,
              label: 'Reintentar',
              prompt: 'retry_streaming_itinerary',
              type: 'generate',
            ),
          ],
        ),
      ];
      return null;
    }
  }

  String _phaseIcon(String phase) {
    return switch (phase) {
      'searching' => '🔍',
      'weather' => '🌤',
      'generating' => '🧠',
      'validating' => '✓',
      'saving' => '💾',
      _ => '🔄',
    };
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

  void _setStreamingProgress({
    required String phase,
    required String message,
    bool appendIfMissing = false,
  }) {
    final normalizedPhase = phase.trim().isEmpty ? 'searching' : phase.trim();
    final text = '${_phaseIcon(normalizedPhase)} $message';
    _streamingProgress = ChatStreamingProgressData(
      phase: normalizedPhase,
      message: message,
      isActive: true,
    );

    var replaced = false;
    state = [
      for (final item in state)
        if (item.messageType == _streamingProgressMessageType)
          () {
            replaced = true;
            return MessageEntity(
              text: text,
              isUser: false,
              timestamp: DateTime.now(),
              isTyping: true,
              messageType: _streamingProgressMessageType,
              progressPhase: normalizedPhase,
            );
          }()
        else if (!item.isTyping)
          item
        else
          item,
      if (!replaced && appendIfMissing)
        MessageEntity(
          text: text,
          isUser: false,
          timestamp: DateTime.now(),
          isTyping: true,
          messageType: _streamingProgressMessageType,
          progressPhase: normalizedPhase,
        ),
    ];
  }

  Future<ItineraryModel> _resolveStreamResultItinerary(
    AraGenerateItineraryResponse response,
  ) async {
    if (response.itinerary != null) {
      return response.itinerary!;
    }
    final itineraryId = response.resolvedItineraryId?.trim();
    if (itineraryId != null && itineraryId.isNotEmpty) {
      return ref
          .read(itineraryRepositoryProvider)
          .getItineraryById(itineraryId);
    }
    throw const ApiException(
      message: 'Ara no devolvió un itinerario válido al finalizar.',
    );
  }

  Future<void> _replaceThinkingWithSession(AraSessionModel session) async {
    if (session.sessionId.trim().isNotEmpty) {
      _sessionId = session.sessionId;
    }
    final assistantMessage = session.assistantMessage;
    final assistantText = session.assistantText;
    final turnType = assistantMessage?.turnType?.trim().toLowerCase();
    final normalizedStatus = session.status.trim().toLowerCase();
    final isStepReplacementCompleted = normalizedStatus == 'step_replaced';
    final isStreamingItinerary = normalizedStatus == 'streaming_itinerary';
    _syncSearchCenterIfNeeded(session);
    _syncSessionDates(session);

    if (session.progress != null) {
      _progress = TripProgressData.fromAraProgress(session.progress);
    }

    final updatedItinerary = session.updatedItinerary;
    final replacementItineraryId =
        updatedItinerary?.id ??
        session.assistantMessage?.metadata?['itinerary_id']?.toString() ??
        session.activeItineraryId;
    if (updatedItinerary != null) {
      ref.read(itineraryProvider.notifier).setCurrent(updatedItinerary);
      ref.invalidate(itineraryHistoryProvider);
      ref.invalidate(itineraryDetailProvider(updatedItinerary.id));
      ref.invalidate(itineraryPoisProvider(updatedItinerary.id));
      _refreshFilteredMapIfNeeded(updatedItinerary.id);
    } else if (isStepReplacementCompleted) {
      final itineraryId = replacementItineraryId?.trim();
      if (itineraryId != null && itineraryId.isNotEmpty) {
        ref.invalidate(itineraryHistoryProvider);
        ref.invalidate(itineraryDetailProvider(itineraryId));
        ref.invalidate(itineraryPoisProvider(itineraryId));
        _refreshFilteredMapIfNeeded(itineraryId);
      }
    }
    if (isStepReplacementCompleted) {
      final itineraryId = replacementItineraryId?.trim();
      if (itineraryId != null && itineraryId.isNotEmpty) {
        _pendingDirectItineraryNavigationId = itineraryId;
      }
    }

    if (_sessionResetsTrip(session)) {
      ref.read(itineraryProvider.notifier).clearCurrent();
    }

    _pendingStreamingTimer?.cancel();
    _pendingStreamingTimer = null;
    _hasPendingStreamingStart = false;
    _pendingStreamingFinalInstruction = null;
    _uiState = AraChatUiState.idle;
    _isBusy = false;

    final hasLodgingCandidates = session.candidatePois.any(
      (c) => c.poiRole == 'lodging',
    );
    final showLodgingDisclaimer =
        hasLodgingCandidates && !_lodgingDisclaimerShown;
    if (showLodgingDisclaimer) {
      _lodgingDisclaimerShown = true;
    }

    final nextCandidatePois = isStepReplacementCompleted
        ? const <MessageCandidatePoi>[]
        : _buildCandidatePois(session.candidatePois);
    final shouldClearPreviousCandidatePois = nextCandidatePois.isEmpty;
    final actions = isStepReplacementCompleted
        ? const <MessageAction>[]
        : _actionsForSession(session, status: normalizedStatus);

    state = [
      for (final message in state)
        if (!message.isTyping)
          shouldClearPreviousCandidatePois && message.candidatePois.isNotEmpty
              ? message.copyWith(candidatePois: const [])
              : message,
      if (assistantText.isNotEmpty)
        MessageEntity(
          text: assistantText,
          isUser: false,
          timestamp: DateTime.now(),
          turnType: turnType,
          evidenceLevel: assistantMessage?.evidenceLevel,
          actions: actions,
          itineraryCard: _buildUpdatedItineraryCard(
            updatedItinerary,
            fallbackItineraryId: assistantMessage?.metadata?['itinerary_id']
                ?.toString(),
          ),
          candidatePois: nextCandidatePois,
          disclaimerText: showLodgingDisclaimer
              ? 'Los alojamientos son sugerencias para tu itinerario. Las reservas, precios y disponibilidad las gestionas por tu cuenta. Ruta Viva no realiza reservas ni garantiza disponibilidad.'
              : null,
        ),
    ];

    if (isStreamingItinerary) {
      _pendingStreamingFinalInstruction =
          assistantMessage?.metadata?['final_instruction']?.toString() ??
          session.tripDraft?['final_instruction']?.toString();
      _hasPendingStreamingStart = true;
      _pendingStreamingTimer = Timer(const Duration(seconds: 2), () {
        unawaited(startPendingStreamingItinerary());
      });
      state = [...state];
      return;
    }

    if (_sessionRequestsGeneration(session)) {
      _isBusy = true;
      await _runItineraryGeneration();
    }
  }

  bool _sessionResetsTrip(AraSessionModel session) {
    final status = session.status.trim().toLowerCase();
    final conversationMode =
        session.preferences?.conversationMode?.trim().toLowerCase() ?? '';
    return status == 'reset' ||
        status == 'reset_or_new_trip' ||
        status == 'new_trip' ||
        status == 'session_reset' ||
        conversationMode == 'reset' ||
        conversationMode == 'new_trip';
  }

  bool _sessionRequestsGeneration(AraSessionModel session) {
    if (session.updatedItinerary != null) {
      return false;
    }
    final status = session.status.trim().toLowerCase();
    if (status == 'streaming_itinerary') {
      return false;
    }
    final conversationMode =
        session.preferences?.conversationMode?.trim().toLowerCase() ?? '';
    final tripDraft = session.tripDraft ?? const <String, dynamic>{};

    const generationStatuses = {
      'generate_request',
      'generation_requested',
      'ready_to_generate',
      'ready_for_generation',
      'generating',
      'generating_itinerary',
      'itinerary_generation',
      'auto_generate',
      'auto_generate_requested',
    };
    const generationModes = {
      'generate_request',
      'generation_requested',
      'ready_to_generate',
      'generating',
      'auto_generate',
      'auto_generate_requested',
    };

    if (generationStatuses.contains(status) ||
        generationModes.contains(conversationMode)) {
      return true;
    }

    return _truthy(tripDraft['generate_requested']) ||
        _truthy(tripDraft['auto_generate_requested']) ||
        _truthy(tripDraft['ready_to_generate']);
  }

  bool _truthy(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  void _syncSessionDates(AraSessionModel session) {
    if (session.startDate != null) {
      _sessionStartDate = session.startDate;
    }
    if (session.endDate != null) {
      _sessionEndDate = session.endDate;
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

  @visibleForTesting
  List<MessageAction> buildActions(List<AraQuickReplyModel> replies) {
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
      if (!reply.isValidForUi) {
        debugPrint(
          '[Ara] Ignoring invalid quick reply: '
          'id=${reply.id}, label=${reply.label}, value=${reply.value}, '
          'hasExplicitLabel=${reply.hasExplicitLabel}, '
          'hasExplicitValue=${reply.hasExplicitValue}',
        );
        continue;
      }
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

  List<MessageAction> _actionsForSession(
    AraSessionModel session, {
    required String status,
  }) {
    final actions = buildActions(session.quickReplies);
    if (status != 'streaming_itinerary') {
      return actions;
    }

    final alreadyHasViewProgress = actions.any(
      (action) => action.isViewProgress,
    );
    if (alreadyHasViewProgress) {
      return actions;
    }

    return [
      ...actions,
      const MessageAction(
        id: _viewProgressActionId,
        label: 'Ver progreso',
        prompt: 'ver progreso',
        type: 'navigation',
      ),
    ];
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
            poiRole: candidate.poiRole,
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
    if (error is ApiException) return _friendlyAraMessage(error.message);
    return 'No pude continuar la conversación. Intenta nuevamente.';
  }

  @visibleForTesting
  String readableErrorForTest(Object error) => _readableError(error);

  @visibleForTesting
  String phaseIconForTest(String phase) => _phaseIcon(phase);

  @visibleForTesting
  bool sessionRequestsGenerationForTest(AraSessionModel session) =>
      _sessionRequestsGeneration(session);

  @visibleForTesting
  Future<void> replaceThinkingWithSessionForTest(AraSessionModel session) =>
      _replaceThinkingWithSession(session);

  @visibleForTesting
  bool get hasPendingStreamingStartForTest => _hasPendingStreamingStart;

  @visibleForTesting
  ChatStreamingProgressData? get streamingProgressForTest => _streamingProgress;

  @visibleForTesting
  void setPendingNavigationForTest(String? itineraryId) {
    _pendingNavigationItineraryId = itineraryId;
    state = [...state];
  }

  @visibleForTesting
  void setPendingDirectItineraryNavigationForTest(String? itineraryId) {
    _pendingDirectItineraryNavigationId = itineraryId;
    state = [...state];
  }

  String _readableGenerationError(Object error) {
    if (error is ApiException) {
      final friendly = _friendlyAraMessage(error.message);
      final normalized = friendly.toLowerCase();
      if (normalized.contains('failed') ||
          normalized.contains('generation failed') ||
          normalized.contains('did not return itinerary steps') ||
          normalized.contains('llm returned pois outside')) {
        return 'No pude armar el itinerario esta vez. Intenta ajustar tu búsqueda o vuelve a intentarlo.';
      }
      return friendly;
    }
    return 'No pude armar el itinerario esta vez. Intenta ajustar tu búsqueda o vuelve a intentarlo.';
  }

  String _friendlyAraMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('invalid candidate selection')) {
      return 'No pude seleccionar ese lugar automáticamente. Elige una opción disponible o escribe tu solicitud con más detalle.';
    }
    if (normalized.contains('candidate') && normalized.contains('invalid')) {
      return 'No pude usar esa opción del asistente. Prueba seleccionando nuevamente o escribe lo que quieres hacer.';
    }
    if (normalized.contains('unprocessable entity')) {
      return 'No pude procesar esa solicitud. Revisa la información y vuelve a intentarlo.';
    }
    return message;
  }
}

final chatProvider = NotifierProvider<ChatNotifier, List<MessageEntity>>(
  ChatNotifier.new,
);

final chatProgressProvider = Provider<TripProgressData?>((ref) {
  ref.watch(chatProvider);
  return ref.read(chatProvider.notifier).progress;
});

final chatStreamingProgressProvider = Provider<ChatStreamingProgressData?>((
  ref,
) {
  ref.watch(chatProvider);
  return ref.read(chatProvider.notifier).streamingProgress;
});

final chatPendingNavigationProvider = Provider<String?>((ref) {
  ref.watch(chatProvider);
  return ref.read(chatProvider.notifier).pendingNavigationItineraryId;
});

final chatPendingDirectItineraryNavigationProvider = Provider<String?>((ref) {
  ref.watch(chatProvider);
  return ref.read(chatProvider.notifier).pendingDirectItineraryNavigationId;
});
