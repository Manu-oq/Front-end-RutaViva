import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_back_button.dart';
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

  Future<void> _locateUser() async {
    final hasPermission = await LocationHandler.handleLocationPermission();

    if (!mounted) {
      return;
    }

    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se requieren permisos de ubicación.')),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    final center = LatLng(position.latitude, position.longitude);

    if (!mounted) {
      return;
    }

    _mapController.move(center, 14.0);
    await ref.read(mapProvider.notifier).loadNearby(center: center);
  }

  void _refreshNearby() {
    ref
        .read(mapProvider.notifier)
        .loadNearby(center: _mapController.camera.center);
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
                      strokeWidth: 5.5,
                      color: theme.colorScheme.tertiary,
                      borderStrokeWidth: 3,
                      borderColor: theme.colorScheme.primary.withValues(
                        alpha: 0.35,
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
                    width: 92,
                    height: 92,
                    child: CustomMapMarker(point: point),
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      theme.colorScheme.surface.withValues(alpha: 0.26),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 18,
            left: 16,
            right: 16,
            child: SafeArea(
              child: _MapHeader(
                isLoading: mapState.isLoading,
                count: mapState.points.length,
                onRefresh: mapState.isLoading ? null : _refreshNearby,
                onLocate: _locateUser,
              ),
            ),
          ),
          if (mapState.errorMessage != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: 136,
              child: _MapNotice(
                icon: Icons.warning_amber_rounded,
                message: mapState.errorMessage!,
                actionLabel: 'Reintentar',
                onAction: mapState.isLoading ? null : _refreshNearby,
              ),
            ),
          if (!mapState.isLoading &&
              mapState.errorMessage == null &&
              mapState.points.isEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 136,
              child: _MapNotice(
                icon: Icons.travel_explore,
                message:
                    'No hay lugares para mostrar todavía. Prueba refrescar o buscar desde Inicio.',
                actionLabel: 'Refrescar',
                onAction: _refreshNearby,
              ),
            ),
          if (mapState.isLoading)
            Positioned(
              left: 20,
              right: 20,
              bottom: 136,
              child: _LoadingChips(),
            ),
          Positioned(
            bottom: 34,
            right: 18,
            child: SafeArea(
              child: Column(
                children: [
                  _MapFloatingAction(
                    icon: Icons.add,
                    tooltip: 'Acercar',
                    onTap: () {
                      final newZoom = _mapController.camera.zoom + 1;
                      _mapController.move(
                        _mapController.camera.center,
                        newZoom,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _MapFloatingAction(
                    icon: Icons.remove,
                    tooltip: 'Alejar',
                    onTap: () {
                      final newZoom = _mapController.camera.zoom - 1;
                      _mapController.move(
                        _mapController.camera.center,
                        newZoom,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapHeader extends StatelessWidget {
  final bool isLoading;
  final int count;
  final VoidCallback? onRefresh;
  final VoidCallback onLocate;

  const _MapHeader({
    required this.isLoading,
    required this.count,
    required this.onRefresh,
    required this.onLocate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Row(
          children: [
            const AppBackButton(
              fallbackRouteName: AppRouteNames.home,
              usePop: false,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mapa vivo',
                    style: theme.textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLoading
                        ? 'Buscando lugares cercanos...'
                        : '$count lugares para explorar',
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refrescar',
              onPressed: onRefresh,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
            IconButton.filledTonal(
              tooltip: 'Mi ubicación',
              onPressed: onLocate,
              icon: const Icon(Icons.my_location),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, _) => const SkeletonContainer(
          width: 112,
          height: 40,
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
      ),
    );
  }
}

class _MapFloatingAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapFloatingAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.10),
              blurRadius: 22,
              spreadRadius: -12,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: IconButton(
          tooltip: tooltip,
          icon: Icon(icon, color: theme.colorScheme.primary),
          onPressed: onTap,
        ),
      ),
    );
  }
}

class _MapNotice extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MapNotice({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Material(
          color: theme.colorScheme.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(24),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.primary,
                  child: Icon(icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(message, style: theme.textTheme.bodyMedium),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(width: 8),
                  TextButton(onPressed: onAction, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
