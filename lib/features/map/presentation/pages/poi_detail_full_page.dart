import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../bookmarks/presentation/widgets/bookmark_button.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../media/presentation/widgets/image_upload_panel.dart';
import '../../../reviews/presentation/widgets/reviews_section.dart';
import '../../data/repositories/poi_repository.dart';
import '../../domain/entities/map_point.dart';
import '../providers/map_provider.dart';
import '../widgets/authenticity_seal.dart';
import '../widgets/amenity_item.dart';
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
          ? _PoiDetailBody(poi: cachedPoi)
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => cachedPoi != null
          ? _PoiDetailBody(poi: cachedPoi)
          : Scaffold(
              appBar: AppBar(),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No encontramos este punto de interés.\n$error',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
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

  const _PoiDetailBody({required this.poi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final names = ref.watch(categoriesByIdProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          PoiGalleryHeader(imageUrl: poi.imageUrl, heroTag: 'poi_${poi.id}'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        poi.categoryLabel(names).toUpperCase(),
                        style: theme.textTheme.labelLarge,
                      ),
                      const Spacer(),
                      if (poi.isLocalAuthentic) const AuthenticitySeal(),
                      BookmarkButton(poiId: poi.id, compact: true),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    poi.name,
                    style: theme.textTheme.displayLarge?.copyWith(fontSize: 32),
                  ),
                  if (poi.distanceMeters != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${(poi.distanceMeters! / 1000).toStringAsFixed(1)} km desde tu referencia',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Descripción',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    poi.description ?? 'Sin descripción disponible.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  if (poi.amenities != null) ...[
                    Text(
                      'Servicios',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 24,
                      children: poi.amenities!
                          .map((a) => AmenityItem(type: a))
                          .toList(),
                    ),
                    const SizedBox(height: 32),
                  ],
                  if (poi.phone != null)
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.chat),
                      label: Text('Contactar ${poi.phone}'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (poi.email != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.email_outlined),
                      label: Text(poi.email!),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  ImageUploadPanel(poiId: poi.id),
                  const SizedBox(height: 32),
                  ReviewsSection(poiId: poi.id),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
