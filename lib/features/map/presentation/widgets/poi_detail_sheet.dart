import 'package:flutter/material.dart';
import '../../domain/entities/map_point.dart';

class PoiDetailSheet extends StatelessWidget {
  final MapPoint point;
  const PoiDetailSheet({super.key, required this.point});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              child: Image.network(point.imageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
            )
          else
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.image_not_supported_outlined, color: theme.colorScheme.primary),
            ),
          
          const SizedBox(height: 20),

          Text(point.name, style: theme.textTheme.displayLarge?.copyWith(fontSize: 24)),
          Text(point.category.name.toUpperCase(), style: theme.textTheme.labelLarge),
          const SizedBox(height: 12),

          Text(
            point.description ?? "Un tesoro local por descubrir. Visítalo para conocer su historia de primera mano.",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: point.description == null ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          const SizedBox(height: 24),
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