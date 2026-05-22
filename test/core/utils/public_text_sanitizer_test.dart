import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_viva/core/utils/public_text_sanitizer.dart';

void main() {
  test('removes internal POI instruction text', () {
    expect(
      PublicTextSanitizer.cleanOptional(
        'alojamiento, usar solo para check-in, check-out o descanso cuando el usuario lo pida explícitamente',
      ),
      isNull,
    );
  });

  test('keeps normal public descriptions', () {
    expect(
      PublicTextSanitizer.cleanOptional('Mirador con vista al volcán.'),
      equals('Mirador con vista al volcán.'),
    );
  });
}
