import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ruta_viva/core/storage/local_storage_provider.dart';
import 'package:ruta_viva/main.dart';

void main() {
  testWidgets('renders the login flow as the initial route', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const RutaVivaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido a Ruta Viva'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Crear una cuenta turista'), findsOneWidget);
  });
}
