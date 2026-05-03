import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../map/domain/entities/map_point.dart';
import '../../data/repositories/bookmark_repository.dart';

class BookmarksPage extends ConsumerWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bookmarks = ref.watch(bookmarkedPoisProvider);
    final names = ref.watch(categoriesByIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(bookmarkedPoisProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: bookmarks.when(
        data: (items) {
          if (items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 52,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no tienes favoritos',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Guarda lugares desde el detalle de cada POI para volver rápido a ellos.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => context.goNamed(AppRouteNames.map),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Explorar mapa'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                      Icons.place_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    poi.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(poi.categoryLabel(names)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.pushNamed(
                    AppRouteNames.poiDetail,
                    pathParameters: {'id': poi.id},
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemCount: items.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No se pudieron cargar favoritos',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text('$error'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(bookmarkedPoisProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
