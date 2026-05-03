import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/skeleton_container.dart';
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
    Future.microtask(() {
      final current = ref.read(mapProvider);
      if (current.points.isEmpty && !current.isLoading) {
        ref.read(mapProvider.notifier).loadNearby();
      }
    });
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
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: araucaniaDefaultCenter,
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
              if (mapState.routePolyline.length > 1)
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
                        mapState.isLoading
                            ? 'Cargando rutas vivas...'
                            : 'Explora La Araucanía (${mapState.points.length})',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: mapState.isLoading
                          ? null
                          : () => ref
                                .read(mapProvider.notifier)
                                .loadNearby(
                                  center: _mapController.camera.center,
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

                        if (!context.mounted) {
                          return;
                        }

                        if (hasPermission) {
                          final position =
                              await Geolocator.getCurrentPosition();
                          final center = LatLng(
                            position.latitude,
                            position.longitude,
                          );

                          if (!context.mounted) {
                            return;
                          }

                          _mapController.move(center, 14.0);
                          await ref
                              .read(mapProvider.notifier)
                              .loadNearby(center: center);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Se requieren permisos de ubicación.',
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

          if (mapState.errorMessage != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: 130,
              child: _MapNotice(message: mapState.errorMessage!),
            ),

          if (mapState.isLoading)
            Positioned(
              left: 20,
              right: 20,
              bottom: 130,
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 6,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, _) => SkeletonContainer(
                    width: 100,
                    height: 36,
                    borderRadius: const BorderRadius.all(Radius.circular(18)),
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
                  final newZoom = _mapController.camera.zoom + 1;
                  _mapController.move(_mapController.camera.center, newZoom);
                }),
                const SizedBox(height: 12),
                _buildMapAction(theme, Icons.remove, () {
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

class _MapNotice extends StatelessWidget {
  final String message;

  const _MapNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, style: theme.textTheme.bodyMedium),
      ),
    );
  }
}
