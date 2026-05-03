import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String displayName;
  final String subtitle;
  final String supportingText;

  const ProfileHeader({
    super.key,
    required this.displayName,
    required this.subtitle,
    required this.supportingText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : 'R';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: theme.colorScheme.secondary.withValues(
              alpha: 0.18,
            ),
            child: Text(
              initial,
              style: theme.textTheme.displayLarge?.copyWith(
                color: theme.colorScheme.secondary,
                fontSize: 42,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 32),
          ),
          Text(subtitle, style: theme.textTheme.labelLarge),
          const SizedBox(height: 12),
          Text(
            supportingText,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
