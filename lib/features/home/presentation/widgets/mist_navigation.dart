import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/glass_container.dart';

class MistNavigation extends StatelessWidget {
  const MistNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GlassContainer(
      blur: 40,
      opacity: 0.8,
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.auto_awesome, color: theme.colorScheme.secondary),
              onPressed: () => context.go('/chat'),
            ),
            IconButton(
              icon: const Icon(Icons.map_outlined, color: Colors.grey),
              onPressed: () => context.push('/map'),
            ),
            IconButton(
              icon: const Icon(Icons.explore_outlined, color: Colors.grey),
              onPressed: () => context.push('/onboarding'),
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.grey),
              onPressed: () => context.go('/profile'),
            ),
          ],
        ),
      ),
    );
  }
}