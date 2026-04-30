import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/map_point.dart';

class MapState {
  final List<MapPoint> points;
  final List<LatLng> routePolyline;
  final MapPoint? selectedPoint;

  MapState({
    required this.points,
    required this.routePolyline,
    this.selectedPoint,
  });

  MapState copyWith({
    List<MapPoint>? points,
    List<LatLng>? routePolyline,
    MapPoint? selectedPoint,
    bool clearSelection = false,
  }) {
    return MapState(
      points: points ?? this.points,
      routePolyline: routePolyline ?? this.routePolyline,
      selectedPoint: clearSelection
          ? null
          : (selectedPoint ?? this.selectedPoint),
    );
  }
}

class MapNotifier extends Notifier<MapState> {
  @override
  MapState build() {
    return MapState(
      points: [
        MapPoint(
          id: '1',
          name: 'Taller de Nury',
          description:
              'Artesanía textil en lana de oveja con tintes naturales de la zona. Conoce el proceso del Witral.',
          imageUrl:
              'https://images.unsplash.com/photo-1590736962236-407a505f9630',
          phone: '+56912345678',
          coordinates: const LatLng(-39.2952, -71.6611),
          category: PointCategory.cultura,
        ),
        MapPoint(
          id: '2',
          name: 'Ruka de Rosa',
          description:
              'Gastronomía Mapuche tradicional. Prueba el pan de piñón y el muday en un ambiente ancestral.',
          imageUrl:
              'https://images.unsplash.com/photo-1596230529625-7ee10f7b09b6',
          phone: '+56987654321',
          coordinates: const LatLng(-39.3552, -71.7011),
          category: PointCategory.comida,
        ),
        MapPoint(
          id: '3',
          name: 'Eco-Hostel Volcán',
          description:
              'Alojamiento sustentable con vista al Villarrica. Energía solar y gestión de residuos zero waste.',
          imageUrl:
              'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
          phone: '+56955544433',
          coordinates: const LatLng(-39.4252, -71.7511),
          category: PointCategory.dormir,
        ),
      ],
      routePolyline: [
        const LatLng(-39.2952, -71.6611),
        const LatLng(-39.3552, -71.7011),
        const LatLng(-39.4252, -71.7511),
      ],
    );
  }

  void selectPoint(MapPoint? point) {
    state = state.copyWith(selectedPoint: point, clearSelection: point == null);
  }

  void updateRoute(List<LatLng> newRoute) {
    state = state.copyWith(routePolyline: newRoute);
  }
}

final mapProvider = NotifierProvider<MapNotifier, MapState>(MapNotifier.new);
