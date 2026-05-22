import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class _NavigationLock {
  static const _debounceDuration = Duration(milliseconds: 650);
  static final Set<String> _activePushes = <String>{};
  static final Map<String, Timer> _timers = <String, Timer>{};

  static bool acquire(String key) {
    if (!_activePushes.add(key)) {
      return false;
    }
    _timers[key]?.cancel();
    _timers[key] = Timer(_debounceDuration, () => release(key));
    return true;
  }

  static void release(String key) {
    _timers.remove(key)?.cancel();
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
        debugPrint(
          '[Navigation] Skipping push to same location: $targetLocation',
        );
        return Future<T?>.value();
      }
    }

    if (!_NavigationLock.acquire(lockKey)) {
      debugPrint('[Navigation] Blocked duplicate push: $lockKey');
      return Future<T?>.value();
    }

    try {
      debugPrint('[Navigation] pushNamedSafe: $name -> $lockKey');
      return pushNamed<T>(
        name,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: extra,
      );
    } catch (error) {
      debugPrint('[Navigation] pushNamedSafe failed for $name: $error');
      _NavigationLock.release(lockKey);
      rethrow;
    }
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
    } catch (error) {
      debugPrint('[Navigation] namedLocation failed for $name: $error');
      return null;
    }
  }

  String? _currentLocationOrNull() {
    try {
      return GoRouterState.of(this).uri.toString();
    } catch (error) {
      debugPrint('[Navigation] current location lookup failed: $error');
      return null;
    }
  }
}
