import 'package:flutter/material.dart';

class TrailIntelligenceBox extends StatelessWidget {
  const TrailIntelligenceBox({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text('Consejos para tu ruta', style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 18),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _AdviceChip(icon: Icons.water_drop_outlined, label: 'Lleva agua'),
              _AdviceChip(
                icon: Icons.wb_sunny_outlined,
                label: 'Revisa el clima',
              ),
              _AdviceChip(
                icon: Icons.map_outlined,
                label: 'Ten el mapa a mano',
              ),
              _AdviceChip(
                icon: Icons.schedule_outlined,
                label: 'Sal con tiempo',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdviceChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AdviceChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}
