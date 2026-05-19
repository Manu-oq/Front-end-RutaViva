import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../categories/presentation/category_style.dart';
import '../../domain/entities/map_point.dart';
import '../providers/map_provider.dart';
import 'poi_detail_sheet.dart';

class CustomMapMarker extends ConsumerWidget {
  final MapPoint point;
  final bool compact;
  final bool showLabel;
  final bool highlighted;

  const CustomMapMarker({
    super.key,
    required this.point,
    this.compact = false,
    this.showLabel = true,
    this.highlighted = false,
  });

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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 7 : 9),
            decoration: BoxDecoration(
              color: style.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: highlighted
                    ? theme.colorScheme.primaryContainer
                    : Colors.white,
                width: highlighted ? 4 : 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: highlighted ? 22 : 14,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              style.icon,
              color: Colors.white,
              size: compact ? 16 : 21,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: 3),
            Container(
              constraints: const BoxConstraints(maxWidth: 86),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    spreadRadius: -6,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                point.name,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
