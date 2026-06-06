import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ruta_viva/core/storage/local_storage_provider.dart';
import 'package:ruta_viva/features/itinerary/data/models/itinerary_model.dart';
import 'package:ruta_viva/features/itinerary/data/repositories/itinerary_repository.dart';
import 'package:ruta_viva/features/itinerary/presentation/pages/itinerary_detail_page.dart';
import 'package:ruta_viva/features/itinerary/presentation/pages/itinerary_history_page.dart';
import 'package:ruta_viva/features/itinerary/presentation/pages/itinerary_master_detail_page.dart';

void main() {
  group('ItineraryMasterDetailPage', () {
    testWidgets('mobile shows only history list', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            itineraryHistoryProvider.overrideWith((ref) async {
              return [_itinerary(title: 'Ruta A')];
            }),
          ],
          child: const MaterialApp(home: ItineraryMasterDetailPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ItineraryHistoryPage), findsOneWidget);
      expect(find.byType(ItineraryDetailPage), findsNothing);
    });

    testWidgets('landscape mobile shows master-detail side by side', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final sharedPreferences = await SharedPreferences.getInstance();

      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
            itineraryHistoryProvider.overrideWith((ref) async {
              return [_itinerary(title: 'Ruta A')];
            }),
            itineraryDetailProvider.overrideWith((ref, id) async {
              return _itinerary(title: 'Ruta A');
            }),
          ],
          child: const MaterialApp(home: ItineraryMasterDetailPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ItineraryHistoryPage), findsOneWidget);
      expect(find.byType(ItineraryDetailPage), findsOneWidget);
    });

    testWidgets('tablet portrait shows master-detail side by side', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final sharedPreferences = await SharedPreferences.getInstance();

      tester.view.physicalSize = const Size(700, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
            itineraryHistoryProvider.overrideWith((ref) async {
              return [_itinerary(title: 'Ruta A')];
            }),
            itineraryDetailProvider.overrideWith((ref, id) async {
              return _itinerary(title: 'Ruta A');
            }),
          ],
          child: const MaterialApp(home: ItineraryMasterDetailPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ItineraryHistoryPage), findsOneWidget);
      expect(find.byType(ItineraryDetailPage), findsOneWidget);
    });

    testWidgets('desktop shows master-detail side by side', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final sharedPreferences = await SharedPreferences.getInstance();

      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
            itineraryHistoryProvider.overrideWith((ref) async {
              return [_itinerary(title: 'Ruta A')];
            }),
            itineraryDetailProvider.overrideWith((ref, id) async {
              return _itinerary(title: 'Ruta A');
            }),
          ],
          child: const MaterialApp(home: ItineraryMasterDetailPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ruta A'), findsAtLeastNWidgets(1));
      expect(find.byType(ItineraryHistoryPage), findsOneWidget);
      expect(find.byType(ItineraryDetailPage), findsOneWidget);
    });
  });
}

ItineraryModel _itinerary({required String title}) {
  return ItineraryModel(
    id: 'itinerary-$title',
    touristId: 'user-1',
    title: title,
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 1, 2),
    status: 'planned',
    isEditable: true,
    steps: const [],
  );
}
