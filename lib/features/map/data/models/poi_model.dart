import 'package:latlong2/latlong.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/map_point.dart';

class PoiModel {
  final String id;
  final String nombre;
  final String descripcion;
  final String tipoAcceso;
  final String? telefonoPublico;
  final String? emailPublico;
  final dynamic multimediaUrls;
  final List<int> categoryIds;
  final double latitude;
  final double longitude;
  final double? distanciaMetros;

  const PoiModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipoAcceso,
    this.telefonoPublico,
    this.emailPublico,
    this.multimediaUrls,
    required this.categoryIds,
    required this.latitude,
    required this.longitude,
    this.distanciaMetros,
  });

  factory PoiModel.fromJson(Map<String, dynamic> json) {
    return PoiModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      tipoAcceso: json['tipo_acceso'] as String,
      telefonoPublico: json['telefono_publico'] as String?,
      emailPublico: json['email_publico'] as String?,
      multimediaUrls: json['multimedia_urls'],
      categoryIds: (json['category_ids'] as List<dynamic>? ?? [])
          .map((item) => (item as num).toInt())
          .toList(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanciaMetros: (json['distancia_metros'] as num?)?.toDouble(),
    );
  }

  MapPoint toMapPoint() {
    return MapPoint(
      id: id,
      name: nombre,
      description: descripcion,
      phone: telefonoPublico,
      email: emailPublico,
      categoryIds: categoryIds,
      category: _categoryFromIds(categoryIds),
      coordinates: LatLng(latitude, longitude),
      imageUrl: ApiConstants.resolveBackendUrl(_firstMediaUrl(multimediaUrls)),
      distanceMeters: distanciaMetros,
    );
  }

  static PointCategory _categoryFromIds(List<int> ids) {
    if (ids.contains(1)) {
      return PointCategory.naturaleza;
    }
    if (ids.contains(2)) {
      return PointCategory.gastronomia;
    }
    if (ids.contains(3)) {
      return PointCategory.turismo;
    }
    if (ids.contains(4)) {
      return PointCategory.alojamiento;
    }
    if (ids.contains(5)) {
      return PointCategory.cultura;
    }
    return PointCategory.otro;
  }

  static String? _firstMediaUrl(dynamic media) {
    if (media is List) {
      for (final item in media) {
        if (item is String && item.isNotEmpty) {
          return item;
        }
        if (item is Map) {
          final value = _firstMediaUrl(item);
          if (value != null) {
            return value;
          }
        }
      }
    }

    if (media is Map) {
      final preferredKeys = ['cover', 'image', 'url', 'principal'];
      for (final key in preferredKeys) {
        final value = media[key];
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
      for (final value in media.values) {
        if (value is String && value.isNotEmpty) {
          return value;
        }
        final nested = _firstMediaUrl(value);
        if (nested != null) {
          return nested;
        }
      }
    }

    return null;
  }
}
