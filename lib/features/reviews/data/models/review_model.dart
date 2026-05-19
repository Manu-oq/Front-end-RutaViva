class ReviewModel {
  final String id;
  final String poiId;
  final String touristId;
  final String? authorName;
  final int ratingStars;
  final String textContent;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.poiId,
    required this.touristId,
    this.authorName,
    required this.ratingStars,
    required this.textContent,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      poiId: json['poi_id'] as String,
      touristId: json['tourist_id'] as String,
      authorName:
          (json['author_name'] ??
                  json['tourist_name'] ??
                  json['user_name'] ??
                  json['full_name'])
              ?.toString(),
      ratingStars: (json['rating_stars'] as num).toInt(),
      textContent: json['text_content'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ReviewSummaryModel {
  final String poiId;
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;

  const ReviewSummaryModel({
    required this.poiId,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory ReviewSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawDistribution =
        json['rating_distribution'] as Map<String, dynamic>? ?? {};
    return ReviewSummaryModel(
      poiId: json['poi_id'] as String,
      averageRating: (json['average_rating'] as num).toDouble(),
      totalReviews: (json['total_reviews'] as num).toInt(),
      ratingDistribution: {
        for (final entry in rawDistribution.entries)
          int.parse(entry.key): (entry.value as num).toInt(),
      },
    );
  }
}
