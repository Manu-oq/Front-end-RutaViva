import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/router/safe_navigation.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/inline_error_widget.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../data/models/poi_model.dart';
import '../../data/repositories/poi_repository.dart';

class MyContributionsPage extends ConsumerWidget {
  const MyContributionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributions = ref.watch(myPoisProvider);
    final categoriesById = ref.watch(categoriesByIdProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRouteName: AppRouteNames.profile),
        title: const Text('Mis contribuciones'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(myPoisProvider.future),
        child: contributions.when(
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: const [_EmptyContributions()],
              );
            }
            return ListView.separated(
              padding: AppResponsive.pagePadding(context),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final poi = items[index];
                final category = poi.categoryIds.isEmpty
                    ? 'Sin categoría'
                    : categoriesById[poi.categoryIds.first]?.name ??
                          'Sin categoría';
                return _ContributionCard(poi: poi, category: category);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              InlineErrorWidget(
                message: 'No pudimos cargar tus contribuciones.',
                onRetry: () => ref.invalidate(myPoisProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContributionCard extends ConsumerWidget {
  final PoiModel poi;
  final String category;

  const _ContributionCard({required this.poi, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final editable = _isEditableWindow(poi.createdAt);
    final status = _statusLabel(poi.verificationStatus);
    final hoursLeft = _remainingHours(poi.createdAt);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poi.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(label: status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Creado: ${_createdAtLabel(poi.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            _EditWindowChip(remainingHours: hoursLeft, theme: theme),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.pushNamedSafe(
                    AppRouteNames.poiDetail,
                    pathParameters: {'id': poi.id},
                  ),
                  icon: const Icon(Icons.place_outlined),
                  label: const Text('Ver lugar'),
                ),
                if (editable) ...[
                  OutlinedButton.icon(
                    onPressed: () => context.pushNamedSafe(
                      AppRouteNames.editPoi,
                      pathParameters: {'id': poi.id},
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context, ref),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Borrar'),
                  ),
                ] else
                  OutlinedButton.icon(
                    onPressed: () => _reportError(context),
                    icon: const Icon(Icons.report_problem_outlined),
                    label: const Text('Reportar error'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isEditableWindow(DateTime? createdAt) {
    return _remainingHours(createdAt) > 0;
  }

  int _remainingHours(DateTime? createdAt) {
    if (createdAt == null) return 0;
    final remaining = 24 - DateTime.now().difference(createdAt).inHours;
    return remaining.clamp(0, 24);
  }

  String _createdAtLabel(DateTime? createdAt) {
    if (createdAt == null) return 'Sin fecha';
    return '${shortDate(createdAt)}/${createdAt.year}';
  }

  String _statusLabel(String? rawStatus) {
    final status = rawStatus?.toLowerCase().trim();
    return switch (status) {
      'verified' || 'verificado' => 'Verificado',
      _ => 'Pendiente',
    };
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar contribución'),
        content: Text('¿Quieres borrar "${poi.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(poiRepositoryProvider).deletePoi(poi.id);
      ref.invalidate(myPoisProvider);
      ref.invalidate(entrepreneurPoisProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Contribución borrada.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No pudimos borrar la contribución.')),
      );
    }
  }

  void _reportError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cuéntanos qué debemos corregir.')),
    );
  }
}

class _EditWindowChip extends StatelessWidget {
  final int remainingHours;
  final ThemeData theme;

  const _EditWindowChip({required this.remainingHours, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (remainingHours <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Edición cerrada (24h)',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Editable ${remainingHours}h más',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verified = label == 'Verificado';
    final color = verified
        ? theme.colorScheme.primary
        : theme.colorScheme.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyContributions extends StatelessWidget {
  const _EmptyContributions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_location_alt_outlined,
            size: 42,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Aún no tienes contribuciones',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Comparte lugares de La Araucanía para ayudar a otros viajeros.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
