import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_viva/core/widgets/authenticated_network_image.dart';

void main() {
  group('AuthenticatedNetworkImage.requiresBearerToken', () {
    test('returns true for backend media paths', () {
      expect(
        AuthenticatedNetworkImage.requiresBearerToken('/media/photo.png'),
        isTrue,
      );
    });

    test('returns false for external images', () {
      expect(
        AuthenticatedNetworkImage.requiresBearerToken(
          'https://example.com/media/photo.png',
        ),
        isFalse,
      );
    });

    test('returns false for non-media backend paths', () {
      expect(
        AuthenticatedNetworkImage.requiresBearerToken('/api/v1/pois/1'),
        isFalse,
      );
    });
  });
}
