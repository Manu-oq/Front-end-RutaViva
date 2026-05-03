import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/network/api_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../map/data/models/poi_model.dart';
import '../../../map/domain/entities/map_point.dart';

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepository(ref.watch(apiClientProvider));
});

final bookmarkedPoisProvider = FutureProvider<List<MapPoint>>((ref) async {
  final pois = await ref.watch(bookmarkRepositoryProvider).getBookmarkedPois();
  return pois.map((poi) => poi.toMapPoint()).toList();
});

final bookmarkStatusProvider = FutureProvider.family<bool, String>((
  ref,
  poiId,
) async {
  return ref.watch(bookmarkRepositoryProvider).isBookmarked(poiId);
});

class BookmarkRepository {
  final DioClient _client;

  const BookmarkRepository(this._client);

  Future<List<PoiModel>> getBookmarkedPois() async {
    try {
      final response = await _client.get<List<dynamic>>('/bookmarks/');
      return (response.data ?? [])
          .map((item) => PoiModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<bool> isBookmarked(String poiId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/bookmarks/$poiId',
      );
      return response.data?['is_bookmarked'] as bool? ?? false;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<void> add(String poiId) async {
    try {
      await _client.post<Map<String, dynamic>>('/bookmarks/$poiId');
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<void> remove(String poiId) async {
    try {
      await _client.delete<void>('/bookmarks/$poiId');
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}
