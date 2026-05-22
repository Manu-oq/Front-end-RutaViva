import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ruta_viva/features/onboarding/presentation/providers/interests_provider.dart';

void main() {
  group('InterestsNotifier', () {
    test('estado inicial es lista vacia', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(interestsProvider);

      expect(state, isEmpty);
    });

    test('toggleInterest agrega interes nuevo', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(interestsProvider.notifier).toggleInterest('gastronomia');

      final state = container.read(interestsProvider);
      expect(state, equals(['gastronomia']));
    });

    test('toggleInterest remueve interes existente', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(interestsProvider.notifier);
      notifier.toggleInterest('gastronomia');
      notifier.toggleInterest('naturaleza');

      expect(
        container.read(interestsProvider),
        equals(['gastronomia', 'naturaleza']),
      );

      notifier.toggleInterest('gastronomia');

      expect(container.read(interestsProvider), equals(['naturaleza']));
    });

    test('toggleInterest maneja correctamente multiples intereses', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(interestsProvider.notifier);
      notifier.toggleInterest('gastronomia');
      notifier.toggleInterest('naturaleza');
      notifier.toggleInterest('cultura');

      expect(
        container.read(interestsProvider),
        equals(['gastronomia', 'naturaleza', 'cultura']),
      );

      notifier.toggleInterest('naturaleza');

      expect(
        container.read(interestsProvider),
        equals(['gastronomia', 'cultura']),
      );
    });

    test('toggleInterest con string vacio lo agrega', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(interestsProvider.notifier).toggleInterest('');

      expect(container.read(interestsProvider), equals(['']));
    });
  });
}
