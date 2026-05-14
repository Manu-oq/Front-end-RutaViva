import 'package:flutter/material.dart';

class AmenityItem extends StatelessWidget {
  final String type;

  const AmenityItem({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _iconFor(type);
    final label = _labelFor(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String value) {
    final normalized = value.toLowerCase().trim();
    return switch (normalized) {
      'wifi' => Icons.wifi_rounded,
      'wc' || 'bathroom' || 'baño' || 'banos' || 'baños' => Icons.wc_rounded,
      'parking' || 'estacionamiento' => Icons.local_parking_rounded,
      'food' || 'restaurant' || 'comida' => Icons.restaurant_rounded,
      'pets' || 'pet_friendly' => Icons.pets_rounded,
      'accessible' || 'accessibility' => Icons.accessible_rounded,
      _ => Icons.check_circle_outline_rounded,
    };
  }

  String _labelFor(String value) {
    final normalized = value.toLowerCase().trim();
    return switch (normalized) {
      'wifi' => 'Wi‑Fi',
      'wc' || 'bathroom' || 'baño' || 'banos' || 'baños' => 'Baños',
      'parking' || 'estacionamiento' => 'Estacionamiento',
      'food' || 'restaurant' || 'comida' => 'Comida',
      'pets' || 'pet_friendly' => 'Mascotas',
      'accessible' || 'accessibility' => 'Accesible',
      _ => value,
    };
  }
}
