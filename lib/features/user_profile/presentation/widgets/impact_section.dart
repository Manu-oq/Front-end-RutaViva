import 'package:flutter/material.dart';

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ImpactStat(value: loadedPois.toString(), label: 'POIS'),
          _ImpactStat(value: itinerarySteps.toString(), label: 'PARADAS'),
          _ImpactStat(value: hasActiveSession ? 'OK' : 'NO', label: 'SESIÓN'),
        ],
      ),
    );
  }
}

class _ImpactStat extends StatelessWidget {
  final String value;
  final String label;

  const _ImpactStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
