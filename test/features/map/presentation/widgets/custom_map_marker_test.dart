import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:ruta_viva/features/map/domain/entities/map_point.dart';
import 'package:ruta_viva/features/map/presentation/widgets/custom_map_marker.dart';

void main() {
  group('CustomMapMarker', () {
    testWidgets(
      'renders the unified fallback icon and color when categoryId is unknown',
      (tester) async {
        final point = MapPoint(
          id: 'poi-unknown',
          name: 'POI con categoría rara',
          coordinates: const LatLng(-39.27, -71.97),
          // 99 is not part of the mapping in categoryStyleFor, so the helper
          // must yield the fallback (Icons.location_on, Colors.grey).
          categoryIds: const [99],
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(body: CustomMapMarker(point: point)),
            ),
          ),
        );

        // The marker icon: there is exactly one Icon inside the marker badge
        // and it must be the fallback Icons.location_on.
        final iconFinder = find.byIcon(Icons.location_on);
        expect(iconFinder, findsOneWidget);

        // The colored circle around the icon: locate the Container that holds
        // the Icon and assert its BoxDecoration color is the fallback grey.
        final containerFinder = find.ancestor(
          of: iconFinder,
          matching: find.byType(Container),
        );
        expect(containerFinder, findsWidgets);
        final container = tester.widget<Container>(containerFinder.first);
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(Colors.grey));
        expect(decoration.shape, equals(BoxShape.circle));
      },
    );
  });
}
