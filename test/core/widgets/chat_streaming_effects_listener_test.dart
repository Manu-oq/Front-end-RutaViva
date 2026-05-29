import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ruta_viva/core/router/app_router.dart';
import 'package:ruta_viva/core/router/app_routes.dart';
import 'package:ruta_viva/core/storage/local_storage_provider.dart';
import 'package:ruta_viva/core/widgets/chat_streaming_effects_listener.dart';
import 'package:ruta_viva/features/chat_ai/presentation/providers/chat_provider.dart';

void main() {
  testWidgets(
    'shows in-app notification and navigates to itinerary detail from CTA',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final sharedPreferences = await SharedPreferences.getInstance();
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Home test'))),
          ),
          GoRoute(
            path: '/itineraries/:id',
            name: AppRouteNames.itineraryDetail,
            builder: (context, state) => Scaffold(
              body: Center(
                child: Text('Itinerary ${state.pathParameters['id']!}'),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          appRouterProvider.overrideWithValue(router),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            builder: (context, child) =>
                ChatStreamingEffectsListener(child: child!),
          ),
        ),
      );

      container
          .read(chatProvider.notifier)
          .setPendingNavigationForTest('iti-1');
      await tester.pump();
      await tester.pump();

      expect(find.text('Itinerario listo'), findsOneWidget);
      expect(container.read(chatPendingNavigationProvider), isNull);

      final action = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
      action.onPressed();
      await tester.pumpAndSettle();

      expect(find.text('Itinerary iti-1'), findsOneWidget);
    },
  );
}
