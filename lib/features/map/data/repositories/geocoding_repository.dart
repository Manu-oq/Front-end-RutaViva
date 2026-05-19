import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/network/api_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../models/geocoding_result_model.dart';

final geocodingRepositoryProvider = Provider<GeocodingRepository>((ref) {
  return GeocodingRepository(ref.watch(apiClientProvider));
});

class GeocodingRepository {
  final DioClient _client;

  const GeocodingRepository(this._client);

  Future<List<GeocodingResultModel>> search({
    required String query,
    required double lat,
    required double lon,
    int limit = 6,
  }) async {
    if (query.trim().isEmpty) return const [];
    try {
      final response = await _client.get<List<dynamic>>(
        '/geocoding/search',
        queryParameters: {
          'q': query.trim(),
          'lat': lat,
          'lon': lon,
          'limit': limit,
        },
      );
      return (response.data ?? [])
          .map(
            (item) =>
                GeocodingResultModel.fromJson(item as Map<String, dynamic>),
          )
          .where(
            (item) =>
                item.coordinates.latitude != 0 ||
                item.coordinates.longitude != 0,
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}
