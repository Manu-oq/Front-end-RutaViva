import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/network/api_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../models/review_model.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(apiClientProvider));
});

final reviewsByPoiProvider = FutureProvider.family<List<ReviewModel>, String>((
  ref,
  poiId,
) async {
  return ref.watch(reviewRepositoryProvider).getByPoi(poiId);
});

final reviewSummaryByPoiProvider =
    FutureProvider.family<ReviewSummaryModel, String>((ref, poiId) async {
      return ref.watch(reviewRepositoryProvider).getSummaryByPoi(poiId);
    });

class ReviewRepository {
  final DioClient _client;

  const ReviewRepository(this._client);

  Future<List<ReviewModel>> getByPoi(String poiId) async {
    try {
      final response = await _client.get<List<dynamic>>('/reviews/poi/$poiId');
      return (response.data ?? [])
          .map((item) => ReviewModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ReviewModel> create({
    required String poiId,
    required int ratingStars,
    required String textContent,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/reviews/',
        data: {
          'poi_id': poiId,
          'rating_stars': ratingStars,
          'text_content': textContent,
        },
      );
      return ReviewModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ReviewSummaryModel> getSummaryByPoi(String poiId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/reviews/poi/$poiId/summary',
      );
      return ReviewSummaryModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ReviewModel> update({
    required String reviewId,
    required int ratingStars,
    required String textContent,
  }) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/reviews/$reviewId',
        data: {'rating_stars': ratingStars, 'text_content': textContent},
      );
      return ReviewModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<void> delete(String reviewId) async {
    try {
      await _client.delete<void>('/reviews/$reviewId');
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}
