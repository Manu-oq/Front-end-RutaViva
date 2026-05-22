import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../map/presentation/providers/map_provider.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).user;
    final mapState = ref.watch(mapProvider);
    final displayName = _firstName(user?.displayName ?? user?.email);
    final isMobile = AppResponsive.isMobile(context);

    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppResponsive.maxContentWidth(context),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              top: isMobile ? 56 : 80,
              left: isMobile ? 16 : 24,
              right: isMobile ? 16 : 24,
              bottom: 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $displayName',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Text('RUTA VIVA', style: theme.textTheme.labelLarge),
                ),
                const SizedBox(height: 14),
                Text(
                  'Descubre La Araucanía',
                  style:
                      (isMobile
                              ? theme.textTheme.displayMedium
                              : theme.textTheme.displayLarge)
                          ?.copyWith(
                            color: theme.colorScheme.primary,
                            height: isMobile ? 0.98 : 0.9,
                          ),
                ),
                SizedBox(height: isMobile ? 12 : 16),
                Text(
                  mapState.points.isEmpty
                      ? 'Ara está buscando lugares para inspirar tu próxima ruta.'
                      : 'Ara encontró ${mapState.points.length} lugares para explorar. Abre el chat para armar tu ruta personalizada.',
                  style: (isMobile
                      ? theme.textTheme.bodyMedium
                      : theme.textTheme.bodyLarge),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _firstName(String? value) {
    final normalized = value?.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
    if (normalized.isEmpty) {
      return 'viajero';
    }
    return normalized.split(' ').first;
  }
}
