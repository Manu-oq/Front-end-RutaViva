import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/safe_navigation.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/emergency_button.dart';
import '../../../../core/widgets/inline_error_widget.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../map/domain/entities/map_point.dart';
import '../../../map/presentation/providers/map_provider.dart';
import '../widgets/destination_hero_card.dart';
import '../widgets/destination_skeleton.dart';
import '../widgets/home_header.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final state = ref.read(mapProvider);
      if (!state.isGlobalMode || (state.points.isEmpty && !state.isLoading)) {
        ref.read(mapProvider.notifier).loadNearby();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final names = ref.watch(categoriesByIdProvider);
    final secondaryPoints = mapState.points.skip(1).take(4).toList();
    final isMobile = AppResponsive.isMobile(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surfaceContainerLow,
              Theme.of(context).colorScheme.surfaceContainerLowest,
            ],
          ),
        ),
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => ref
                  .read(mapProvider.notifier)
                  .loadNearby(center: mapState.center),
              child: CustomScrollView(
                slivers: [
                  const HomeHeader(),
                  if (mapState.isLoading && mapState.points.isEmpty)
                    const DestinationSkeleton()
                  else if (mapState.points.isEmpty)
                    SliverToBoxAdapter(
                      child: _EmptyHomeState(
                        errorMessage: mapState.errorMessage,
                        onRetry: () => ref
                            .read(mapProvider.notifier)
                            .loadNearby(center: mapState.center),
                      ),
                    )
                  else ...[
                    DestinationHeroCard(
                      title: mapState.points.first.name,
                      category: mapState.points.first.categoryLabel(names),
                      description:
                          mapState.points.first.description ??
                          'Lugar disponible en Ruta Viva.',
                      imageUrl: mapState.points.first.imageUrl,
                      distanceLabel: _distanceLabel(mapState.points.first),
                      onSetRoute: () =>
                          context.pushNamedSafe(AppRouteNames.map),
                      onDetails: () => context.pushNamedSafe(
                        AppRouteNames.poiDetail,
                        pathParameters: {'id': mapState.points.first.id},
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 16 : 24,
                        0,
                        isMobile ? 16 : 24,
                        isMobile ? 120 : 160,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final point = secondaryPoints[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: AppResponsive.maxContentWidth(
                                    context,
                                  ),
                                ),
                                child: _PoiListTile(point: point),
                              ),
                            ),
                          );
                        }, childCount: secondaryPoints.length),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                top: true,
                left: true,
                right: false,
                bottom: false,
                child: EmergencyButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _distanceLabel(MapPoint point) {
    final distance = point.distanceMeters;
    if (distance == null) {
      return null;
    }
    if (distance < 1000) {
      return '${distance.round()} m';
    }
    return '${(distance / 1000).toStringAsFixed(1)} km';
  }
}

class _PoiListTile extends ConsumerWidget {
  final MapPoint point;

  const _PoiListTile({required this.point});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final names = ref.watch(categoriesByIdProvider);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(Icons.place_outlined, color: theme.colorScheme.primary),
        ),
        title: Text(point.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(point.categoryLabel(names), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => context.pushNamedSafe(
          AppRouteNames.poiDetail,
          pathParameters: {'id': point.id},
        ),
      ),
    );
  }
}

class _EmptyHomeState extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const _EmptyHomeState({required this.errorMessage, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = AppResponsive.isMobile(context);
    final hasError = errorMessage != null && errorMessage!.trim().isNotEmpty;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppResponsive.maxContentWidth(context),
        ),
        child: Padding(
          padding: AppResponsive.pagePadding(context),
          child: Container(
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(
                AppResponsive.cardRadius(context),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.travel_explore,
                  color: theme.colorScheme.secondary,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  'No hay lugares cargados todavía',
                  style: isMobile
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                if (hasError)
                  InlineErrorWidget(message: errorMessage!, onRetry: onRetry)
                else
                  Text(
                    'Intenta refrescar para buscar lugares nuevamente.',
                    style: theme.textTheme.bodyMedium,
                  ),
                const SizedBox(height: 16),
                if (!hasError)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
