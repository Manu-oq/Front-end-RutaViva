import '../../../../core/constants/api_constants.dart';
import '../../../itinerary/data/models/itinerary_model.dart';

class AraQuickReplyModel {
  final String id;
  final String label;
  final String value;
  final String type;

  const AraQuickReplyModel({
    required this.id,
    required this.label,
    required this.value,
    required this.type,
  });

  factory AraQuickReplyModel.fromJson(Map<String, dynamic> json) {
    return AraQuickReplyModel(
      id: (json['id'] ?? json['label'] ?? '').toString(),
      label: (json['label'] ?? json['value'] ?? '').toString(),
      value: (json['value'] ?? json['label'] ?? '').toString(),
      type: (json['type'] ?? 'refinement').toString(),
    );
  }
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
  });

  factory AraCandidatePoiModel.fromJson(Map<String, dynamic> json) {
    final id = _readString(json, ['id', 'poi_id', 'uuid']) ?? '';
    return AraCandidatePoiModel(
      id: id,
      name: _readString(json, ['name', 'title', 'label']) ?? 'Lugar sugerido',
      description: _readString(json, ['description', 'summary']),
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

class AraSessionModel {
  final String sessionId;
  final String status;
  final AraChatMessageModel? userMessage;
  final AraChatMessageModel? assistantMessage;
  final List<AraQuickReplyModel> quickReplies;
  final List<AraCandidatePoiModel> candidatePois;
  final Map<String, dynamic>? preferences;

  const AraSessionModel({
    required this.sessionId,
    required this.status,
    this.userMessage,
    this.assistantMessage,
    this.quickReplies = const [],
    this.candidatePois = const [],
    this.preferences,
  });

  factory AraSessionModel.fromJson(Map<String, dynamic> json) {
    return AraSessionModel(
      sessionId: (json['session_id'] ?? '').toString(),
      status: (json['status'] ?? 'clarifying').toString(),
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
      preferences: _readMap(json['preferences']),
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
    final raw = preferences?['trip_draft'];
    return _readMap(raw);
  }

  AraSearchCenterModel? get searchCenter {
    return AraSearchCenterModel.tryParse(
          assistantMessage?.metadata?['search_center'],
        ) ??
        AraSearchCenterModel.tryParse(tripDraft?['search_center']);
  }

  static Map<String, dynamic>? _readMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }
}

class AraGenerateItineraryResponse {
  final String sessionId;
  final String status;
  final ItineraryModel itinerary;

  const AraGenerateItineraryResponse({
    required this.sessionId,
    required this.status,
    required this.itinerary,
  });

  factory AraGenerateItineraryResponse.fromJson(Map<String, dynamic> json) {
    return AraGenerateItineraryResponse(
      sessionId: (json['session_id'] ?? '').toString(),
      status: (json['status'] ?? 'completed').toString(),
      itinerary: ItineraryModel.fromJson(
        json['itinerary'] as Map<String, dynamic>,
      ),
    );
  }
}

class AraItineraryGenerationStatus {
  final String sessionId;
  final String status;
  final String? generatedItineraryId;
  final ItineraryModel? itinerary;
  final String? detail;

  const AraItineraryGenerationStatus({
    required this.sessionId,
    required this.status,
    this.generatedItineraryId,
    this.itinerary,
    this.detail,
  });

  factory AraItineraryGenerationStatus.fromJson(Map<String, dynamic> json) {
    final rawItinerary = json['itinerary'];
    return AraItineraryGenerationStatus(
      sessionId: (json['session_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      generatedItineraryId: json['generated_itinerary_id']?.toString(),
      itinerary: rawItinerary is Map<String, dynamic>
          ? ItineraryModel.fromJson(rawItinerary)
          : null,
      detail: json['detail']?.toString(),
    );
  }
}
