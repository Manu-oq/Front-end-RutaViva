import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ruta_viva/core/network/dio_client.dart';
import 'package:ruta_viva/core/router/app_router.dart';
import 'package:ruta_viva/core/router/app_routes.dart';
import 'package:ruta_viva/features/categories/data/models/category_model.dart';
import 'package:ruta_viva/features/categories/data/repositories/category_repository.dart';
import 'package:ruta_viva/features/auth/data/models/user_model.dart';
import 'package:ruta_viva/features/auth/presentation/providers/auth_provider.dart';
import 'package:ruta_viva/features/map/data/models/poi_model.dart';
import 'package:ruta_viva/features/map/data/repositories/poi_repository.dart';

final _testUser = UserModel(
  id: 'test-id',
  email: 'test@test.com',
  isActive: true,
  createdAt: DateTime(2025),
);

String? _appRedirect(AuthState authState, String location) {
  final isPublicAuthRoute =
      location == AppRoutes.login || location == AppRoutes.register;
  final isAuthenticated = authState.isAuthenticated;
  final isRestoringSession = authState.isLoading && authState.token != null;

  if (isRestoringSession) return null;
  if (!isAuthenticated && !isPublicAuthRoute) return AppRoutes.login;
  if (isAuthenticated && isPublicAuthRoute) return AppRoutes.home;

  return null;
}

void main() {
  group('appRouter redirect logic', () {
    group('unauthenticated user', () {
      test('redirects to /login from protected route /home', () {
        final result = _appRedirect(const AuthState(), AppRoutes.home);
        expect(result, equals(AppRoutes.login));
      });

      test('redirects to /login from protected route /map', () {
        final result = _appRedirect(const AuthState(), AppRoutes.map);
        expect(result, equals(AppRoutes.login));
      });

      test('redirects to /login from protected route /map/focused', () {
        final result = _appRedirect(const AuthState(), AppRoutes.focusedMap);
        expect(result, equals(AppRoutes.login));
      });

      test('redirects to /login from protected route /profile', () {
        final result = _appRedirect(const AuthState(), AppRoutes.profile);
        expect(result, equals(AppRoutes.login));
      });

      test('stays on /login without redirect', () {
        final result = _appRedirect(const AuthState(), AppRoutes.login);
        expect(result, isNull);
      });

      test('stays on /register without redirect', () {
        final result = _appRedirect(const AuthState(), AppRoutes.register);
        expect(result, isNull);
      });
    });

    group('authenticated user', () {
      final authed = AuthState(user: _testUser, token: 'tok');

      test('redirects to /home when on /login', () {
        final result = _appRedirect(authed, AppRoutes.login);
        expect(result, equals(AppRoutes.home));
      });

      test('redirects to /home when on /register', () {
        final result = _appRedirect(authed, AppRoutes.register);
        expect(result, equals(AppRoutes.home));
      });

      test('stays on protected route /home without redirect', () {
        final result = _appRedirect(authed, AppRoutes.home);
        expect(result, isNull);
      });

      test('stays on protected route /map without redirect', () {
        final result = _appRedirect(authed, AppRoutes.map);
        expect(result, isNull);
      });

      test('stays on protected route /map/focused without redirect', () {
        final result = _appRedirect(authed, AppRoutes.focusedMap);
        expect(result, isNull);
      });

      test('stays on /profile without redirect', () {
        final result = _appRedirect(authed, AppRoutes.profile);
        expect(result, isNull);
      });
    });

    group('restoring session', () {
      const restoring = AuthState(token: 'restoring-tok', isLoading: true);

      test('does not redirect from /map', () {
        final result = _appRedirect(restoring, AppRoutes.map);
        expect(result, isNull);
      });

      test('does not redirect from /login', () {
        final result = _appRedirect(restoring, AppRoutes.login);
        expect(result, isNull);
      });

      test('does not redirect from /home', () {
        final result = _appRedirect(restoring, AppRoutes.home);
        expect(result, isNull);
      });
    });
  });

  group('appRouter create POI route', () {
    testWidgets(
      '/pois/create?creationType=entrepreneur pasa param a CreatePoiPage',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(
              () => _NotifierWithState(
                AuthState(user: _testUser, token: 'token'),
              ),
            ),
            categoriesProvider.overrideWith((ref) async => _categories),
            poiRepositoryProvider.overrideWith((ref) => _FakePoiRepository()),
          ],
        );
        addTearDown(container.dispose);

        final router = container.read(appRouterProvider);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        router.go('/pois/create?creationType=entrepreneur');
        await tester.pumpAndSettle();

        expect(find.text('Publica tu negocio'), findsOneWidget);
        expect(find.text('Contacto del negocio'), findsOneWidget);
        expect(find.text('Teléfono público obligatorio'), findsOneWidget);
      },
    );
  });
}

class _FakePoiRepository extends PoiRepository {
  _FakePoiRepository() : super(DioClient(Dio()));

  @override
  Future<List<PoiModel>> searchNearby({
    required double lat,
    required double lon,
    double radius = 30000,
    List<int> categoryIds = const [],
  }) async {
    return const [];
  }
}

const _categories = [CategoryModel(id: 1, name: 'Naturaleza')];

class _NotifierWithState extends AuthNotifier {
  final AuthState _fakeState;

  _NotifierWithState(this._fakeState);

  @override
  AuthState build() => _fakeState;
}
