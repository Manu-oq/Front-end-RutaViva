import 'package:latlong2/latlong.dart';

enum PointCategory {
  naturaleza,
  gastronomia,
  turismo,
  alojamiento,
  cultura,
  otro,
}

extension PointCategoryLabel on PointCategory {
  String get label {
    switch (this) {
      case PointCategory.naturaleza:
        return 'Naturaleza';
      case PointCategory.gastronomia:
        return 'Gastronomía';
      case PointCategory.turismo:
        return 'Turismo';
      case PointCategory.alojamiento:
        return 'Alojamiento';
      case PointCategory.cultura:
        return 'Cultura';
      case PointCategory.otro:
        return 'Otro';
    }
  }
}

class MapPoint {
  final String id;
  final String name;
  final LatLng coordinates;
  final PointCategory category;
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
    required this.category,
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
