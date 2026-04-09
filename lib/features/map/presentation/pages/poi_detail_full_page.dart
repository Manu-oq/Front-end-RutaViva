import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/map_provider.dart';
import '../widgets/authenticity_seal.dart';
import '../widgets/amenity_item.dart';
import '../widgets/poi_gallery_header.dart';

class PoiDetailFullPage extends ConsumerWidget {
  final String poiId;
  const PoiDetailFullPage({super.key, required this.poiId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final poi = ref.watch(mapProvider).points.firstWhere((p) => p.id == poiId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Widget Extraído
          PoiGalleryHeader(
            imageUrl: poi.imageUrl ?? '', 
            heroTag: 'poi_${poi.id}'
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(poi.category.name.toUpperCase(), style: theme.textTheme.labelLarge),
                      const Spacer(),
                      if (poi.isLocalAuthentic) const AuthenticitySeal(), 
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(poi.name, style: theme.textTheme.displayLarge?.copyWith(fontSize: 32)),
                  const SizedBox(height: 24),
                  
                  Text("Descripción", style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20)),
                  const SizedBox(height: 8),
                  Text(poi.description ?? "Sin descripción disponible.", style: theme.textTheme.bodyLarge),
                  
                  const SizedBox(height: 32),

                  if (poi.amenities != null) ...[
                    Text("Servicios", style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 24,
                      children: poi.amenities!.map((a) => AmenityItem(type: a)).toList(),
                    ),
                  ],

                  const SizedBox(height: 40),

                  if (poi.phone != null)
                    ElevatedButton.icon(
                      onPressed: () {}, 
                      icon: const Icon(Icons.chat),
                      label: const Text("Contactar por WhatsApp"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}