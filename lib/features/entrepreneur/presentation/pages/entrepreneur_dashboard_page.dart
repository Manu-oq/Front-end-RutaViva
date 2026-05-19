import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/safe_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/entrepreneur_models.dart';
import '../../data/repositories/entrepreneur_repository.dart';
import '../../../map/data/models/poi_model.dart';
import '../../../map/data/repositories/poi_repository.dart';
import '../../../map/presentation/providers/map_provider.dart';

class EntrepreneurDashboardPage extends ConsumerWidget {
  const EntrepreneurDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
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
          child: user?.isEntrepreneur == true
              ? const _EntrepreneurDashboard()
              : _ActivateEntrepreneurPanel(isLoading: authState.isLoading),
        ),
      ),
      floatingActionButton: user?.isEntrepreneur == true
          ? FloatingActionButton.extended(
              onPressed: () => context.pushNamedSafe(AppRouteNames.createPoi),
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Compartir lugar'),
            )
          : null,
    );
  }
}

class _ActivateEntrepreneurPanel extends ConsumerWidget {
  final bool isLoading;

  const _ActivateEntrepreneurPanel({required this.isLoading});

  Future<void> _activate(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(authProvider.notifier)
        .activateEntrepreneurProfile();

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modo emprendedor activado.')),
      );
      ref.invalidate(myPoisProvider);
      return;
    }

    final message =
        ref.read(authProvider).errorMessage ??
        'No se pudo activar el modo emprendedor.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _HeroCard(
            title: 'Activa tu espacio emprendedor',
            subtitle:
                'Gestiona tus lugares, revisa métricas y prepara tu presencia para futuras reservas dentro de Ruta Viva.',
            badge: 'Comunidad local',
            leading: const AppBackButton(
              fallbackRouteName: AppRouteNames.profile,
              color: Colors.white,
            ),
            action: FilledButton.icon(
              onPressed: isLoading ? null : () => _activate(context, ref),
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_user_outlined),
              label: Text(isLoading ? 'Activando...' : 'Activar modo'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EntrepreneurDashboard extends ConsumerWidget {
  const _EntrepreneurDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pois = ref.watch(myPoisProvider);
    final metrics = ref.watch(entrepreneurMetricsProvider);
    final income = ref.watch(entrepreneurIncomeProvider);
    final posts = ref.watch(entrepreneurPostsProvider);

    return pois.when(
      data: (items) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myPoisProvider);
          ref.invalidate(entrepreneurMetricsProvider);
          ref.invalidate(entrepreneurIncomeProvider);
          ref.invalidate(entrepreneurPostsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroCard(
                          title: 'Panel emprendedor',
                          subtitle:
                              'Administra tus lugares publicados y revisa señales de actividad de tu comunidad viajera.',
                          badge: '${items.length} lugares publicados',
                          leading: const AppBackButton(
                            fallbackRouteName: AppRouteNames.profile,
                            color: Colors.white,
                          ),
                          action: FilledButton.icon(
                            onPressed: () =>
                                context.pushNamedSafe(AppRouteNames.createPoi),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Nuevo lugar'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _MetricGrid(
                          count: items.length,
                          metrics: metrics,
                          income: income,
                        ),
                        const SizedBox(height: 16),
                        _PostsSection(posts: posts),
                        const SizedBox(height: 16),
                        _PlacesSection(items: items),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          _DashboardError(onRetry: () => ref.invalidate(myPoisProvider)),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final Widget leading;
  final Widget action;

  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.leading,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepForest, AppColors.forest, AppColors.moss],
        ),
        boxShadow: AppColors.liftedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          action,
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final int count;
  final AsyncValue<EntrepreneurMetricsModel> metrics;
  final AsyncValue<EntrepreneurIncomeModel> income;

  const _MetricGrid({
    required this.count,
    required this.metrics,
    required this.income,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 760
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth;
        final metricData = metrics.asData?.value;
        final incomeData = income.asData?.value;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              width: width,
              icon: Icons.storefront_rounded,
              value: '$count',
              label: 'Lugares',
              detail: 'publicados',
            ),
            _MetricCard(
              width: width,
              icon: Icons.visibility_rounded,
              value: metrics.isLoading
                  ? '...'
                  : '${metricData?.visitsCount ?? 0}',
              label: 'Visitas',
              detail: '${metricData?.reviewsCount ?? 0} reseñas',
            ),
            _MetricCard(
              width: width,
              icon: Icons.payments_rounded,
              value: income.isLoading
                  ? '...'
                  : incomeData?.isPlaceholder == true
                  ? 'Próx.'
                  : _formatIncome(incomeData),
              label: 'Ganancias',
              detail: 'cuando exista pasarela',
            ),
          ],
        );
      },
    );
  }

  String _formatIncome(EntrepreneurIncomeModel? income) {
    if (income == null) return 'Próx.';
    return '${income.currency} ${income.total.round()}';
  }
}

class _PostsSection extends ConsumerWidget {
  final AsyncValue<List<EntrepreneurPostModel>> posts;

  const _PostsSection({required this.posts});

  Future<void> _openPostDialog(
    BuildContext context,
    WidgetRef ref, {
    EntrepreneurPostModel? post,
  }) async {
    final titleController = TextEditingController(text: post?.title ?? '');
    final contentController = TextEditingController(text: post?.content ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(post == null ? 'Nuevo post' : 'Editar post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Contenido'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    try {
      final repository = ref.read(entrepreneurRepositoryProvider);
      if (post == null) {
        await repository.createPost(
          title: titleController.text.trim(),
          content: contentController.text.trim(),
        );
      } else {
        await repository.updatePost(
          postId: post.id,
          title: titleController.text.trim(),
          content: contentController.text.trim(),
        );
      }
      ref.invalidate(entrepreneurPostsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post guardado.')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos guardar el post.')),
      );
    }
  }

  Future<void> _deletePost(
    BuildContext context,
    WidgetRef ref,
    EntrepreneurPostModel post,
  ) async {
    try {
      await ref.read(entrepreneurRepositoryProvider).deletePost(post.id);
      ref.invalidate(entrepreneurPostsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post eliminado.')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos eliminar el post.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Posts creados', style: theme.textTheme.titleLarge),
              ),
              FilledButton.icon(
                onPressed: () => _openPostDialog(context, ref),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Post'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          posts.when(
            data: (items) {
              if (items.isEmpty) {
                return const Text('Aún no tienes publicaciones.');
              }
              return Column(
                children: items
                    .map(
                      (post) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(post.title),
                        subtitle: Text(
                          post.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openPostDialog(context, ref, post: post);
                            } else if (value == 'delete') {
                              _deletePost(context, ref, post);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Editar')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Eliminar'),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const LinearProgressIndicator(minHeight: 3),
            error: (error, stackTrace) =>
                const Text('No pudimos cargar los posts.'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String value;
  final String label;
  final String detail;

  const _MetricCard({
    required this.width,
    required this.icon,
    required this.value,
    required this.label,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: AppColors.ambientShadow,
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: theme.textTheme.titleLarge),
                  Text(label, style: theme.textTheme.labelLarge),
                  Text(detail, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlacesSection extends ConsumerWidget {
  final List<PoiModel> items;

  const _PlacesSection({required this.items});

  Future<void> _deletePoi(
    BuildContext context,
    WidgetRef ref,
    PoiModel poi,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar lugar'),
        content: Text(
          '¿Eliminar "${poi.nombre}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(poiRepositoryProvider).deletePoi(poi.id);
      ref.invalidate(myPoisProvider);
      ref.invalidate(poiDetailProvider(poi.id));
      ref.invalidate(poiModelDetailProvider(poi.id));
      await ref.read(mapProvider.notifier).loadNearby();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lugar eliminado.')));
    } catch (error) {
      if (!context.mounted) return;
      final message = error is ApiException
          ? error.message
          : 'No se pudo eliminar el lugar.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return _EmptyPlacesCard(
        onCreate: () => context.pushNamedSafe(AppRouteNames.createPoi),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tus lugares', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        ...items.map(
          (poi) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlaceCard(
              poi: poi,
              onOpen: () => context.pushNamedSafe(
                AppRouteNames.poiDetail,
                pathParameters: {'id': poi.id},
              ),
              onEdit: () => context.pushNamedSafe(
                AppRouteNames.editPoi,
                pathParameters: {'id': poi.id},
              ),
              onDelete: () => _deletePoi(context, ref, poi),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final PoiModel poi;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlaceCard({
    required this.poi,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(
              Icons.storefront_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(poi.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${poi.categoryIds.length} categorías'),
              ],
            ),
          ),
          IconButton(
            onPressed: onOpen,
            icon: const Icon(Icons.visibility_rounded),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded)),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlacesCard extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyPlacesCard({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.add_location_alt_rounded,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Aún no tienes lugares publicados',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Comparte tu primer lugar para gestionarlo desde este panel.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Compartir lugar'),
          ),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final VoidCallback onRetry;

  const _DashboardError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Reintentar'),
      ),
    );
  }
}
