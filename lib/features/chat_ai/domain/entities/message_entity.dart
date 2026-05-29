class MessageAction {
  final String id;
  final String label;
  final String prompt;
  final String type;

  const MessageAction({
    this.id = '',
    required this.label,
    required this.prompt,
    this.type = 'refinement',
  });

  bool get isGenerate => type == 'generate' || type == 'finalize';

  bool get isViewProgress {
    final normalizedId = id.trim().toLowerCase();
    final normalizedLabel = label.trim().toLowerCase();
    final normalizedPrompt = prompt.trim().toLowerCase();
    return normalizedId == 'view_progress' ||
        normalizedLabel == 'ver progreso' ||
        normalizedPrompt == 'ver progreso';
  }

  bool get isRetryStreaming {
    final normalizedId = id.trim().toLowerCase();
    final normalizedPrompt = prompt.trim().toLowerCase();
    return normalizedId == 'retry_streaming_itinerary' ||
        normalizedPrompt == 'retry_streaming_itinerary';
  }
}

class MessageItineraryCard {
  final String id;
  final String title;
  final int stepsCount;

  const MessageItineraryCard({
    required this.id,
    required this.title,
    required this.stepsCount,
  });
}

class MessageCandidatePoi {
  final String id;
  final String name;
  final String? description;
  final List<int> categoryIds;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final double? distanceMeters;
  final String? actionValue;
  final String? poiRole;

  const MessageCandidatePoi({
    required this.id,
    required this.name,
    this.description,
    this.categoryIds = const [],
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.distanceMeters,
    this.actionValue,
    this.poiRole,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
}

class MessageEntity {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isTyping;
  final String? turnType;
  final String? evidenceLevel;
  final List<MessageAction> actions;
  final MessageItineraryCard? itineraryCard;
  final List<MessageCandidatePoi> candidatePois;
  final String? selectedActionId;
  final bool actionsLocked;
  final String? disclaimerText;
  final String? messageType;
  final String? progressPhase;

  MessageEntity({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isTyping = false,
    this.turnType,
    this.evidenceLevel,
    this.actions = const [],
    this.itineraryCard,
    this.candidatePois = const [],
    this.selectedActionId,
    this.actionsLocked = false,
    this.disclaimerText,
    this.messageType,
    this.progressPhase,
  });

  MessageEntity copyWith({
    List<MessageAction>? actions,
    MessageItineraryCard? itineraryCard,
    bool clearItineraryCard = false,
    List<MessageCandidatePoi>? candidatePois,
    String? selectedActionId,
    bool clearSelectedActionId = false,
    bool? actionsLocked,
    String? disclaimerText,
    bool clearDisclaimerText = false,
    String? messageType,
    bool clearMessageType = false,
    String? progressPhase,
    bool clearProgressPhase = false,
  }) {
    return MessageEntity(
      text: text,
      isUser: isUser,
      timestamp: timestamp,
      isTyping: isTyping,
      turnType: turnType,
      evidenceLevel: evidenceLevel,
      actions: actions ?? this.actions,
      itineraryCard: clearItineraryCard
          ? null
          : (itineraryCard ?? this.itineraryCard),
      candidatePois: candidatePois ?? this.candidatePois,
      selectedActionId: clearSelectedActionId
          ? null
          : (selectedActionId ?? this.selectedActionId),
      actionsLocked: actionsLocked ?? this.actionsLocked,
      disclaimerText: clearDisclaimerText
          ? null
          : (disclaimerText ?? this.disclaimerText),
      messageType: clearMessageType ? null : (messageType ?? this.messageType),
      progressPhase: clearProgressPhase
          ? null
          : (progressPhase ?? this.progressPhase),
    );
  }
}
