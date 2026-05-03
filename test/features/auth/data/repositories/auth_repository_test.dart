import 'package:flutter_test/flutter_test.dart';

import 'package:ruta_viva/features/auth/data/models/token_model.dart';
import 'package:ruta_viva/features/auth/data/models/user_model.dart';

const _tokenJson = <String, dynamic>{
  'access_token': 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.fake',
  'token_type': 'bearer',
};

const _userJson = <String, dynamic>{
  'id': 'user-123',
  'email': 'turista@test.com',
  'is_active': true,
  'created_at': '2025-01-15T10:30:00Z',
  'tourist_profile': <String, dynamic>{
    'user_id': 'user-123',
    'full_name': 'María Pérez',
    'has_own_transport': true,
    'system_preferences': <String, dynamic>{
      'interests': <String>['naturaleza', 'gastronomia'],
    },
  },
  'entrepreneur_profile': null,
};

void main() {
  group('TokenModel.fromJson', () {
    test('parses access_token and token_type', () {
      final token = TokenModel.fromJson(_tokenJson);

      expect(token.accessToken, equals('eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.fake'));
      expect(token.tokenType, equals('bearer'));
    });

    test('defaults token_type to bearer when absent', () {
      final token = TokenModel.fromJson(<String, dynamic>{
        'access_token': 'abc',
      });

      expect(token.tokenType, equals('bearer'));
    });
  });

  group('UserModel.fromJson', () {
    test('parses user with tourist profile completely', () {
      final user = UserModel.fromJson(_userJson);

      expect(user.id, equals('user-123'));
      expect(user.email, equals('turista@test.com'));
      expect(user.isActive, isTrue);
      expect(user.createdAt, equals(DateTime.utc(2025, 1, 15, 10, 30, 0)));

      expect(user.touristProfile, isNotNull);
      expect(user.touristProfile!.userId, equals('user-123'));
      expect(user.touristProfile!.fullName, equals('María Pérez'));
      expect(user.touristProfile!.hasOwnTransport, isTrue);
      expect(
        user.touristProfile!.interests,
        equals(['naturaleza', 'gastronomia']),
      );

      expect(user.entrepreneurProfile, isNull);
      expect(user.isEntrepreneur, isFalse);
    });

    test('displayName returns fullName when tourist profile exists', () {
      final user = UserModel.fromJson(_userJson);
      expect(user.displayName, equals('María Pérez'));
    });

    test('displayName falls back to email prefix without tourist profile', () {
      final json = Map<String, dynamic>.from(_userJson)
        ..remove('tourist_profile');
      final user = UserModel.fromJson(json);

      expect(user.displayName, equals('turista'));
    });

    test('parses entrepreneur profile when present', () {
      final json = Map<String, dynamic>.from(_userJson)
        ..remove('tourist_profile')
        ..['entrepreneur_profile'] = <String, dynamic>{
          'user_id': 'user-123',
          'admin_data': <String, dynamic>{'activated_from': 'frontend'},
        };
      final user = UserModel.fromJson(json);

      expect(user.isEntrepreneur, isTrue);
      expect(user.entrepreneurProfile, isNotNull);
      expect(user.entrepreneurProfile!.userId, equals('user-123'));
      expect(user.entrepreneurProfile!.adminData, isNotNull);
      expect(
        user.entrepreneurProfile!.adminData!['activated_from'],
        equals('frontend'),
      );
    });

    test('defaults is_active to true when absent', () {
      final json = Map<String, dynamic>.from(_userJson)
        ..remove('is_active');
      final user = UserModel.fromJson(json);

      expect(user.isActive, isTrue);
    });

    test('handles user without any profile', () {
      final json = Map<String, dynamic>.from(_userJson)
        ..remove('tourist_profile')
        ..['entrepreneur_profile'] = null;
      final user = UserModel.fromJson(json);

      expect(user.touristProfile, isNull);
      expect(user.entrepreneurProfile, isNull);
      expect(user.isEntrepreneur, isFalse);
    });

    test('interests defaults to empty list when system_preferences is null', () {
      final json = Map<String, dynamic>.from(_userJson);
      json['tourist_profile'] = <String, dynamic>{
        'user_id': 'user-123',
        'full_name': 'Test User',
        'has_own_transport': false,
        'system_preferences': null,
      };
      final user = UserModel.fromJson(json);

      expect(user.touristProfile!.interests, isEmpty);
    });

    test('interests defaults to empty list when interests field is missing', () {
      final json = Map<String, dynamic>.from(_userJson);
      json['tourist_profile'] = <String, dynamic>{
        'user_id': 'user-123',
        'full_name': 'Test User',
        'has_own_transport': false,
        'system_preferences': <String, dynamic>{},
      };
      final user = UserModel.fromJson(json);

      expect(user.touristProfile!.interests, isEmpty);
    });
  });
}
