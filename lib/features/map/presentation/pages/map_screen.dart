import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/utils/location_handler.dart';
import '../providers/map_provider.dart';
import '../widgets/custom_map_marker.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapState = ref.watch(mapProvider);

    return Scaffold(
      body: Stack(
        children: [
          // 1. EL MAPA
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-39.35, -71.70),
              initialZoom: 11.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rutaviva.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: mapState.routePolyline,
                    strokeWidth: 5.0,
                    color: theme.colorScheme.tertiary,
                    borderStrokeWidth: 2.0,
                    borderColor: theme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                ],
              ),
              MarkerLayer(
                markers: mapState.points.map((point) {
                  return Marker(
                    point: point.coordinates,
                    width: 80,
                    height: 80,
                    child: CustomMapMarker(point: point),
                  );
                }).toList(),
              ),
            ],
          ),

          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: GlassContainer(
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        "Explora La Araucanía",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    IconButton(
                      icon: Icon(
                        Icons.gps_fixed,
                        color: theme.colorScheme.secondary,
                      ),
                      onPressed: () async {
                        final hasPermission =
                            await LocationHandler.handleLocationPermission();

                        if (!context.mounted) return;

                        if (hasPermission) {
                          final position =
                              await Geolocator.getCurrentPosition();

                          if (!context.mounted) return;

                          _mapController.move(
                            LatLng(position.latitude, position.longitude),
                            14.0,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Se requieren permisos de ubicación.",
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            right: 20,
            child: Column(
              children: [
                _buildMapAction(theme, Icons.add, () {
                  // Aumentar zoom
                  final newZoom = _mapController.camera.zoom + 1;
                  _mapController.move(_mapController.camera.center, newZoom);
                }),
                const SizedBox(height: 12),
                _buildMapAction(theme, Icons.remove, () {
                  // Disminuir zoom
                  final newZoom = _mapController.camera.zoom - 1;
                  _mapController.move(_mapController.camera.center, newZoom);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapAction(ThemeData theme, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: theme.colorScheme.primary),
        onPressed: onTap,
      ),
    );
  }
}
