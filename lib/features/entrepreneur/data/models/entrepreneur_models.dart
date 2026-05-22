class EntrepreneurMetricsModel {
  final int placesCount;
  final int visitsCount;
  final int reviewsCount;
  final int favoritesCount;

  const EntrepreneurMetricsModel({
    required this.placesCount,
    required this.visitsCount,
    required this.reviewsCount,
    required this.favoritesCount,
  });

  factory EntrepreneurMetricsModel.fromJson(Map<String, dynamic> json) {
    return EntrepreneurMetricsModel(
      placesCount: _readInt(json, ['places_count', 'pois_count', 'places']),
      visitsCount: _readInt(json, ['visits_count', 'visits']),
      reviewsCount: _readInt(json, ['reviews_count', 'reviews']),
      favoritesCount: _readInt(json, ['favorites_count', 'favorites']),
    );
  }
}

class EntrepreneurIncomeModel {
  final double total;
  final String currency;
  final bool isPlaceholder;

  const EntrepreneurIncomeModel({
    required this.total,
    required this.currency,
    required this.isPlaceholder,
  });

  factory EntrepreneurIncomeModel.fromJson(Map<String, dynamic> json) {
    return EntrepreneurIncomeModel(
      total: _readDouble(json, ['total', 'amount', 'income']) ?? 0,
      currency: (json['currency'] ?? 'CLP').toString(),
      isPlaceholder:
          json['is_placeholder'] as bool? ??
          json['placeholder'] as bool? ??
          true,
    );
  }
}

class EntrepreneurPostModel {
  final String id;
  final String? entrepreneurId;
  final String? poiId;
  final String? poiName;
  final String title;
  final String content;
  final String? imageUrl;
  final bool isPublished;
  final bool isPinned;
  final DateTime? scheduledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EntrepreneurPostModel({
    required this.id,
    this.entrepreneurId,
    this.poiId,
    this.poiName,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.isPublished,
    this.isPinned = false,
    this.scheduledAt,
    this.createdAt,
    this.updatedAt,
  });

  factory EntrepreneurPostModel.fromJson(Map<String, dynamic> json) {
    return EntrepreneurPostModel(
      id: json['id'].toString(),
      entrepreneurId: json['entrepreneur_id']?.toString(),
      poiId: json['poi_id']?.toString(),
      poiName: json['poi_name']?.toString(),
      title: (json['title'] ?? 'Publicación').toString(),
      content: (json['content'] ?? '').toString(),
      imageUrl: json['image_url']?.toString(),
      isPublished: json['is_published'] as bool? ?? true,
      isPinned: json['is_pinned'] as bool? ?? false,
      scheduledAt: DateTime.tryParse((json['scheduled_at'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()),
    );
  }
}

class PoiAnalyticsModel {
  final int visitsCount;
  final int clicksCount;
  final int favoritesCount;
  final int reviewsCount;
  final double avgRating;
  final int weeklyVisits;
  final double monthlyGrowth;

  const PoiAnalyticsModel({
    required this.visitsCount,
    required this.clicksCount,
    required this.favoritesCount,
    required this.reviewsCount,
    required this.avgRating,
    required this.weeklyVisits,
    required this.monthlyGrowth,
  });

  factory PoiAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return PoiAnalyticsModel(
      visitsCount: _readInt(json, ['visits_count', 'visits']),
      clicksCount: _readInt(json, ['clicks_count', 'clicks']),
      favoritesCount: _readInt(json, ['favorites_count', 'favorites']),
      reviewsCount: _readInt(json, ['reviews_count', 'reviews']),
      avgRating: _readDouble(json, ['avg_rating', 'average_rating']) ?? 0,
      weeklyVisits: _readInt(json, ['weekly_visits', 'visits_this_week']),
      monthlyGrowth:
          _readDouble(json, ['monthly_growth', 'growth_percent']) ?? 0,
    );
  }
}

class PoiActivityEvent {
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const PoiActivityEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });

  factory PoiActivityEvent.fromJson(Map<String, dynamic> json) {
    return PoiActivityEvent(
      type: (json['type'] ?? json['event_type'] ?? 'unknown').toString(),
      timestamp: DateTime.parse(
        (json['timestamp'] ?? json['created_at']).toString(),
      ),
      data:
          (json['data'] ?? json['extra'] ?? const <String, dynamic>{})
              as Map<String, dynamic>,
    );
  }
}

int _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
  }
  return 0;
}

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
  }
  return null;
}
