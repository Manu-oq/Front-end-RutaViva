import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../map/presentation/providers/map_provider.dart';

class MistNavigation extends ConsumerWidget {
  final Widget child;
  const MistNavigation({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uri = GoRouterState.of(context).uri;
    final selectedIndex = _calculateSelectedIndex(uri);
    final theme = Theme.of(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.10),
                  blurRadius: 28,
                  spreadRadius: -18,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) =>
                    _onItemTapped(index, context, ref),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Inicio',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline),
                    selectedIcon: Icon(Icons.chat_bubble),
                    label: 'Chat',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.map_outlined),
                    selectedIcon: Icon(Icons.map),
                    label: 'Mapa',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.route_outlined),
                    selectedIcon: Icon(Icons.route),
                    label: 'Rutas',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: 'Perfil',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _calculateSelectedIndex(Uri uri) {
    final path = uri.path;
    if (path.startsWith(AppRoutes.home)) return 0;
    if (path.startsWith(AppRoutes.chat)) return 1;
    if (path.startsWith(AppRoutes.map)) return 2;
    if (path.startsWith(AppRoutes.itineraryHistory)) return 3;
    if (path.startsWith(AppRoutes.profile)) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, WidgetRef ref) {
    switch (index) {
      case 0:
        context.goNamed(AppRouteNames.home);
      case 1:
        context.goNamed(AppRouteNames.chat);
      case 2:
        final mapState = ref.read(mapProvider);
        if (!mapState.isGlobalMode) {
          ref.read(mapProvider.notifier).loadNearby(center: mapState.center);
        }
        context.goNamed(AppRouteNames.map);
      case 3:
        context.goNamed(AppRouteNames.itineraryHistory);
      case 4:
        context.goNamed(AppRouteNames.profile);
    }
  }
}
