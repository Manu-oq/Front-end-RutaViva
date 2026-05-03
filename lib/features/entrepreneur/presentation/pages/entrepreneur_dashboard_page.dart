import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../map/data/models/poi_model.dart';
import '../../../map/data/repositories/poi_repository.dart';
import '../../../map/presentation/providers/map_provider.dart';

class EntrepreneurDashboardPage extends ConsumerWidget {
  const EntrepreneurDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Panel emprendedor')),
      body: user?.isEntrepreneur == true
          ? const _EntrepreneurPoisList()
          : _ActivateEntrepreneurPanel(isLoading: authState.isLoading),
      floatingActionButton: user?.isEntrepreneur == true
          ? FloatingActionButton.extended(
              onPressed: () => context.pushNamed(AppRouteNames.createPoi),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Crear POI'),
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

    if (!context.mounted) {
      return;
    }

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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 56,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Activa tu perfil emprendedor',
            style: theme.textTheme.displayLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Al activarlo, los próximos POIs que crees quedarán asociados a tu usuario y podrás editarlos o eliminarlos desde este panel.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: isLoading ? null : () => _activate(context, ref),
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified_user_outlined),
            label: Text(
              isLoading ? 'Activando...' : 'Activar modo emprendedor',
            ),
          ),
        ],
      ),
    );
  }
}

class _EntrepreneurPoisList extends ConsumerWidget {
  const _EntrepreneurPoisList();

  Future<void> _deletePoi(
    BuildContext context,
    WidgetRef ref,
    PoiModel poi,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar POI'),
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

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(poiRepositoryProvider).deletePoi(poi.id);
      ref.invalidate(myPoisProvider);
      ref.invalidate(poiDetailProvider(poi.id));
      ref.invalidate(poiModelDetailProvider(poi.id));
      await ref.read(mapProvider.notifier).loadNearby();

      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('POI eliminado.')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : 'No se pudo eliminar el POI.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pois = ref.watch(myPoisProvider);

    return pois.when(
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.add_location_alt_outlined,
                  size: 52,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aún no tienes POIs propios',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Crea tu primer punto de interés para gestionarlo desde este panel.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => context.pushNamed(AppRouteNames.createPoi),
                  icon: const Icon(Icons.add),
                  label: const Text('Crear POI'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myPoisProvider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            itemBuilder: (context, index) {
              final poi = items[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.12,
                    ),
                    child: Icon(
                      Icons.storefront,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    poi.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${poi.categoryIds.length} categorías'),
                  onTap: () => context.pushNamed(
                    AppRouteNames.poiDetail,
                    pathParameters: {'id': poi.id},
                  ),
                  trailing: PopupMenuButton<_PoiAction>(
                    onSelected: (action) {
                      switch (action) {
                        case _PoiAction.edit:
                          context.pushNamed(
                            AppRouteNames.editPoi,
                            pathParameters: {'id': poi.id},
                          );
                          break;
                        case _PoiAction.delete:
                          _deletePoi(context, ref, poi);
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _PoiAction.edit,
                        child: Text('Editar'),
                      ),
                      PopupMenuItem(
                        value: _PoiAction.delete,
                        child: Text('Eliminar'),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemCount: items.length,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No se pudieron cargar tus POIs',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text('$error'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(myPoisProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PoiAction { edit, delete }
