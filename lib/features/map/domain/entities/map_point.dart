import 'package:latlong2/latlong.dart';

import '../../../categories/data/models/category_model.dart';

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
  final bool isLocalAuthentic;
  final List<String>? amenities;

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
    this.isLocalAuthentic = true,
    this.amenities,
  });
}

extension MapPointCategoryX on MapPoint {
  /// Resolves a single user-facing label for this point's primary category.
  ///
  /// Looks up [categoryIds] `.first` against the provided [names] map (built
  /// from `categoriesByIdProvider`). Returns the unified fallback string when
  /// the point has no categories or the id isn't present in the map (loading,
  /// error, or unknown backend id).
  String categoryLabel(Map<int, CategoryModel> names) {
    if (categoryIds.isEmpty) return 'Sin categoría';
    return names[categoryIds.first]?.name ?? 'Sin categoría';
  }
}
