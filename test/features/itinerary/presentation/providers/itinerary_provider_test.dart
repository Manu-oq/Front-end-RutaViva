import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ruta_viva/core/storage/local_storage_provider.dart';
import 'package:ruta_viva/features/itinerary/presentation/providers/itinerary_provider.dart';

void main() {
  group('ItineraryState', () {
    test('default state has no current itinerary', () {
      const state = ItineraryState();

      expect(state.current, isNull);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('copyWith updates isLoading', () {
      const state = ItineraryState();
      final updated = state.copyWith(isLoading: true);

      expect(updated.isLoading, isTrue);
      expect(updated.current, isNull);
    });

    test('copyWith clearError removes errorMessage', () {
      const state = ItineraryState(errorMessage: 'err');
      final updated = state.copyWith(clearError: true);

      expect(updated.errorMessage, isNull);
    });
  });

  group('itineraryProvider', () {
    test('initial state is empty when no stored itinerary', () async {
      SharedPreferences.setMockInitialValues({});
      final sharedPreferences = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(itineraryProvider);
      expect(state.current, isNull);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('initial state loads from stored itinerary', () async {
      final storedJson = jsonEncode({
        'id': 'stored-1',
        'tourist_id': 'u1',
        'title': 'Stored Tour',
        'status': 'draft',
        'steps': <dynamic>[],
      });
      SharedPreferences.setMockInitialValues({
        'ruta_viva.last_itinerary': storedJson,
      });
      final sharedPreferences = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(itineraryProvider);
      expect(state.current, isNotNull);
      expect(state.current!.id, equals('stored-1'));
      expect(state.current!.title, equals('Stored Tour'));
      expect(state.current!.status, equals('draft'));
      expect(state.current!.steps, isEmpty);
    });

    test('initial state handles corrupt JSON gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'ruta_viva.last_itinerary': 'not-valid-json{{{',
      });
      final sharedPreferences = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(itineraryProvider);
      expect(state.current, isNull);
    });
  });
}
