import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/url_launcher_helper.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../bookmarks/presentation/widgets/bookmark_button.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../media/presentation/widgets/image_upload_panel.dart';
import '../../../reviews/presentation/widgets/reviews_section.dart';
import '../../data/repositories/poi_repository.dart';
import '../../domain/entities/map_point.dart';
import '../providers/map_provider.dart';
import '../widgets/amenity_item.dart';
import '../widgets/authenticity_seal.dart';
import '../widgets/poi_gallery_header.dart';

class PoiDetailFullPage extends ConsumerWidget {
  final String poiId;
  const PoiDetailFullPage({super.key, required this.poiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedPoi = _findPointById(ref.watch(mapProvider).points, poiId);
    final asyncPoi = ref.watch(poiDetailProvider(poiId));

    return asyncPoi.when(
      data: (poi) => _PoiDetailBody(poi: poi),
      loading: () => cachedPoi != null
          ? _PoiDetailBody(poi: cachedPoi, isRefreshing: true)
          : const _PoiLoadingPage(),
      error: (error, stackTrace) => cachedPoi != null
          ? _PoiDetailBody(poi: cachedPoi)
          : _PoiErrorPage(
              onRetry: () => ref.invalidate(poiDetailProvider(poiId)),
            ),
    );
  }

  static MapPoint? _findPointById(List<MapPoint> points, String poiId) {
    for (final point in points) {
      if (point.id == poiId) {
        return point;
      }
    }
    return null;
  }
}

class _PoiDetailBody extends ConsumerWidget {
  final MapPoint poi;
  final bool isRefreshing;

  const _PoiDetailBody({required this.poi, this.isRefreshing = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final names = ref.watch(categoriesByIdProvider);
    final category = poi.categoryLabel(names);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(poiDetailProvider(poi.id));
        },
        child: CustomScrollView(
          slivers: [
            PoiGalleryHeader(
              imageUrl: poi.imageUrl,
              heroTag: 'poi_${poi.id}',
              title: poi.name,
              subtitle: category,
              trailing: BookmarkButton(poiId: poi.id, compact: true),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isRefreshing) ...[
                          const LinearProgressIndicator(minHeight: 3),
                          const SizedBox(height: 14),
                        ],
                        _TitleCard(
                          poi: poi,
                          category: category,
                          onOpenMap: () => context.goNamed(AppRouteNames.map),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Sobre este lugar',
                          icon: Icons.travel_explore_rounded,
                          child: Text(
                            poi.description?.trim().isNotEmpty == true
                                ? poi.description!.trim()
                                : 'Aún no hay una descripción completa para este lugar. Puedes visitarlo, subir una foto o dejar tu opinión para ayudar a otros viajeros.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.55,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (poi.amenities != null &&
                            poi.amenities!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Servicios disponibles',
                            icon: Icons.check_circle_rounded,
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: poi.amenities!
                                  .map((item) => AmenityItem(type: item))
                                  .toList(),
                            ),
                          ),
                        ],
                        if (poi.phone != null || poi.email != null) ...[
                          const SizedBox(height: 16),
                          _ContactCard(poi: poi),
                        ],
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Fotos de viajeros',
                          icon: Icons.photo_camera_rounded,
                          child: ImageUploadPanel(poiId: poi.id),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Comunidad viajera',
                          icon: Icons.forum_rounded,
                          child: ReviewsSection(poiId: poi.id),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleCard extends StatelessWidget {
  final MapPoint poi;
  final String category;
  final VoidCallback onOpenMap;

  const _TitleCard({
    required this.poi,
    required this.category,
    required this.onOpenMap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DetailPill(icon: Icons.local_offer_rounded, label: category),
              if (poi.distanceMeters != null)
                _DetailPill(
                  icon: Icons.near_me_rounded,
                  label: _formatDistance(poi.distanceMeters!),
                ),
              if (poi.isLocalAuthentic) const AuthenticitySeal(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            poi.name,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Guárdalo, revisa sus datos y súmalo a tu próxima salida por La Araucanía.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onOpenMap,
            icon: const Icon(Icons.map_rounded),
            label: const Text('Ver en el mapa'),
          ),
        ],
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m de distancia';
    return '${(meters / 1000).toStringAsFixed(1)} km de distancia';
  }
}

class _ContactCard extends StatelessWidget {
  final MapPoint poi;

  const _ContactCard({required this.poi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SectionCard(
      title: 'Contacto',
      icon: Icons.support_agent_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Comunícate directamente con este lugar para consultar horarios, reservas o disponibilidad.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          if (poi.phone != null) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () =>
                  UrlLauncherHelper.launchPhone(context, poi.phone!),
              icon: const Icon(Icons.phone_rounded),
              label: Text('Llamar ${poi.phone}'),
            ),
          ],
          if (poi.email != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => UrlLauncherHelper.launchEmail(
                context,
                poi.email!,
                subject: 'Consulta desde Ruta Viva',
              ),
              icon: const Icon(Icons.mail_rounded),
              label: Text(poi.email!),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PoiLoadingPage extends StatelessWidget {
  const _PoiLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _PoiErrorPage extends StatelessWidget {
  final VoidCallback onRetry;

  const _PoiErrorPage({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  boxShadow: AppColors.ambientShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppBackButton(
                      fallbackRouteName: AppRouteNames.map,
                      usePop: false,
                    ),
                    const SizedBox(height: 12),
                    Icon(
                      Icons.place_outlined,
                      size: 46,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No encontramos este lugar',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Puede que ya no esté disponible o que la conexión haya fallado. Intenta nuevamente.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
