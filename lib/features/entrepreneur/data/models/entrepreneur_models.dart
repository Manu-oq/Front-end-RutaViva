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
  final String title;
  final String content;
  final bool isPublished;
  final DateTime? createdAt;

  const EntrepreneurPostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.isPublished,
    this.createdAt,
  });

  factory EntrepreneurPostModel.fromJson(Map<String, dynamic> json) {
    return EntrepreneurPostModel(
      id: json['id'].toString(),
      title: (json['title'] ?? 'Publicación').toString(),
      content: (json['content'] ?? json['body'] ?? json['description'] ?? '')
          .toString(),
      isPublished:
          json['is_published'] as bool? ?? json['published'] as bool? ?? true,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
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
