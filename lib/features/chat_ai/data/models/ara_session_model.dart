import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/public_text_sanitizer.dart';
import '../../../itinerary/data/models/itinerary_model.dart';

class AraQuickReplyModel {
  final String id;
  final String label;
  final String value;
  final String type;
  final bool hasExplicitLabel;
  final bool hasExplicitValue;

  const AraQuickReplyModel({
    required this.id,
    required this.label,
    required this.value,
    required this.type,
    this.hasExplicitLabel = true,
    this.hasExplicitValue = true,
  });

  factory AraQuickReplyModel.fromJson(Map<String, dynamic> json) {
    final rawLabel = json['label'];
    final rawValue = json['value'];
    final labelText = rawLabel?.toString().trim() ?? '';
    final valueText = rawValue?.toString().trim() ?? '';
    return AraQuickReplyModel(
      id: (json['id'] ?? rawLabel ?? '').toString(),
      label: labelText.isNotEmpty ? labelText : valueText,
      value: valueText.isNotEmpty ? valueText : labelText,
      type: (json['type'] ?? 'refinement').toString(),
      hasExplicitLabel: labelText.isNotEmpty,
      hasExplicitValue: valueText.isNotEmpty,
    );
  }

  bool get isValidForUi => hasExplicitLabel && hasExplicitValue;
}

class AraChatMessageModel {
  final String role;
  final String content;
  final Map<String, dynamic>? metadata;
  final List<AraQuickReplyModel> quickReplies;

  const AraChatMessageModel({
    required this.role,
    required this.content,
    this.metadata,
    this.quickReplies = const [],
  });

  factory AraChatMessageModel.fromJson(Map<String, dynamic>? json) {
    return AraChatMessageModel(
      role: (json?['role'] ?? 'assistant').toString(),
      content: (json?['content'] ?? '').toString(),
      metadata: _readMap(json?['metadata']),
      quickReplies: (json?['quick_replies'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map(
            (item) =>
                AraQuickReplyModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
    );
  }

  String? get turnType => metadata?['turn_type']?.toString();
  String? get evidenceLevel => metadata?['evidence_level']?.toString();
  String? get topic => metadata?['topic']?.toString();
  String? get usedContext => metadata?['used_context']?.toString();

  static Map<String, dynamic>? _readMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }
}

class AraSearchCenterModel {
  final double lat;
  final double lon;
  final String? label;
  final String? source;

  const AraSearchCenterModel({
    required this.lat,
    required this.lon,
    this.label,
    this.source,
  });

  static AraSearchCenterModel? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    final lat = _readDouble(json, ['lat', 'latitude']);
    final lon = _readDouble(json, ['lon', 'lng', 'longitude']);
    if (lat == null || lon == null) return null;

    final center = AraSearchCenterModel(
      lat: lat,
      lon: lon,
      label: _readString(json, ['label', 'name']),
      source: _readString(json, ['source']),
    );
    return center.isValid ? center : null;
  }

  factory AraSearchCenterModel.fromJson(Map<String, dynamic> json) {
    return AraSearchCenterModel(
      lat: _readDouble(json, ['lat', 'latitude']) ?? 0,
      lon: _readDouble(json, ['lon', 'lng', 'longitude']) ?? 0,
      label: _readString(json, ['label', 'name']),
      source: _readString(json, ['source']),
    );
  }

  bool get isValid =>
      lat >= -90 &&
      lat <= 90 &&
      lon >= -180 &&
      lon <= 180 &&
      (lat != 0 || lon != 0);

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

  static double? _readDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
    }
    return null;
  }
}

class AraCandidatePoiModel {
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

  const AraCandidatePoiModel({
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

  factory AraCandidatePoiModel.fromJson(Map<String, dynamic> json) {
    final id = _readString(json, ['id', 'poi_id', 'uuid']) ?? '';
    return AraCandidatePoiModel(
      id: id,
      name: _readString(json, ['name', 'title', 'label']) ?? 'Lugar sugerido',
      description: PublicTextSanitizer.cleanOptional(
        _readString(json, ['description', 'summary']),
      ),
      categoryIds: (json['category_ids'] as List<dynamic>? ?? [])
          .map((item) => (item as num).toInt())
          .toList(growable: false),
      latitude: _readDouble(json, ['latitude', 'lat']),
      longitude: _readDouble(json, ['longitude', 'lon', 'lng']),
      imageUrl: ApiConstants.resolveBackendUrl(
        _firstMediaUrl(
          json['multimedia_urls'] ?? json['media'] ?? json['image_url'],
        ),
      ),
      distanceMeters: _readDouble(json, ['distance_meters']),
      actionValue: _readString(json, [
        'action_value',
        'quick_reply_value',
        'value',
        'prompt',
        'message',
      ]),
      poiRole: _readString(json, ['poi_role', 'role']),
    );
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

  static double? _readDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
    }
    return null;
  }

  static String? _firstMediaUrl(dynamic media) {
    if (media is String && media.isNotEmpty) return media;
    if (media is List) {
      for (final item in media) {
        final value = _firstMediaUrl(item);
        if (value != null) return value;
      }
    }
    if (media is Map) {
      for (final key in ['cover', 'image', 'url', 'principal']) {
        final value = media[key];
        if (value is String && value.isNotEmpty) return value;
      }
      for (final value in media.values) {
        final nested = _firstMediaUrl(value);
        if (nested != null) return nested;
      }
    }
    return null;
  }
}

class AraIntentModel {
  final List<String> intents;
  final String? primaryIntent;
  final String? specificity;
  final List<String> locations;
  final int? turnCount;

  const AraIntentModel({
    this.intents = const [],
    this.primaryIntent,
    this.specificity,
    this.locations = const [],
    this.turnCount,
  });

  factory AraIntentModel.fromJson(Map<String, dynamic> json) {
    return AraIntentModel(
      intents: _readStringList(json['intents']),
      primaryIntent: json['primary_intent']?.toString(),
      specificity: json['specificity']?.toString(),
      locations: _readStringList(json['locations']),
      turnCount: (json['turn_count'] as num?)?.toInt(),
    );
  }
}

class AraLodgingModel {
  final String? poiId;
  final String name;
  final dynamic mode;

  const AraLodgingModel({this.poiId, required this.name, this.mode});

  factory AraLodgingModel.fromJson(Map<String, dynamic> json) {
    return AraLodgingModel(
      poiId: json['poi_id']?.toString(),
      name: (json['name'] ?? '').toString(),
      mode: json['mode'],
    );
  }
}

class AraDayProgressModel {
  final String label;
  final String date;
  final int dayIndex;
  final String status;
  final bool isFocus;
  final int steps;

  const AraDayProgressModel({
    required this.label,
    required this.date,
    required this.dayIndex,
    required this.status,
    required this.isFocus,
    required this.steps,
  });

  factory AraDayProgressModel.fromJson(Map<String, dynamic> json) {
    return AraDayProgressModel(
      label: (json['label'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      dayIndex: (json['day_index'] as num? ?? 0).toInt(),
      status: (json['status'] ?? 'pending').toString(),
      isFocus: json['is_focus'] == true,
      steps: (json['steps'] as num? ?? 0).toInt(),
    );
  }
}

class AraProgressModel {
  final int totalDays;
  final int currentDayFocus;
  final List<AraDayProgressModel> days;
  final AraLodgingModel? lodging;

  const AraProgressModel({
    required this.totalDays,
    required this.currentDayFocus,
    this.days = const [],
    this.lodging,
  });

  factory AraProgressModel.fromJson(Map<String, dynamic> json) {
    final rawLodging = json['lodging'];
    return AraProgressModel(
      totalDays: (json['total_days'] as num? ?? 0).toInt(),
      currentDayFocus: (json['current_day_focus'] as num? ?? 0).toInt(),
      days: (json['days'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map(
            (item) =>
                AraDayProgressModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      lodging: rawLodging is Map
          ? AraLodgingModel.fromJson(Map<String, dynamic>.from(rawLodging))
          : null,
    );
  }
}

class AraPreferencesModel {
  final List<String> tags;
  final List<String> positivePreferences;
  final List<String> negativeConstraints;
  final List<String> completedDimensions;
  final Map<String, dynamic>? tripDraft;
  final String? destinationScope;
  final List<String> selectedPoiIds;
  final String? conversationMode;
  final double? routeReadyScore;
  final AraLodgingModel? lodging;
  final int? dayFocus;

  const AraPreferencesModel({
    this.tags = const [],
    this.positivePreferences = const [],
    this.negativeConstraints = const [],
    this.completedDimensions = const [],
    this.tripDraft,
    this.destinationScope,
    this.selectedPoiIds = const [],
    this.conversationMode,
    this.routeReadyScore,
    this.lodging,
    this.dayFocus,
  });

  factory AraPreferencesModel.fromJson(Map<String, dynamic> json) {
    final rawLodging = json['lodging'];
    return AraPreferencesModel(
      tags: _readStringList(json['tags']),
      positivePreferences: _readStringList(json['positive_preferences']),
      negativeConstraints: _readStringList(json['negative_constraints']),
      completedDimensions: _readStringList(json['completed_dimensions']),
      tripDraft: _readMap(json['trip_draft']),
      destinationScope: json['destination_scope']?.toString(),
      selectedPoiIds: _readStringList(json['selected_poi_ids']),
      conversationMode: json['conversation_mode']?.toString(),
      routeReadyScore: _readDoubleValue(json['route_ready_score']),
      lodging: rawLodging is Map
          ? AraLodgingModel.fromJson(Map<String, dynamic>.from(rawLodging))
          : null,
      dayFocus: (json['day_focus'] as num?)?.toInt(),
    );
  }
}

class AraDestinationContextModel {
  final double lat;
  final double lon;
  final String? label;

  const AraDestinationContextModel({
    required this.lat,
    required this.lon,
    this.label,
  });

  static AraDestinationContextModel? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    final lat = _readDoubleFromKeys(json, ['lat', 'latitude']);
    final lon = _readDoubleFromKeys(json, ['lon', 'lng', 'longitude']);
    if (lat == null || lon == null) return null;
    return AraDestinationContextModel(
      lat: lat,
      lon: lon,
      label: json['label']?.toString(),
    );
  }

  AraSearchCenterModel toSearchCenter() {
    return AraSearchCenterModel(lat: lat, lon: lon, label: label);
  }
}

class AraWeatherModel {
  final String? description;
  final double? temperatureC;

  const AraWeatherModel({this.description, this.temperatureC});

  factory AraWeatherModel.fromJson(Map<String, dynamic> json) {
    return AraWeatherModel(
      description: json['description']?.toString(),
      temperatureC: _readDoubleValue(json['temperature_c']),
    );
  }
}

class AraSessionModel {
  final String sessionId;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final AraChatMessageModel? userMessage;
  final AraChatMessageModel? assistantMessage;
  final List<AraQuickReplyModel> quickReplies;
  final List<AraCandidatePoiModel> candidatePois;
  final AraIntentModel? intent;
  final AraPreferencesModel? preferences;
  final String? activeItineraryId;
  final AraDestinationContextModel? destinationContext;
  final AraWeatherModel? weather;
  final AraProgressModel? progress;

  const AraSessionModel({
    required this.sessionId,
    required this.status,
    this.startDate,
    this.endDate,
    this.userMessage,
    this.assistantMessage,
    this.quickReplies = const [],
    this.candidatePois = const [],
    this.intent,
    this.preferences,
    this.activeItineraryId,
    this.destinationContext,
    this.weather,
    this.progress,
  });

  factory AraSessionModel.fromJson(Map<String, dynamic> json) {
    final rawIntent = json['intent'];
    final rawPreferences = json['preferences'];
    final rawWeather = json['weather'];
    final rawProgress = json['progress'];
    return AraSessionModel(
      sessionId: (json['session_id'] ?? '').toString(),
      status: (json['status'] ?? 'clarifying').toString(),
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
      userMessage: json['user_message'] is Map<String, dynamic>
          ? AraChatMessageModel.fromJson(
              json['user_message'] as Map<String, dynamic>,
            )
          : null,
      assistantMessage: json['assistant_message'] is Map<String, dynamic>
          ? AraChatMessageModel.fromJson(
              json['assistant_message'] as Map<String, dynamic>,
            )
          : null,
      quickReplies: (json['quick_replies'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map(
            (item) =>
                AraQuickReplyModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      candidatePois: (json['candidate_pois'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map(
            (item) =>
                AraCandidatePoiModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      intent: rawIntent is Map
          ? AraIntentModel.fromJson(Map<String, dynamic>.from(rawIntent))
          : null,
      preferences: rawPreferences is Map
          ? AraPreferencesModel.fromJson(
              Map<String, dynamic>.from(rawPreferences),
            )
          : null,
      activeItineraryId: json['active_itinerary_id']?.toString(),
      destinationContext: AraDestinationContextModel.tryParse(
        json['destination_context'],
      ),
      weather: rawWeather is Map
          ? AraWeatherModel.fromJson(Map<String, dynamic>.from(rawWeather))
          : null,
      progress: rawProgress is Map
          ? AraProgressModel.fromJson(Map<String, dynamic>.from(rawProgress))
          : null,
    );
  }

  ItineraryModel? get updatedItinerary {
    final raw = assistantMessage?.metadata?['updated_itinerary'];
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    return ItineraryModel.fromJson(raw);
  }

  Map<String, dynamic>? get tripDraft {
    return preferences?.tripDraft;
  }

  AraSearchCenterModel? get searchCenter {
    return destinationContext?.toSearchCenter() ??
        AraSearchCenterModel.tryParse(
          assistantMessage?.metadata?['search_center'],
        ) ??
        AraSearchCenterModel.tryParse(tripDraft?['search_center']);
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  String get assistantText {
    final legacyText = assistantMessage?.content.trim();
    if (legacyText != null && legacyText.isNotEmpty) {
      return legacyText;
    }
    if (candidatePois.isNotEmpty) {
      return 'Encontré ${candidatePois.length} lugares que calzan con tu búsqueda.';
    }
    return '';
  }
}

class AraGenerateItineraryResponse {
  final String sessionId;
  final String status;
  final String? itineraryId;
  final ItineraryModel? itinerary;

  const AraGenerateItineraryResponse({
    required this.sessionId,
    required this.status,
    this.itineraryId,
    required this.itinerary,
  });

  factory AraGenerateItineraryResponse.fromJson(Map<String, dynamic> json) {
    final rawItinerary = json['itinerary'];
    return AraGenerateItineraryResponse(
      sessionId: (json['session_id'] ?? '').toString(),
      status: (json['status'] ?? 'completed').toString(),
      itineraryId: json['itinerary_id']?.toString(),
      itinerary: rawItinerary is Map<String, dynamic>
          ? ItineraryModel.fromJson(rawItinerary)
          : null,
    );
  }

  String? get resolvedItineraryId => itinerary?.id ?? itineraryId;
}

sealed class AraGenerationStreamEvent {
  const AraGenerationStreamEvent();
}

class AraGenerationStatusEvent extends AraGenerationStreamEvent {
  final String phase;
  final String message;

  const AraGenerationStatusEvent({required this.phase, required this.message});

  factory AraGenerationStatusEvent.fromJson(Map<String, dynamic> json) {
    return AraGenerationStatusEvent(
      phase: (json['phase'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
    );
  }
}

class AraGenerationResultEvent extends AraGenerationStreamEvent {
  final AraGenerateItineraryResponse response;

  const AraGenerationResultEvent(this.response);
}

class AraGenerationErrorEvent extends AraGenerationStreamEvent {
  final String message;

  const AraGenerationErrorEvent(this.message);
}

class AraGenerationWarningEvent extends AraGenerationStreamEvent {
  final String message;
  final List<AraQuickReplyModel> quickReplies;

  const AraGenerationWarningEvent({
    required this.message,
    this.quickReplies = const [],
  });

  factory AraGenerationWarningEvent.fromJson(Map<String, dynamic> json) {
    final replies = (json['quick_replies'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map(
          (item) =>
              AraQuickReplyModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);

    if (replies.isNotEmpty) {
      return AraGenerationWarningEvent(
        message: (json['message'] ?? '').toString(),
        quickReplies: replies,
      );
    }

    final actionLabel = json['action_label']?.toString().trim();
    final actionValue = json['action_value']?.toString().trim();
    if (actionLabel != null &&
        actionLabel.isNotEmpty &&
        actionValue != null &&
        actionValue.isNotEmpty) {
      return AraGenerationWarningEvent(
        message: (json['message'] ?? '').toString(),
        quickReplies: [
          AraQuickReplyModel(
            id: (json['action_id'] ?? actionLabel).toString(),
            label: actionLabel,
            value: actionValue,
            type: (json['action_type'] ?? 'refinement').toString(),
          ),
        ],
      );
    }

    return AraGenerationWarningEvent(
      message: (json['message'] ?? '').toString(),
    );
  }
}

List<String> _readStringList(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .where((item) => item != null && item.toString().trim().isNotEmpty)
      .map((item) => item.toString().trim())
      .toList(growable: false);
}

Map<String, dynamic>? _readMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return null;
}

double? _readDoubleValue(dynamic raw) {
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw);
  return null;
}

double? _readDoubleFromKeys(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _readDoubleValue(json[key]);
    if (value != null) return value;
  }
  return null;
}
