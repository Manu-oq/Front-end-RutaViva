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

class PoiRepository {
  final DioClient _client;

  const PoiRepository(this._client);

  Future<PoiModel> createPoi({
    required String nombre,
    required String descripcion,
    required String tipoAcceso,
    required double latitude,
    required double longitude,
    String? telefonoPublico,
    String? emailPublico,
    String? imageUrl,
    List<int> categoryIds = const [],
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/pois/',
        data: {
          'nombre': nombre,
          'descripcion': descripcion,
          'tipo_acceso': tipoAcceso,
          'telefono_publico': telefonoPublico?.isEmpty == true
              ? null
              : telefonoPublico,
          'email_publico': emailPublico?.isEmpty == true ? null : emailPublico,
          'multimedia_urls': imageUrl == null || imageUrl.isEmpty
              ? null
              : {'cover': imageUrl},
          'category_ids': categoryIds,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      return PoiModel.fromJson(response.data!);
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
      return PoiModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<List<PoiModel>> getMyPois() async {
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
    required String nombre,
    required String descripcion,
    required String tipoAcceso,
    required double latitude,
    required double longitude,
    String? telefonoPublico,
    String? emailPublico,
    List<int> categoryIds = const [],
  }) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/pois/$poiId',
        data: {
          'nombre': nombre,
          'descripcion': descripcion,
          'tipo_acceso': tipoAcceso,
          'telefono_publico': telefonoPublico?.isEmpty == true
              ? null
              : telefonoPublico,
          'email_publico': emailPublico?.isEmpty == true ? null : emailPublico,
          'category_ids': categoryIds,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      return PoiModel.fromJson(response.data!);
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

  Future<List<PoiModel>> searchNearby({
    required double lat,
    required double lon,
    double radius = 30000,
  }) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '/pois/search',
        queryParameters: {'lat': lat, 'lon': lon, 'radius': radius},
      );
      return (response.data ?? [])
          .map((item) => PoiModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
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
      return PoiModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}
