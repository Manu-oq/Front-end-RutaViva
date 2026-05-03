import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../categories/presentation/category_style.dart';
import '../../domain/entities/map_point.dart';
import '../providers/map_provider.dart';
import 'poi_detail_sheet.dart';

class CustomMapMarker extends ConsumerWidget {
  final MapPoint point;

  const CustomMapMarker({super.key, required this.point});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final style = categoryStyleFor(
      point.categoryIds.isEmpty ? null : point.categoryIds.first,
      theme.colorScheme,
    );

    return GestureDetector(
      onTap: () {
        ref.read(mapProvider.notifier).selectPoint(point);
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => PoiDetailSheet(point: point),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: style.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(style.icon, color: Colors.white, size: 20),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              point.name,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
