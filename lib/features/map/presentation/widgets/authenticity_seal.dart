import 'package:flutter/material.dart';

class AuthenticitySeal extends StatelessWidget {
  const AuthenticitySeal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        "Sello de Autenticidad", 
        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary)
      ),
    );
  }
}