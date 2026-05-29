import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/safe_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/url_launcher_helper.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../bookmarks/presentation/widgets/bookmark_button.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../entrepreneur/presentation/widgets/poi_posts_view.dart';
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
  static final Set<String> _recordedVisits = <String>{};

  const PoiDetailFullPage({super.key, required this.poiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapProvider);
    final cachedPoi =
        _findPointById(mapState.visiblePoints, poiId) ??
        _findPointById(mapState.points, poiId);
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

  static void recordVisitOnce(WidgetRef ref, String poiId) {
    if (!_recordedVisits.add(poiId)) return;
    Future.microtask(() async {
      try {
        await ref.read(poiRepositoryProvider).recordVisit(poiId);
      } catch (_) {
        _recordedVisits.remove(poiId);
      }
    });
  }
}

class _PoiDetailBody extends ConsumerWidget {
  final MapPoint poi;
  final bool isRefreshing;

  const _PoiDetailBody({required this.poi, this.isRefreshing = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    PoiDetailFullPage.recordVisitOnce(ref, poi.id);
    final theme = Theme.of(context);
    final names = ref.watch(categoriesByIdProvider);
    final category = poi.categoryLabel(names);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(poiDetailProvider(poi.id));
          try {
            await ref.read(poiDetailProvider(poi.id).future);
          } catch (error) {
            debugPrint('[POI] Refresh failed for ${poi.id}: $error');
          }
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
                  constraints: BoxConstraints(
                    maxWidth: AppResponsive.maxContentWidth(context),
                  ),
                  child: Padding(
                    padding: AppResponsive.pagePadding(context),
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
                          onOpenMap: () {
                            ref.read(mapProvider.notifier).showSinglePoi(poi);
                            context.pushNamedSafe(
                              AppRouteNames.focusedMap,
                              extra: AppRouteNames.map,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        SectionCard(
                          title: 'Sobre este lugar',
                          icon: Icons.travel_explore_rounded,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                poi.description?.trim().isNotEmpty == true
                                    ? poi.description!.trim()
                                    : 'Aún no hay una descripción completa para este lugar. Puedes visitarlo, subir una foto o dejar tu opinión para ayudar a otros viajeros.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  height: 1.55,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (poi.openingHoursText != null &&
                                  poi.openingHoursText!.trim().isNotEmpty) ...[
                                const SizedBox(height: 14),
                                _InfoPill(
                                  icon: Icons.schedule_rounded,
                                  label: 'Horario: ${poi.openingHoursText}',
                                ),
                              ],
                              if (poi.visitRules?.accessNotes != null &&
                                  poi.visitRules!.accessNotes!
                                      .trim()
                                      .isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _AccessNote(text: poi.visitRules!.accessNotes!),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        PoiPostsView(poiId: poi.id),
                        if (poi.amenities != null &&
                            poi.amenities!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          SectionCard(
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
                        SectionCard(
                          title: 'Fotos de viajeros',
                          icon: Icons.photo_camera_rounded,
                          child: ImageUploadPanel(poiId: poi.id),
                        ),
                        const SizedBox(height: 16),
                        SectionCard(
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
              if (poi.visitRules?.requiresDaylight == true)
                const _DetailPill(
                  icon: Icons.wb_sunny_rounded,
                  label: 'Mejor con luz de día',
                ),
              if (poi.verificationStatus != null)
                _VerificationBadge(status: poi.verificationStatus!),
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

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
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
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessNote extends StatelessWidget {
  final String text;

  const _AccessNote({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sun.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sun.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.earth),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final MapPoint poi;

  const _ContactCard({required this.poi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
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

class _DetailPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _DetailPill({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pillForeground =
        color ?? (isDark ? const Color(0xFF8EF0A7) : theme.colorScheme.primary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: pillForeground.withValues(alpha: isDark ? 0.14 : 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: pillForeground.withValues(alpha: isDark ? 0.32 : 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: pillForeground),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: pillForeground,
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
            constraints: BoxConstraints(
              maxWidth: AppResponsive.maxContentWidth(context),
            ),
            child: Padding(
              padding: AppResponsive.pagePadding(context),
              child: Container(
                padding: EdgeInsets.all(AppResponsive.cardPadding(context)),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(
                    AppResponsive.cardRadius(context),
                  ),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  boxShadow: AppColors.ambientShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppBackButton(fallbackRouteName: AppRouteNames.map),
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

class _VerificationBadge extends StatelessWidget {
  final String status;

  const _VerificationBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (status) {
      'verified' => (
        Icons.verified_rounded,
        'Verificado',
        const Color(0xFF2E7D32),
      ),
      'pending' => (
        Icons.pending_rounded,
        'Pendiente',
        const Color(0xFFF57F17),
      ),
      'flagged' => (Icons.report_rounded, 'Reportado', const Color(0xFFC62828)),
      _ => (Icons.help_outline_rounded, 'Sin verificar', Colors.grey),
    };
    return _DetailPill(icon: icon, label: label, color: color);
  }
}
