import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/app_durations.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/utils/location_handler.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../categories/presentation/category_style.dart';
import '../../data/repositories/geocoding_repository.dart';
import '../../domain/entities/map_point.dart';
import '../providers/map_provider.dart';
import '../widgets/custom_map_marker.dart';

class MapScreen extends ConsumerStatefulWidget {
  final String backFallbackRouteName;

  const MapScreen({super.key, this.backFallbackRouteName = AppRouteNames.home});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static const _autoRefreshDebounce = Duration(milliseconds: 800);
  static const _autoRefreshDistanceThresholdMeters = 8000.0;

  late final MapController _mapController;
  final _searchController = TextEditingController();
  LatLng _cameraCenter = araucaniaDefaultCenter;
  double _cameraZoom = 11.0;
  Timer? _autoRefreshTimer;
  String? _activeMapSearchQuery;
  bool _isResolvingSearch = false;
  double _pullRefreshOffset = 0;
  bool _isPullRefreshing = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    final current = ref.read(mapProvider);
    _cameraCenter = current.center;
    _cameraZoom = current.focusedPoiId != null ? 15.0 : 11.0;
    Future.microtask(() {
      final current = ref.read(mapProvider);
      if (widget.backFallbackRouteName == AppRouteNames.home &&
          !current.isGlobalMode) {
        ref.read(mapProvider.notifier).loadNearby(center: current.center);
      } else if (current.isGlobalMode &&
          current.points.isEmpty &&
          !current.isLoading) {
        ref.read(mapProvider.notifier).loadNearby();
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  List<_VisibleMapMarker> _visibleMarkers(
    List<MapPoint> points,
    MapState mapState,
  ) {
    if (points.isEmpty) {
      return const [];
    }

    if (!mapState.isGlobalMode) {
      return [
        for (final point in points)
          _VisibleMapMarker(
            point: point,
            size: mapState.focusedPoiId == point.id ? 82 : 64,
            showLabel: true,
            highlighted: mapState.focusedPoiId == point.id,
          ),
      ];
    }

    final isSearchMode = _activeMapSearchQuery?.trim().isNotEmpty == true;
    final density = _MarkerDensity.fromZoom(_cameraZoom);
    final hasCategoryFilters = mapState.selectedCategoryIds.isNotEmpty;
    const distance = Distance();
    final radiusMeters = density.radiusMeters(isSearchMode: isSearchMode);
    final maxMarkers = density.maxMarkers(
      hasCategoryFilters: hasCategoryFilters,
      isSearchMode: isSearchMode,
    );
    final cellSize = density.cellSize(
      hasCategoryFilters: hasCategoryFilters,
      isSearchMode: isSearchMode,
    );

    final candidates =
        <({MapPoint point, double meters})>[
          for (final point in points)
            if (isSearchMode ||
                hasCategoryFilters ||
                density.allows(point.categoryIds))
              (
                point: point,
                meters: distance.as(
                  LengthUnit.Meter,
                  _cameraCenter,
                  point.coordinates,
                ),
              ),
        ].where((item) => item.meters <= radiusMeters).toList()..sort((a, b) {
          final scoreA = _visualScore(
            a.point,
            a.meters,
            density: density,
            isSearchMode: isSearchMode,
          );
          final scoreB = _visualScore(
            b.point,
            b.meters,
            density: density,
            isSearchMode: isSearchMode,
          );
          final byScore = scoreB.compareTo(scoreA);
          return byScore == 0 ? a.meters.compareTo(b.meters) : byScore;
        });

    final occupiedCells = <String>{};
    final visible = <_VisibleMapMarker>[];
    for (final item in candidates) {
      final cell = _screenCellKey(item.point, cellSize);
      if (!occupiedCells.add(cell)) {
        continue;
      }
      visible.add(
        _VisibleMapMarker(
          point: item.point,
          size: density.markerSize(isSearchMode: isSearchMode),
          showLabel:
              isSearchMode ||
              density == _MarkerDensity.near ||
              item.point.id == mapState.selectedPoint?.id,
          highlighted: item.point.id == mapState.selectedPoint?.id,
        ),
      );
      if (visible.length >= maxMarkers) {
        break;
      }
    }
    return visible;
  }

  String _screenCellKey(MapPoint point, double cellSize) {
    try {
      final offset = _mapController.camera.getOffsetFromOrigin(
        point.coordinates,
      );
      return '${(offset.dx / cellSize).floor()}:${(offset.dy / cellSize).floor()}';
    } catch (_) {
      final scale = _cameraZoom >= 14
          ? 0.002
          : _cameraZoom >= 12
          ? 0.006
          : 0.016;
      return '${(point.coordinates.latitude / scale).floor()}:${(point.coordinates.longitude / scale).floor()}';
    }
  }

  double _visualScore(
    MapPoint point,
    double distanceMeters, {
    required _MarkerDensity density,
    required bool isSearchMode,
  }) {
    final categoryScore = point.categoryIds.isEmpty
        ? 4.0
        : point.categoryIds
              .map((id) => _categoryVisualPriority(id, density))
              .reduce((a, b) => a > b ? a : b);
    final imageBoost = point.imageUrl?.isNotEmpty == true ? 8.0 : 0.0;
    final primaryBoost = point.visitRules?.isPrimaryExperience == true
        ? 18.0
        : 0.0;
    final distancePenalty = distanceMeters / (isSearchMode ? 2200 : 3000);
    return categoryScore + imageBoost + primaryBoost - distancePenalty;
  }

  double _categoryVisualPriority(int id, _MarkerDensity density) {
    final landmark = switch (id) {
      1 || 3 || 7 || 8 || 9 || 10 || 11 => 100.0,
      5 || 6 || 12 => 82.0,
      2 || 4 || 15 => 66.0,
      13 || 14 => 38.0,
      _ => 44.0,
    };
    if (density == _MarkerDensity.near) {
      return landmark + (id == 13 || id == 14 ? 18.0 : 0.0);
    }
    return landmark;
  }

  Future<void> _locateUser() async {
    bool hasPermission;
    try {
      hasPermission = await LocationHandler.handleLocationPermission();
    } catch (_) {
      hasPermission = false;
    }

    if (!mounted) {
      return;
    }

    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se requieren permisos de ubicación.')),
      );
      return;
    }

    Position position;
    try {
      position = await Geolocator.getCurrentPosition();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos obtener tu ubicación en este dispositivo.'),
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    final center = LatLng(position.latitude, position.longitude);
    setState(() {
      _cameraCenter = center;
      _cameraZoom = 14.0;
    });
    _mapController.move(center, 14.0);
    await ref.read(mapProvider.notifier).loadNearby(center: center);
  }

  void _refreshNearby() {
    _autoRefreshTimer?.cancel();
    _activeMapSearchQuery = null;
    _searchController.clear();
    ref
        .read(mapProvider.notifier)
        .loadNearby(center: _mapController.camera.center);
  }

  Future<void> _searchMap() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _isResolvingSearch) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _activeMapSearchQuery = query;
      _isResolvingSearch = true;
    });

    final notifier = ref.read(mapProvider.notifier);
    final center = _mapController.camera.center;
    await notifier.semanticSearch(query: query, center: center);

    if (!mounted) return;
    var stateAfterSearch = ref.read(mapProvider);
    if (stateAfterSearch.visiblePoints.isEmpty) {
      try {
        final locations = await ref
            .read(geocodingRepositoryProvider)
            .search(query: query, lat: center.latitude, lon: center.longitude);
        if (locations.isNotEmpty) {
          final nextCenter = locations.first.coordinates;
          _mapController.move(nextCenter, 13.0);
          setState(() {
            _cameraCenter = nextCenter;
            _cameraZoom = 13.0;
          });
          await notifier.semanticSearch(query: query, center: nextCenter);
          stateAfterSearch = ref.read(mapProvider);
          if (stateAfterSearch.visiblePoints.isEmpty) {
            await notifier.loadMapViewNearby(center: nextCenter, radius: 16000);
          }
        }
      } catch (_) {
        // Keep the semantic-search result/error already reflected by MapState.
      }
    }

    if (!mounted) return;
    final finalState = ref.read(mapProvider);
    final finalVisiblePoints = finalState.visiblePoints;
    if (finalVisiblePoints.isNotEmpty) {
      final first = finalVisiblePoints.first.coordinates;
      final targetZoom = _cameraZoom < 13 ? 13.0 : _cameraZoom;
      _mapController.move(first, targetZoom);
      setState(() {
        _cameraCenter = first;
        _cameraZoom = targetZoom;
      });
    }
    setState(() => _isResolvingSearch = false);
  }

  void _clearSearch() {
    setState(() {
      _activeMapSearchQuery = null;
      _isResolvingSearch = false;
    });
    _searchController.clear();
    ref
        .read(mapProvider.notifier)
        .loadNearby(center: _mapController.camera.center);
  }

  Future<void> _onPullRefresh() async {
    setState(() => _isPullRefreshing = true);
    try {
      final mapState = ref.read(mapProvider);
      final notifier = ref.read(mapProvider.notifier);
      if (mapState.selectedCategoryIds.isNotEmpty) {
        await notifier.loadCategoryFilteredNearby(
          center: _mapController.camera.center,
          categoryIds: mapState.selectedCategoryIds,
        );
      } else {
        await notifier.loadNearby(center: _mapController.camera.center);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPullRefreshing = false;
          _pullRefreshOffset = 0;
        });
      }
    }
  }

  void _focusSearchResult(MapPoint point) {
    ref.read(mapProvider.notifier).selectPoint(point);
    setState(() {
      _cameraCenter = point.coordinates;
      _cameraZoom = _cameraZoom < 14 ? 14.0 : _cameraZoom;
    });
    _mapController.move(point.coordinates, _cameraZoom);
  }

  void _scheduleViewportRefresh(LatLng center) {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer(_autoRefreshDebounce, () {
      if (!mounted) {
        return;
      }
      final mapState = ref.read(mapProvider);
      if (mapState.isLoading || !mapState.isGlobalMode) {
        return;
      }

      final metersFromLoadedCenter = const Distance().as(
        LengthUnit.Meter,
        mapState.center,
        center,
      );
      if (metersFromLoadedCenter < _autoRefreshDistanceThresholdMeters) {
        return;
      }

      final notifier = ref.read(mapProvider.notifier);
      if (mapState.selectedCategoryIds.isNotEmpty) {
        notifier.loadCategoryFilteredNearby(
          center: center,
          categoryIds: mapState.selectedCategoryIds,
        );
      } else {
        notifier.loadNearby(center: center);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapState = ref.watch(mapProvider);
    final visiblePoints = mapState.visiblePoints;
    final visibleMarkers = _visibleMarkers(visiblePoints, mapState);

    ref.listen<MapState>(mapProvider, (previous, next) {
      if (next.isGlobalMode || previous?.center == next.center) {
        return;
      }
      final zoom = next.focusedPoiId != null ? 15.0 : 13.0;
      _autoRefreshTimer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _cameraCenter = next.center;
          _cameraZoom = zoom;
        });
        _mapController.move(next.center, zoom);
      });
    });

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapState.center,
              initialZoom: mapState.focusedPoiId != null ? 15.0 : 11.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onPositionChanged: (position, hasGesture) {
                final center = position.center;
                final zoom = position.zoom;
                if (hasGesture) {
                  setState(() {
                    _cameraCenter = center;
                    _cameraZoom = zoom;
                  });
                  if (ref.read(mapProvider).isGlobalMode) {
                    _scheduleViewportRefresh(center);
                  }
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.rutaviva.app',
              ),
              MarkerLayer(
                markers: visibleMarkers
                    .map((marker) {
                      return Marker(
                        point: marker.point.coordinates,
                        width: marker.size,
                        height: marker.showLabel
                            ? marker.size + 24
                            : marker.size,
                        child: CustomMapMarker(
                          point: marker.point,
                          compact: !marker.showLabel,
                          showLabel: marker.showLabel,
                          highlighted: marker.highlighted,
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 80,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragUpdate: (details) {
                if (!mapState.isGlobalMode) return;
                setState(() {
                  _pullRefreshOffset = (_pullRefreshOffset + details.delta.dy)
                      .clamp(0, 90);
                });
              },
              onVerticalDragEnd: (_) {
                if (!mapState.isGlobalMode) return;
                if (_pullRefreshOffset > 60 && !mapState.isLoading) {
                  _onPullRefresh();
                } else {
                  setState(() => _pullRefreshOffset = 0);
                }
              },
              child: _pullRefreshOffset > 0
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: _pullRefreshOffset - 28),
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: _isPullRefreshing
                              ? const CircularProgressIndicator(strokeWidth: 3)
                              : Icon(
                                  Icons.refresh_rounded,
                                  color: Theme.of(context).colorScheme.primary
                                      .withValues(
                                        alpha: (_pullRefreshOffset / 90).clamp(
                                          0.2,
                                          1.0,
                                        ),
                                      ),
                                  size: 28,
                                ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
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
                controller: _searchController,
                backFallbackRouteName: widget.backFallbackRouteName,
                isLoading: _isResolvingSearch || mapState.isLoading,
                activeSearchQuery: _activeMapSearchQuery,
                hasActiveSearch: _activeMapSearchQuery != null,
                onSearch: _searchMap,
                onClearSearch: _clearSearch,
              ),
            ),
          ),
          Positioned(
            top: 88,
            left: 16,
            right: 16,
            child: AnimatedOpacity(
              opacity: mapState.isGlobalMode ? 1.0 : 0.0,
              duration: AppDurations.long,
              curve: Curves.easeOut,
              child: AnimatedSlide(
                offset: Offset(0, mapState.isGlobalMode ? 0.0 : -0.12),
                duration: AppDurations.long,
                curve: Curves.easeOut,
                child: IgnorePointer(
                  ignoring: !mapState.isGlobalMode,
                  child: SafeArea(
                    child: _MapCategoryFilters(
                      categories: ref.watch(categoriesProvider),
                      selectedCategoryIds: mapState.selectedCategoryIds,
                      isLoading: mapState.isLoading,
                      onClear: () {
                        setState(() => _activeMapSearchQuery = null);
                        _searchController.clear();
                        ref
                            .read(mapProvider.notifier)
                            .clearCategoryFilters(
                              center: _mapController.camera.center,
                            );
                      },
                      onToggle: (id) {
                        setState(() => _activeMapSearchQuery = null);
                        _searchController.clear();
                        ref
                            .read(mapProvider.notifier)
                            .toggleCategoryFilter(
                              id,
                              center: _mapController.camera.center,
                            );
                      },
                    ),
                  ),
                ),
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
              visiblePoints.isEmpty)
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
          if (mapState.isGlobalMode &&
              _activeMapSearchQuery != null &&
              visiblePoints.isNotEmpty)
            Positioned(
              left: 16,
              right: 92,
              bottom: 112,
              child: SafeArea(
                child: _MapSearchResultsPanel(
                  points: visiblePoints,
                  selectedPointId: mapState.selectedPoint?.id,
                  onSelect: _focusSearchResult,
                ),
              ),
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
                      final center = _mapController.camera.center;
                      setState(() {
                        _cameraCenter = center;
                        _cameraZoom = newZoom;
                      });
                      _mapController.move(center, newZoom);
                    },
                  ),
                  const SizedBox(height: 12),
                  _MapFloatingAction(
                    icon: Icons.remove,
                    tooltip: 'Alejar',
                    onTap: () {
                      final newZoom = _mapController.camera.zoom - 1;
                      final center = _mapController.camera.center;
                      setState(() {
                        _cameraCenter = center;
                        _cameraZoom = newZoom;
                      });
                      _mapController.move(center, newZoom);
                    },
                  ),
                  const SizedBox(height: 12),
                  _MapFloatingAction(
                    icon: Icons.my_location,
                    tooltip: 'Mi ubicación',
                    onTap: _locateUser,
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
  final TextEditingController controller;
  final String backFallbackRouteName;
  final bool isLoading;
  final String? activeSearchQuery;
  final bool hasActiveSearch;
  final VoidCallback onSearch;
  final VoidCallback onClearSearch;

  const _MapHeader({
    required this.controller,
    required this.backFallbackRouteName,
    required this.isLoading,
    required this.activeSearchQuery,
    required this.hasActiveSearch,
    required this.onSearch,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassContainer(
      borderRadius: BorderRadius.circular(26),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 8, 8),
        child: Row(
          children: [
            AppBackButton(fallbackRouteName: backFallbackRouteName),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isLoading,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onSearch(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Buscar minimarket, comisaría...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: null,
                  suffixIcon: hasActiveSearch
                      ? IconButton(
                          tooltip: 'Limpiar búsqueda',
                          onPressed: onClearSearch,
                          icon: const Icon(Icons.close_rounded),
                          visualDensity: VisualDensity.compact,
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surface.withValues(alpha: 0.92),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.47),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton.filled(
                tooltip: 'Buscar',
                onPressed: onSearch,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.search_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                padding: const EdgeInsets.all(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapCategoryFilters extends StatelessWidget {
  final AsyncValue<List<CategoryModel>> categories;
  final Set<int> selectedCategoryIds;
  final bool isLoading;
  final VoidCallback onClear;
  final ValueChanged<int> onToggle;

  const _MapCategoryFilters({
    required this.categories,
    required this.selectedCategoryIds,
    required this.isLoading,
    required this.onClear,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final items = categories.maybeWhen(
      data: (value) => value,
      orElse: () => const <CategoryModel>[],
    );
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final allSelected = selectedCategoryIds.isEmpty;
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: items.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _MapFilterChip(
              label: 'Todos',
              icon: Icons.public_rounded,
              color: theme.colorScheme.primary,
              selected: allSelected,
              enabled: !isLoading,
              onTap: onClear,
            );
          }

          final category = items[index - 1];
          final style = categoryStyleFor(category.id, theme.colorScheme);
          return _MapFilterChip(
            label: category.name,
            icon: style.icon,
            color: style.color,
            selected: selectedCategoryIds.contains(category.id),
            enabled: !isLoading,
            onTap: () => onToggle(category.id),
          );
        },
      ),
    );
  }
}

class _MapSearchResultsPanel extends StatelessWidget {
  final List<MapPoint> points;
  final String? selectedPointId;
  final ValueChanged<MapPoint> onSelect;

  const _MapSearchResultsPanel({
    required this.points,
    required this.selectedPointId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final visible = points.take(10).toList(growable: false);
    return SizedBox(
      height: 126,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visible.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final point = visible[index];
          return _MapSearchResultCard(
            point: point,
            selected: point.id == selectedPointId,
            onTap: () => onSelect(point),
          );
        },
      ),
    );
  }
}

class _MapSearchResultCard extends StatelessWidget {
  final MapPoint point;
  final bool selected;
  final VoidCallback onTap;

  const _MapSearchResultCard({
    required this.point,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = categoryStyleFor(
      point.categoryIds.isEmpty ? null : point.categoryIds.first,
      theme.colorScheme,
    );
    return SizedBox(
      width: 218,
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.96)
            : theme.colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.12),
                  blurRadius: 22,
                  spreadRadius: -12,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: style.color.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(style.icon, color: style.color, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          point.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (point.distanceMeters != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _distanceLabel(point.distanceMeters!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _distanceLabel(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }
}

class _MapFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _MapFilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = selected
        ? color.withValues(alpha: 0.96)
        : theme.colorScheme.surface.withValues(alpha: 0.94);
    final foreground = selected ? Colors.white : theme.colorScheme.onSurface;

    return AnimatedScale(
      scale: selected ? 1.05 : 1.0,
      duration: AppDurations.short,
      curve: Curves.easeOutBack,
      child: Semantics(
        button: true,
        label: 'Filtro $label, ${selected ? "seleccionado" : "disponible"}',
        enabled: enabled,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: AppDurations.medium,
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? color.withValues(alpha: 0.32)
                    : theme.colorScheme.outlineVariant,
                width: selected ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? color.withValues(alpha: 0.22)
                      : theme.colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: selected ? 14 : 18,
                  spreadRadius: selected ? -6 : -12,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: foreground),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
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

enum _MarkerDensity {
  far,
  medium,
  near;

  static _MarkerDensity fromZoom(double zoom) {
    if (zoom >= 14) return _MarkerDensity.near;
    if (zoom >= 12) return _MarkerDensity.medium;
    return _MarkerDensity.far;
  }

  bool allows(List<int> categoryIds) {
    if (this == _MarkerDensity.near || categoryIds.isEmpty) {
      return true;
    }
    final allowed = switch (this) {
      _MarkerDensity.far => const {1, 3, 7, 8, 9, 10, 11},
      _MarkerDensity.medium => const {
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        15,
      },
      _MarkerDensity.near => const <int>{},
    };
    return categoryIds.any(allowed.contains);
  }

  double radiusMeters({required bool isSearchMode}) {
    if (isSearchMode) return 50000;
    return switch (this) {
      _MarkerDensity.far => 36000,
      _MarkerDensity.medium => 22000,
      _MarkerDensity.near => 10000,
    };
  }

  int maxMarkers({
    required bool hasCategoryFilters,
    required bool isSearchMode,
  }) {
    if (isSearchMode) {
      return switch (this) {
        _MarkerDensity.far => 48,
        _MarkerDensity.medium => 80,
        _MarkerDensity.near => 140,
      };
    }
    if (hasCategoryFilters) {
      return switch (this) {
        _MarkerDensity.far => 56,
        _MarkerDensity.medium => 96,
        _MarkerDensity.near => 170,
      };
    }
    return switch (this) {
      _MarkerDensity.far => 28,
      _MarkerDensity.medium => 64,
      _MarkerDensity.near => 145,
    };
  }

  double cellSize({
    required bool hasCategoryFilters,
    required bool isSearchMode,
  }) {
    final base = switch (this) {
      _MarkerDensity.far => 68.0,
      _MarkerDensity.medium => 56.0,
      _MarkerDensity.near => 44.0,
    };
    return hasCategoryFilters || isSearchMode ? base * 0.82 : base;
  }

  double markerSize({required bool isSearchMode}) {
    if (isSearchMode) {
      return switch (this) {
        _MarkerDensity.far => 48,
        _MarkerDensity.medium => 56,
        _MarkerDensity.near => 68,
      };
    }
    return switch (this) {
      _MarkerDensity.far => 38,
      _MarkerDensity.medium => 48,
      _MarkerDensity.near => 64,
    };
  }
}

class _VisibleMapMarker {
  final MapPoint point;
  final double size;
  final bool showLabel;
  final bool highlighted;

  const _VisibleMapMarker({
    required this.point,
    required this.size,
    required this.showLabel,
    required this.highlighted,
  });
}
