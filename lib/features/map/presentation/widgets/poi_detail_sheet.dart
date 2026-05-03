import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../domain/entities/map_point.dart';

class PoiDetailSheet extends ConsumerWidget {
  final MapPoint point;
  const PoiDetailSheet({super.key, required this.point});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final names = ref.watch(categoriesByIdProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (point.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                point.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.image_not_supported_outlined,
                color: theme.colorScheme.primary,
              ),
            ),

          const SizedBox(height: 20),

          Text(
            point.name,
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
          ),
          Text(
            point.categoryLabel(names).toUpperCase(),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 12),

          Text(
            point.description ??
                "Un tesoro local por descubrir. Visítalo para conocer su historia de primera mano.",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: point.description == null
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.pushNamed(
                  AppRouteNames.poiDetail,
                  pathParameters: {'id': point.id},
                );
              },
              icon: const Icon(Icons.info_outline),
              label: const Text('Ver detalle completo'),
            ),
          ),
          const SizedBox(height: 12),
          if (point.phone != null)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text("WhatsApp"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ],
            )
          else
            Center(
              child: Text(
                "Este emprendedor prefiere el contacto presencial.",
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
