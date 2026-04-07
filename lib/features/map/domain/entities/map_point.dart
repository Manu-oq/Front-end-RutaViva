import 'package:latlong2/latlong.dart';

enum PointCategory { comida, dormir, cultura, trekking }

class MapPoint {
  final String id;
  final String name;
  final LatLng coordinates; 
  final PointCategory category;
  final String? description; 
  final String? imageUrl;    
  final String? phone;       
  final bool isLocalAuthentic;

  MapPoint({
    required this.id,
    required this.name,
    required this.coordinates,
    required this.category,
    this.description, 
    this.imageUrl,    
    this.phone,       
    this.isLocalAuthentic = true,
  });
}