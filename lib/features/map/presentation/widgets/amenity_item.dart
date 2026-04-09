import 'package:flutter/material.dart';

class AmenityItem extends StatelessWidget {
  final String type;

  const AmenityItem({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final iconMap = {
      'wifi': Icons.wifi,
      'wc': Icons.wc,
      'parking': Icons.local_parking,
      'food': Icons.restaurant,
    };

    return Column(
      children: [
        Icon(iconMap[type] ?? Icons.help_outline, 
             color: theme.colorScheme.primary.withValues(alpha: 0.6)),
        const SizedBox(height: 4),
        Text(type.toUpperCase(), style: theme.textTheme.labelSmall),
      ],
    );
  }
}