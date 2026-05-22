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
  });

  MessageEntity copyWith({
    List<MessageAction>? actions,
    List<MessageCandidatePoi>? candidatePois,
    String? selectedActionId,
    bool? actionsLocked,
  }) {
    return MessageEntity(
      text: text,
      isUser: isUser,
      timestamp: timestamp,
      isTyping: isTyping,
      turnType: turnType,
      evidenceLevel: evidenceLevel,
      actions: actions ?? this.actions,
      itineraryCard: itineraryCard,
      candidatePois: candidatePois ?? this.candidatePois,
      selectedActionId: selectedActionId ?? this.selectedActionId,
      actionsLocked: actionsLocked ?? this.actionsLocked,
    );
  }
}
