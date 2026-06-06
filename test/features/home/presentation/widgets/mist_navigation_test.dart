import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ruta_viva/features/home/presentation/widgets/mist_navigation.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MistNavigation(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/chat',
            builder: (_, _) => const Scaffold(body: Text('Chat')),
          ),
          GoRoute(
            path: '/map',
            builder: (_, _) => const Scaffold(body: Text('Map')),
          ),
          GoRoute(
            path: '/itineraries',
            builder: (_, _) => const Scaffold(body: Text('Itineraries')),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, _) => const Scaffold(body: Text('Profile')),
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('MistNavigation responsive', () {
    testWidgets('shows BottomNavigationBar on mobile (< 600px)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = _buildRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('shows NavigationRail on tablet (>= 600px)', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = _buildRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('NavigationRail is extended when width > 800px', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = _buildRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
    });

    testWidgets('NavigationRail is not extended when width <= 800px', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(700, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = _buildRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isFalse);
    });

    testWidgets('NavigationRail Theme provides hover color on desktop', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = _buildRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final themeFinder = find.ancestor(
        of: find.byType(NavigationRail),
        matching: find.byType(Theme),
      );
      final themes = themeFinder.evaluate().toList();
      final closestTheme = themes.last.widget as Theme;
      final hoverColor = closestTheme.data.hoverColor;
      expect(hoverColor, isNotNull);
      expect(hoverColor.a, lessThan(0.12));
    });
  });
}
