import 'package:latlong2/latlong.dart';

class GeocodingResultModel {
  final String id;
  final String label;
  final LatLng coordinates;

  const GeocodingResultModel({
    required this.id,
    required this.label,
    required this.coordinates,
  });

  factory GeocodingResultModel.fromJson(Map<String, dynamic> json) {
    final lat = _readDouble(json, ['lat', 'latitude']);
    final lon = _readDouble(json, ['lon', 'lng', 'longitude']);
    final label = _readString(json, [
      'label',
      'display_name',
      'name',
      'address',
      'formatted_address',
    ]);
    return GeocodingResultModel(
      id: (json['id'] ?? json['place_id'] ?? label ?? '$lat,$lon').toString(),
      label: label ?? 'Ubicación encontrada',
      coordinates: LatLng(lat ?? 0, lon ?? 0),
    );
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
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
