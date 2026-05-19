import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class _NavigationLock {
  static final Set<String> _activePushes = <String>{};

  static bool acquire(String key) => _activePushes.add(key);

  static void release(String key) {
    _activePushes.remove(key);
  }
}

extension SafeNavigation on BuildContext {
  Future<T?> pushNamedSafe<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
    bool skipIfSameLocation = true,
  }) {
    final targetLocation = _namedLocationOrNull(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
    );
    final lockKey = targetLocation ?? '$name|$pathParameters|$queryParameters';

    if (skipIfSameLocation && targetLocation != null) {
      final currentLocation = _currentLocationOrNull();
      if (currentLocation == targetLocation) {
        return Future<T?>.value();
      }
    }

    if (!_NavigationLock.acquire(lockKey)) {
      return Future<T?>.value();
    }

    late final Future<T?> future;
    try {
      future = pushNamed<T>(
        name,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: extra,
      );
    } catch (_) {
      _NavigationLock.release(lockKey);
      rethrow;
    }
    unawaited(
      future.whenComplete(() async {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        _NavigationLock.release(lockKey);
      }),
    );
    return future;
  }

  String? _namedLocationOrNull(
    String name, {
    required Map<String, String> pathParameters,
    required Map<String, dynamic> queryParameters,
  }) {
    try {
      return GoRouter.of(this).namedLocation(
        name,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
      );
    } catch (_) {
      return null;
    }
  }

  String? _currentLocationOrNull() {
    try {
      return GoRouterState.of(this).uri.toString();
    } catch (_) {
      return null;
    }
  }
}
