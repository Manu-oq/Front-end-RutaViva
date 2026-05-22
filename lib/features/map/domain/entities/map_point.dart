import 'package:latlong2/latlong.dart';

import '../../../categories/data/models/category_model.dart';

class MapPointVisitRules {
  final bool? isPrimaryExperience;
  final bool? requiresDaylight;
  final bool? nightSuitable;
  final String? latestRecommendedStartTime;
  final String? accessNotes;
  final String? confidence;

  const MapPointVisitRules({
    this.isPrimaryExperience,
    this.requiresDaylight,
    this.nightSuitable,
    this.latestRecommendedStartTime,
    this.accessNotes,
    this.confidence,
  });
}

class MapPoint {
  final String id;
  final String name;
  final LatLng coordinates;
  final List<int> categoryIds;
  final String? description;
  final String? imageUrl;
  final String? phone;
  final String? email;
  final double? distanceMeters;
  final String? openingHoursText;
  final MapPointVisitRules? visitRules;
  final bool isLocalAuthentic;
  final List<String>? amenities;
  final String? verificationStatus;
  final double? confidenceScore;

  MapPoint({
    required this.id,
    required this.name,
    required this.coordinates,
    this.categoryIds = const [],
    this.description,
    this.imageUrl,
    this.phone,
    this.email,
    this.distanceMeters,
    this.openingHoursText,
    this.visitRules,
    this.isLocalAuthentic = true,
    this.amenities,
    this.verificationStatus,
    this.confidenceScore,
  });
}

extension MapPointCategoryX on MapPoint {
  String categoryLabel(Map<int, CategoryModel> names) {
    if (categoryIds.isEmpty) return 'Sin categoría';
    return names[categoryIds.first]?.name ?? 'Sin categoría';
  }
}
