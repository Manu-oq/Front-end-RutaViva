import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';

class MistNavigation extends StatelessWidget {
  final Widget child;
  const MistNavigation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final selectedIndex = _calculateSelectedIndex(uri);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
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
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Guardados',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(Uri uri) {
    final path = uri.path;
    if (path.startsWith(AppRoutes.home)) return 0;
    if (path.startsWith(AppRoutes.map)) return 1;
    if (path.startsWith(AppRoutes.itineraryHistory)) return 2;
    if (path.startsWith(AppRoutes.bookmarks)) return 3;
    if (path.startsWith(AppRoutes.profile)) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed(AppRouteNames.home);
      case 1:
        context.goNamed(AppRouteNames.map);
      case 2:
        context.goNamed(AppRouteNames.itineraryHistory);
      case 3:
        context.goNamed(AppRouteNames.bookmarks);
      case 4:
        context.goNamed(AppRouteNames.profile);
    }
  }
}
