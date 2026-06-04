import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/network/api_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/map_point.dart';
import '../models/poi_model.dart';

final poiRepositoryProvider = Provider<PoiRepository>((ref) {
  return PoiRepository(ref.watch(apiClientProvider));
});

final poiDetailProvider = FutureProvider.family<MapPoint, String>((
  ref,
  poiId,
) async {
  final poi = await ref.watch(poiRepositoryProvider).getPoiById(poiId);
  return poi.toMapPoint();
});

final poiModelDetailProvider = FutureProvider.family<PoiModel, String>((
  ref,
  poiId,
) async {
  return ref.watch(poiRepositoryProvider).getPoiById(poiId);
});

final myPoisProvider = FutureProvider<List<PoiModel>>((ref) async {
  return ref.watch(poiRepositoryProvider).getMyPois();
});

final entrepreneurPoisProvider = FutureProvider<List<PoiModel>>((ref) async {
  return ref.watch(poiRepositoryProvider).getEntrepreneurPois();
});

final itineraryPoisProvider = FutureProvider.family<List<MapPoint>, String>((
  ref,
  itineraryId,
) async {
  final pois = await ref
      .watch(poiRepositoryProvider)
      .getPoisForItinerary(itineraryId);
  return pois.map((poi) => poi.toMapPoint()).toList(growable: false);
});

class PoiRepository {
  final DioClient _client;

  const PoiRepository(this._client);

  Future<List<PoiModel>> getPoisForItinerary(String itineraryId) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '/itineraries/$itineraryId/pois',
      );
      return (response.data ?? [])
          .map((item) => PoiModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<PoiModel> createPoi({
    required String creationType,
    required String name,
    required String description,
    required String accessType,
    required String imageUrl,
    required double latitude,
    required double longitude,
    String? contactPhone,
    String? contactEmail,
    List<int> categoryIds = const [],
  }) async {
    try {
      final endpoint = _createPoiEndpoint(creationType);
      final response = await _client.post<Map<String, dynamic>>(
        endpoint,
        data: _createPoiRequestBody(
          name: name,
          description: description,
          accessType: accessType,
          imageUrl: imageUrl,
          latitude: latitude,
          longitude: longitude,
          contactPhone: contactPhone,
          contactEmail: contactEmail,
          categoryIds: categoryIds,
        ),
      );
      return _poiFromResponse(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<PoiModel> appendImage({
    required String poiId,
    required String imageUrl,
  }) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        '/pois/$poiId/media',
        data: {'image_url': imageUrl},
      );
      return _poiFromResponse(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<List<PoiModel>> getMyPois() async {
    try {
      final response = await _client.get<List<dynamic>>(
        '/pois/my-contributions/',
      );
      return (response.data ?? [])
          .map((item) => PoiModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<List<PoiModel>> getEntrepreneurPois() async {
    try {
      final response = await _client.get<List<dynamic>>('/pois/mine');
      return (response.data ?? [])
          .map((item) => PoiModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<PoiModel> updatePoi({
    required String poiId,
    required String name,
    required String description,
    required String accessType,
    required double latitude,
    required double longitude,
    String? contactPhone,
    String? contactEmail,
    List<int> categoryIds = const [],
  }) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/pois/$poiId',
        data: _updatePoiRequestBody(
          name: name,
          description: description,
          accessType: accessType,
          latitude: latitude,
          longitude: longitude,
          contactPhone: contactPhone,
          contactEmail: contactEmail,
          categoryIds: categoryIds,
        ),
      );
      return _poiFromResponse(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<void> deletePoi(String poiId) async {
    try {
      await _client.delete<void>('/pois/$poiId');
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<void> recordVisit(String poiId, {String source = 'frontend'}) async {
    try {
      await _client.post<void>('/pois/$poiId/visit', data: {'source': source});
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<List<PoiModel>> searchNearby({
    required double lat,
    required double lon,
    double radius = 30000,
    List<int> categoryIds = const [],
  }) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '/pois/search',
        queryParameters: _searchNearbyQueryParameters(
          lat: lat,
          lon: lon,
          radius: radius,
          categoryIds: categoryIds,
        ),
      );
      return (response.data ?? [])
          .map((item) => PoiModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  static Map<String, dynamic> searchNearbyQueryParametersForTesting({
    required double lat,
    required double lon,
    required double radius,
    List<int> categoryIds = const [],
  }) {
    return _searchNearbyQueryParameters(
      lat: lat,
      lon: lon,
      radius: radius,
      categoryIds: categoryIds,
    );
  }

  static Map<String, dynamic> _searchNearbyQueryParameters({
    required double lat,
    required double lon,
    required double radius,
    required List<int> categoryIds,
  }) {
    return {
      'lat': lat,
      'lon': lon,
      'radius': radius,
      if (categoryIds.isNotEmpty) 'category_ids': categoryIds.join(','),
    };
  }

  Future<List<PoiModel>> semanticSearch({
    required String query,
    required double lat,
    required double lon,
    double radius = 30000,
  }) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '/pois/semantic-search',
        queryParameters: {
          'query': query,
          'lat': lat,
          'lon': lon,
          'radius': radius,
        },
      );
      return (response.data ?? [])
          .map((item) => PoiModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<PoiModel> getPoiById(String poiId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/pois/$poiId');
      return _poiFromResponse(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  static Map<String, dynamic> createPoiRequestBodyForTesting({
    required String name,
    required String description,
    required String accessType,
    required String imageUrl,
    required double latitude,
    required double longitude,
    String? contactPhone,
    String? contactEmail,
    List<int> categoryIds = const [],
  }) {
    return _createPoiRequestBody(
      name: name,
      description: description,
      accessType: accessType,
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
      contactPhone: contactPhone,
      contactEmail: contactEmail,
      categoryIds: categoryIds,
    );
  }

  static Map<String, dynamic> updatePoiRequestBodyForTesting({
    required String name,
    required String description,
    required String accessType,
    required double latitude,
    required double longitude,
    String? contactPhone,
    String? contactEmail,
    List<int> categoryIds = const [],
  }) {
    return _updatePoiRequestBody(
      name: name,
      description: description,
      accessType: accessType,
      latitude: latitude,
      longitude: longitude,
      contactPhone: contactPhone,
      contactEmail: contactEmail,
      categoryIds: categoryIds,
    );
  }

  static String createPoiEndpointForTesting(String creationType) {
    return _createPoiEndpoint(creationType);
  }

  static String _createPoiEndpoint(String creationType) {
    return switch (creationType) {
      'entrepreneur' => '/pois/entrepreneur/',
      _ => '/pois/tourist/',
    };
  }

  static Map<String, dynamic> _createPoiRequestBody({
    required String name,
    required String description,
    required String accessType,
    required String imageUrl,
    required double latitude,
    required double longitude,
    required String? contactPhone,
    required String? contactEmail,
    required List<int> categoryIds,
  }) {
    return {
      'name': name,
      'description': description,
      'access_type': accessType,
      'contact_phone': contactPhone?.isEmpty == true ? null : contactPhone,
      'contact_email': contactEmail?.isEmpty == true ? null : contactEmail,
      'image_url': imageUrl,
      'category_ids': categoryIds,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static Map<String, dynamic> _updatePoiRequestBody({
    required String name,
    required String description,
    required String accessType,
    required double latitude,
    required double longitude,
    required String? contactPhone,
    required String? contactEmail,
    required List<int> categoryIds,
  }) {
    return {
      'name': name,
      'description': description,
      'access_type': accessType,
      'contact_phone': contactPhone?.isEmpty == true ? null : contactPhone,
      'contact_email': contactEmail?.isEmpty == true ? null : contactEmail,
      'category_ids': categoryIds,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static PoiModel _poiFromResponse(Map<String, dynamic> data) {
    final payload = data['poi'] ?? data['data'];
    if (payload is Map<String, dynamic>) {
      return PoiModel.fromJson(payload);
    }
    return PoiModel.fromJson(data);
  }
}
