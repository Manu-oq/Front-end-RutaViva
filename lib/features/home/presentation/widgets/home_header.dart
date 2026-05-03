import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../map/presentation/providers/map_provider.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;
    final mapState = ref.watch(mapProvider);
    final displayName = user?.email.split('@').first ?? 'viajero';

    return SliverPadding(
      padding: const EdgeInsets.only(top: 80, left: 24, right: 32),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text('Hola, $displayName', style: theme.textTheme.headlineMedium),
          Text(
            'Explora datos reales de La Araucanía',
            style: theme.textTheme.displayLarge?.copyWith(
              color: theme.colorScheme.secondary,
              height: 0.9,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            mapState.points.isEmpty
                ? 'Ara está consultando el backend para encontrar puntos de interés cercanos.'
                : 'Ara encontró ${mapState.points.length} puntos de interés desde el backend. Usa el buscador para generar una ruta personalizada.',
            style: theme.textTheme.bodyLarge,
          ),
        ]),
      ),
    );
  }
}
