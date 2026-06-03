import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:ruta_viva/features/map/domain/entities/map_point.dart';
import 'package:ruta_viva/features/map/presentation/widgets/custom_map_marker.dart';

void main() {
  testWidgets('CustomMapMarker highlighted marker fits allocated map size', (
    tester,
  ) async {
    final point = MapPoint(
      id: 'poi-1',
      name: 'Río Quiliche con un nombre largo',
      coordinates: const LatLng(-39.35, -71.70),
      categoryIds: const [1],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 104,
                height: 98,
                child: CustomMapMarker(point: point, highlighted: true),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Río Quiliche con un nombre largo'), findsOneWidget);
  });

  testWidgets('CustomMapMarker compact marker fits allocated map size', (
    tester,
  ) async {
    final point = MapPoint(
      id: 'poi-2',
      name: 'Mirador',
      coordinates: const LatLng(-39.35, -71.70),
      categoryIds: const [3],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 46,
                height: 46,
                child: CustomMapMarker(
                  point: point,
                  compact: true,
                  showLabel: false,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Mirador'), findsNothing);
  });
}
