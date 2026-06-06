import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_viva/features/auth/data/models/user_model.dart';
import 'package:ruta_viva/features/auth/presentation/providers/auth_provider.dart';
import 'package:ruta_viva/features/entrepreneur/data/models/entrepreneur_models.dart';
import 'package:ruta_viva/features/entrepreneur/presentation/pages/entrepreneur_dashboard_page.dart';
import 'package:ruta_viva/features/map/data/models/poi_model.dart';
import 'package:ruta_viva/features/map/data/repositories/poi_repository.dart';
import 'package:ruta_viva/features/entrepreneur/data/repositories/entrepreneur_repository.dart';

class _FakeAuthNotifier extends AuthNotifier {
  final AuthState _state;
  _FakeAuthNotifier(this._state);

  @override
  AuthState build() => _state;
}

void main() {
  group('EntrepreneurDashboardPage grid', () {
    Widget buildDashboard() {
      return ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => _FakeAuthNotifier(
              AuthState(
                user: UserModel(
                  id: 'u1',
                  email: 'e@test.com',
                  isActive: true,
                  createdAt: DateTime(2025),
                  entrepreneurProfile: const EntrepreneurProfileModel(
                    userId: 'u1',
                    rut: '12345678-9',
                  ),
                ),
                token: 'tok',
              ),
            ),
          ),
          entrepreneurPoisProvider.overrideWith((ref) async {
            return [
              _poi('Lugar 1'),
              _poi('Lugar 2'),
              _poi('Lugar 3'),
              _poi('Lugar 4'),
            ];
          }),
          entrepreneurMetricsProvider.overrideWith((ref) async {
            return const EntrepreneurMetricsModel(
              placesCount: 4,
              visitsCount: 10,
              reviewsCount: 2,
              favoritesCount: 1,
            );
          }),
          entrepreneurIncomeProvider.overrideWith((ref) async {
            return const EntrepreneurIncomeModel(
              grossIncome: 0,
              netIncome: 0,
              pendingIncome: 0,
              currency: 'CLP',
              status: 'not_configured',
              detail: '',
            );
          }),
        ],
        child: const MaterialApp(home: EntrepreneurDashboardPage()),
      );
    }

    testWidgets('mobile uses a vertical list', (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsNothing);
      expect(find.byType(ListView), findsWidgets);
      expect(find.text('Lugar 1'), findsOneWidget);
    });

    testWidgets('tablet uses 2 grid columns', (tester) async {
      tester.view.physicalSize = const Size(750, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals(2));
    });

    testWidgets('desktop uses 3 grid columns', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals(3));
    });

    testWidgets('desktop renders Scrollbar', (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.byType(Scrollbar), findsOneWidget);
    });
  });
}

PoiModel _poi(String name) {
  return PoiModel(
    id: 'poi-$name',
    name: name,
    description: 'Desc',
    accessType: 'public',
    categoryIds: const [1],
    latitude: -39.0,
    longitude: -71.0,
  );
}
