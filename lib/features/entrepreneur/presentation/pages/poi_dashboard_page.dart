import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/inline_error_widget.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../map/data/models/poi_model.dart';
import '../../../map/data/repositories/poi_repository.dart';
import '../../../reviews/presentation/widgets/reviews_section.dart';
import '../../data/models/entrepreneur_models.dart';
import '../../data/repositories/entrepreneur_repository.dart';

class PoiDashboardPage extends ConsumerWidget {
  final String poiId;

  const PoiDashboardPage({super.key, required this.poiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poiAsync = ref.watch(poiModelDetailProvider(poiId));

    return poiAsync.when(
      data: (poi) => _PoiDashboardBody(poi: poi),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => _PoiDashboardError(
        poiId: poiId,
        message: error is ApiException
            ? error.message
            : 'No se pudo cargar el lugar.',
      ),
    );
  }
}

class _PoiDashboardError extends ConsumerWidget {
  final String poiId;
  final String message;

  const _PoiDashboardError({required this.poiId, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    const AppBackButton(
                      fallbackRouteName: AppRouteNames.entrepreneur,
                    ),
                    const SizedBox(height: 12),
                    Icon(
                      Icons.analytics_outlined,
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
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () =>
                          ref.invalidate(poiModelDetailProvider(poiId)),
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

class _PoiDashboardBody extends ConsumerWidget {
  final PoiModel poi;

  const _PoiDashboardBody({required this.poi});

  Future<void> _refreshDashboard(WidgetRef ref) async {
    ref.invalidate(poiAnalyticsProvider(poi.id));
    ref.invalidate(poiActivityProvider(poi.id));
    ref.invalidate(poiPostsProvider(poi.id));
    try {
      await Future.wait([
        ref.read(poiAnalyticsProvider(poi.id).future),
        ref.read(poiActivityProvider(poi.id).future),
        ref.read(poiPostsProvider(poi.id).future),
      ]);
    } catch (error) {
      debugPrint('[POI dashboard] Refresh failed for ${poi.id}: $error');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(poiAnalyticsProvider(poi.id));
    final activity = ref.watch(poiActivityProvider(poi.id));
    final names = ref.watch(categoriesByIdProvider);
    final category = _categoryLabel(poi.categoryIds, names);
    final isMobile = AppResponsive.isMobile(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refreshDashboard(ref),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: isMobile ? 240 : 320,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.deepForest,
              foregroundColor: Colors.white,
              leading: const AppBackButton(
                fallbackRouteName: AppRouteNames.entrepreneur,
                color: Colors.white,
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(72, 0, 20, 12),
                title: _PoiDashboardTitle(poi: poi, category: category),
                background: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.deepForest,
                        AppColors.forest,
                        AppColors.moss,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: AppResponsive.value<double>(
                      context,
                      mobile: double.infinity,
                      tablet: 860,
                      desktop: 900,
                    ),
                  ),
                  child: Padding(
                    padding: AppResponsive.value<EdgeInsets>(
                      context,
                      mobile: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      tablet: const EdgeInsets.fromLTRB(20, 20, 20, 112),
                      desktop: const EdgeInsets.fromLTRB(20, 20, 20, 112),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AnalyticsSection(analytics: analytics, poiId: poi.id),
                        const SizedBox(height: 16),
                        _PerformanceSection(
                          analytics: analytics,
                          poiId: poi.id,
                        ),
                        const SizedBox(height: 16),
                        SectionCard(
                          title: 'Actividad reciente',
                          icon: Icons.timeline_rounded,
                          child: _ActivityFeed(
                            activity: activity,
                            poiId: poi.id,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SectionCard(
                          title: 'Opiniones',
                          icon: Icons.reviews_rounded,
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

  String _categoryLabel(List<int> ids, Map<int, CategoryModel> names) {
    for (final id in ids) {
      final category = names[id];
      if (category != null) return category.name;
    }
    return 'Sin categoria';
  }
}

class _PoiDashboardTitle extends StatelessWidget {
  final PoiModel poi;
  final String category;

  const _PoiDashboardTitle({required this.poi, required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.84),
            fontSize: 9.5,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          poi.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontSize: 13.5,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _AnalyticsSection extends ConsumerWidget {
  final AsyncValue<PoiAnalyticsModel> analytics;
  final String poiId;

  const _AnalyticsSection({required this.analytics, required this.poiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = analytics.asData?.value;

    if (analytics.isLoading && data == null) {
      return const SectionCard(
        title: 'Estadisticas',
        icon: Icons.analytics_rounded,
        child: _AnalyticsSkeleton(),
      );
    }

    if (analytics.hasError && data == null) {
      return SectionCard(
        title: 'Estadisticas',
        icon: Icons.analytics_rounded,
        child: InlineErrorWidget(
          message: 'No se pudieron cargar las metricas.',
          onRetry: () => ref.invalidate(poiAnalyticsProvider(poiId)),
        ),
      );
    }

    return SectionCard(
      title: 'Estadisticas',
      icon: Icons.analytics_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = AppResponsive.isMobile(context);
          final isWide = constraints.maxWidth > 620;
          final cardWidth = isWide
              ? (constraints.maxWidth - 16) / 3
              : isMobile
              ? constraints.maxWidth
              : (constraints.maxWidth - 8) / 2;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AnalyticCard(
                width: cardWidth,
                icon: Icons.remove_red_eye_rounded,
                value: '${data?.visitsCount ?? 0}',
                label: 'Visitas',
              ),
              _AnalyticCard(
                width: cardWidth,
                icon: Icons.bookmark_rounded,
                value: '${data?.favoritesCount ?? 0}',
                label: 'Favoritos',
              ),
              _AnalyticCard(
                width: cardWidth,
                icon: Icons.reviews_rounded,
                value: '${data?.reviewsCount ?? 0}',
                label: 'Resenas',
              ),
              _AnalyticCard(
                width: cardWidth,
                icon: Icons.star_rounded,
                value: data?.avgRating != null
                    ? data!.avgRating.toStringAsFixed(1)
                    : '-',
                label: 'Promedio',
                accentColor: AppColors.sun,
                subtitle: 'de 5 estrellas',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnalyticsSkeleton extends StatelessWidget {
  const _AnalyticsSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 520;
        final isMobile = AppResponsive.isMobile(context);
        final cardWidth = isWide
            ? (constraints.maxWidth - 16) / 3
            : isMobile
            ? constraints.maxWidth
            : (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(5, (_) {
            return SizedBox(
              width: cardWidth,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _AnalyticCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String value;
  final String label;
  final String? subtitle;
  final Color? accentColor;

  const _AnalyticCard({
    required this.width,
    required this.icon,
    required this.value,
    required this.label,
    this.subtitle,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.colorScheme.primary;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PerformanceSection extends ConsumerWidget {
  final AsyncValue<PoiAnalyticsModel> analytics;
  final String poiId;

  const _PerformanceSection({required this.analytics, required this.poiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final data = analytics.asData?.value;

    if (analytics.isLoading && data == null) {
      return SectionCard(
        title: 'Rendimiento temporal',
        icon: Icons.trending_up_rounded,
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      );
    }

    if (analytics.hasError && data == null) {
      return SectionCard(
        title: 'Rendimiento temporal',
        icon: Icons.trending_up_rounded,
        child: InlineErrorWidget(
          message: 'No se pudo cargar el rendimiento.',
          onRetry: () => ref.invalidate(poiAnalyticsProvider(poiId)),
        ),
      );
    }

    return SectionCard(
      title: 'Rendimiento temporal',
      icon: Icons.trending_up_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PerformanceRow(
            icon: Icons.calendar_view_week_rounded,
            value: '${data?.weeklyVisits ?? 0}',
            label: 'Visitas esta semana',
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          _PerformanceRow(
            icon: Icons.show_chart_rounded,
            value:
                '${data?.monthlyGrowth != null ? data!.monthlyGrowth.toStringAsFixed(1) : '0.0'}%',
            label: 'Crecimiento mensual',
            color: AppColors.leaf,
            positive: (data?.monthlyGrowth ?? 0) >= 0,
          ),
        ],
      ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool positive;

  const _PerformanceRow({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.positive = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    if (icon == Icons.show_chart_rounded) ...[
                      const SizedBox(width: 6),
                      Icon(
                        positive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: color,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityFeed extends ConsumerWidget {
  final AsyncValue<List<PoiActivityEvent>> activity;
  final String poiId;

  const _ActivityFeed({required this.activity, required this.poiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return activity.when(
      data: (items) {
        if (items.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.event_note_rounded,
            message: 'Aun no hay actividad registrada para este lugar.',
          );
        }
        return Column(
          children: items
              .take(10)
              .map((event) => _ActivityEventTile(event: event))
              .toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: LinearProgressIndicator(minHeight: 3),
      ),
      error: (_, _) => InlineErrorWidget(
        message: 'No se pudo cargar la actividad.',
        onRetry: () => ref.invalidate(poiActivityProvider(poiId)),
      ),
    );
  }
}

class _ActivityEventTile extends StatelessWidget {
  final PoiActivityEvent event;

  const _ActivityEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _eventIcon(event.type);
    final label = _eventLabel(event.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 17, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                Text(
                  _formatTimestamp(event.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _eventIcon(String type) {
    if (type == 'new_review' || type == 'review') return Icons.reviews_rounded;
    if (type == 'new_favorite' || type == 'favorite') {
      return Icons.bookmark_added_rounded;
    }
    if (type == 'new_post' || type == 'post') return Icons.campaign_rounded;
    if (type == 'new_visit' || type == 'visit') return Icons.visibility_rounded;
    return Icons.notifications_rounded;
  }

  String _eventLabel(String type) {
    if (type == 'new_review' || type == 'review') {
      return 'Nueva resena recibida';
    }
    if (type == 'new_favorite' || type == 'favorite') return 'Nuevo favorito';
    if (type == 'new_post' || type == 'post') return 'Nuevo post del lugar';
    if (type == 'new_visit' || type == 'visit') return 'Nueva visita al lugar';
    return 'Actividad reciente';
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} dias';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
