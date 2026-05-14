import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ImpactSection extends StatelessWidget {
  final int loadedPois;
  final int itinerarySteps;
  final bool hasActiveSession;

  const ImpactSection({
    super.key,
    required this.loadedPois,
    required this.itinerarySteps,
    required this.hasActiveSession,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = [
      _ImpactData(
        icon: Icons.explore_rounded,
        value: loadedPois.toString(),
        label: 'Lugares',
        detail: 'para descubrir',
      ),
      _ImpactData(
        icon: Icons.route_rounded,
        value: itinerarySteps.toString(),
        label: 'Paradas',
        detail: 'en tu ruta actual',
      ),
      _ImpactData(
        icon: hasActiveSession ? Icons.lock_open_rounded : Icons.lock_outline,
        value: hasActiveSession ? 'Activa' : 'Pendiente',
        label: 'Sesión',
        detail: hasActiveSession ? 'lista para viajar' : 'vuelve a ingresar',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                'Tu actividad',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.auto_awesome_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 680;
            final itemWidth = isWide
                ? (constraints.maxWidth - 24) / 3
                : constraints.maxWidth;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: stats
                  .map(
                    (stat) => SizedBox(
                      width: itemWidth,
                      child: _ImpactCard(data: stat),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final _ImpactData data;

  const _ImpactCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: AppColors.ambientShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(data.icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  data.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactData {
  final IconData icon;
  final String value;
  final String label;
  final String detail;

  const _ImpactData({
    required this.icon,
    required this.value,
    required this.label,
    required this.detail,
  });
}
