import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/glass_container.dart';
import '../providers/map_provider.dart';
import '../widgets/custom_map_marker.dart';

class MapScreen extends ConsumerWidget { 
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mapState = ref.watch(mapProvider);

    return Scaffold(
      body: Stack(
        children: [

          FlutterMap(
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
                    borderColor: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        "Explora La Araucanía",
                        style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.gps_fixed, color: theme.colorScheme.secondary),
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
                }),
                const SizedBox(height: 12),
                _buildMapAction(theme, Icons.remove, () {
                }),
              ],
            ),
          )
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
            spreadRadius: 2
          )
        ]
      ),
      child: IconButton(
        icon: Icon(icon, color: theme.colorScheme.primary),
        onPressed: onTap,
      ),
    );
  }
}