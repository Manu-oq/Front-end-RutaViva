import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=mateo'),
          ),
          const SizedBox(height: 16),
          Text(
            "Mateo Vicuña",
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 32),
          ),
          Text("VIAJERO SUSTENTABLE", style: theme.textTheme.labelLarge),
          const SizedBox(height: 12),
          Text(
            "Dedicado a preservar el espíritu de la Araucanía a través de la exploración consciente.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
