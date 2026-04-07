import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverPadding(
      padding: const EdgeInsets.only(top: 80, left: 24, right: 32),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text("Buenos días,", style: theme.textTheme.headlineMedium),
          Text(
            "Explora el sur de Chile", 
            style: theme.textTheme.displayLarge?.copyWith(
              color: theme.colorScheme.secondary,
              height: 0.9,
            )
          ),
          const SizedBox(height: 16),
          Text(
            "Ara está escuchando. La niebla se levanta sobre Villarrica y revela senderos que pocos han visto.",
            style: theme.textTheme.bodyLarge,
          ),
        ]),
      ),
    );
  }
}