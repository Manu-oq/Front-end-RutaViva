import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_viva/core/constants/api_constants.dart';

void main() {
  group('ApiConstants.resolveBackendUrl', () {
    test('returns null for hostless text values', () {
      expect(ApiConstants.resolveBackendUrl('OpenStreetMap'), isNull);
      expect(ApiConstants.resolveBackendUrl(' example.png '), isNull);
    });

    test('keeps valid absolute URLs', () {
      expect(
        ApiConstants.resolveBackendUrl('https://example.com/photo.png'),
        equals('https://example.com/photo.png'),
      );
    });

    test('resolves backend paths against backend origin', () {
      expect(
        ApiConstants.resolveBackendUrl('/media/photo.png'),
        endsWith('/media/photo.png'),
      );
      expect(
        ApiConstants.resolveBackendUrl('/media/photo.png'),
        startsWith('http'),
      );
    });
  });
}
