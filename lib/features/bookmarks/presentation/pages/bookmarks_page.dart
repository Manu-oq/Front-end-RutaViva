import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/safe_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../map/domain/entities/map_point.dart';
import '../../data/repositories/bookmark_repository.dart';

class BookmarksPage extends ConsumerWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarkedPoisProvider);
    final categories = ref.watch(categoriesByIdProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark
                  ? theme.colorScheme.surfaceContainerLowest
                  : theme.colorScheme.surface,
              isDark
                  ? AppColors.deepForest
                  : AppColors.mint.withValues(alpha: 0.42),
              isDark
                  ? theme.colorScheme.surfaceContainerLowest
                  : theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: bookmarks.when(
            data: (items) => _BookmarksContent(
              items: items,
              categories: categories,
              onRefresh: () => ref.invalidate(bookmarkedPoisProvider),
            ),
            loading: () => _BookmarksScaffold(
              count: null,
              onRefresh: () => ref.invalidate(bookmarkedPoisProvider),
              child: const _LoadingBookmarks(),
            ),
            error: (error, stackTrace) => _BookmarksScaffold(
              count: null,
              onRefresh: () => ref.invalidate(bookmarkedPoisProvider),
              child: _BookmarksStateCard(
                icon: Icons.cloud_off_rounded,
                title: 'No pudimos cargar tus favoritos',
                message:
                    'Revisa tu conexión e intenta nuevamente para volver a ver tus lugares guardados.',
                actionLabel: 'Reintentar',
                actionIcon: Icons.refresh_rounded,
                onAction: () => ref.invalidate(bookmarkedPoisProvider),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookmarksContent extends StatelessWidget {
  final List<MapPoint> items;
  final Map<int, CategoryModel> categories;
  final VoidCallback onRefresh;

  const _BookmarksContent({
    required this.items,
    required this.categories,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _BookmarksScaffold(
        count: 0,
        onRefresh: onRefresh,
        child: _BookmarksStateCard(
          icon: Icons.bookmark_add_outlined,
          title: 'Aún no tienes favoritos',
          message:
              'Guarda lugares desde el detalle de cada punto de interés para tenerlos siempre a mano.',
          actionLabel: 'Explorar mapa',
          actionIcon: Icons.map_rounded,
          onAction: () => context.pushNamedSafe(AppRouteNames.map),
        ),
      );
    }

    return _BookmarksScaffold(
      count: items.length,
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final poi = items[index];
          return _BookmarkCard(
            poi: poi,
            categoryLabel: poi.categoryLabel(categories),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemCount: items.length,
      ),
    );
  }
}

class _BookmarksScaffold extends StatelessWidget {
  final int? count;
  final VoidCallback onRefresh;
  final Widget child;

  const _BookmarksScaffold({
    required this.count,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BookmarksHeader(count: count, onRefresh: onRefresh),
                      const SizedBox(height: 18),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarksHeader extends StatelessWidget {
  final int? count;
  final VoidCallback onRefresh;

  const _BookmarksHeader({required this.count, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countLabel = count == null
        ? 'Actualizando tus lugares guardados'
        : count == 1
        ? '1 lugar guardado'
        : '$count lugares guardados';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.forest, AppColors.moss],
        ),
        boxShadow: AppColors.liftedShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: -44,
            child: Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppBackButton(
                    fallbackRouteName: AppRouteNames.home,
                    color: Colors.white,
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    onPressed: onRefresh,
                    tooltip: 'Actualizar favoritos',
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bookmark_rounded,
                      color: AppColors.sun,
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      countLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Tus favoritos',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Un espacio para volver rápido a esos lugares que quieres visitar, recomendar o sumar a tu próxima ruta.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final MapPoint poi;
  final String categoryLabel;

  const _BookmarkCard({required this.poi, required this.categoryLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = poi.imageUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () => context.pushNamedSafe(
          AppRouteNames.poiDetail,
          pathParameters: {'id': poi.id},
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: AppColors.ambientShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: imageUrl == null || imageUrl.isEmpty
                        ? const _BookmarkImageFallback()
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const _BookmarkImageFallback(),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SoftPill(
                            icon: Icons.local_offer_rounded,
                            label: categoryLabel,
                          ),
                          if (poi.distanceMeters != null)
                            _SoftPill(
                              icon: Icons.near_me_rounded,
                              label: _formatDistance(poi.distanceMeters!),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        poi.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if ((poi.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          poi.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

class _BookmarkImageFallback extends StatelessWidget {
  const _BookmarkImageFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.mint,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
          ],
        ),
      ),
      child: Icon(
        Icons.landscape_rounded,
        color: Theme.of(context).colorScheme.primary,
        size: 34,
      ),
    );
  }
}

class _SoftPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SoftPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarksStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  const _BookmarksStateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 30),
          ),
          const SizedBox(height: 18),
          Text(
            title,
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
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAction,
            icon: Icon(actionIcon),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _LoadingBookmarks extends StatelessWidget {
  const _LoadingBookmarks();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 3 ? 0 : 12),
          child: Container(
            height: 118,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
