import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ruta_viva/main.dart';

void main() {
  testWidgets('renders the login flow as the initial route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: RutaVivaApp()));
    await tester.pumpAndSettle();

    expect(find.text('Ruta Viva'), findsOneWidget);
    expect(find.text('Tu conserje andino inteligente.'), findsOneWidget);
    expect(find.text('Comenzar el viaje'), findsOneWidget);
  });
}
