import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/network/api_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../models/entrepreneur_models.dart';

final entrepreneurRepositoryProvider = Provider<EntrepreneurRepository>((ref) {
  return EntrepreneurRepository(ref.watch(apiClientProvider));
});

final entrepreneurMetricsProvider = FutureProvider<EntrepreneurMetricsModel>((
  ref,
) async {
  return ref.watch(entrepreneurRepositoryProvider).getMyMetrics();
});

final entrepreneurIncomeProvider = FutureProvider<EntrepreneurIncomeModel>((
  ref,
) async {
  return ref.watch(entrepreneurRepositoryProvider).getMyIncome();
});

final entrepreneurPostsProvider = FutureProvider<List<EntrepreneurPostModel>>((
  ref,
) async {
  return ref.watch(entrepreneurRepositoryProvider).getMyPosts();
});

class EntrepreneurRepository {
  final DioClient _client;

  const EntrepreneurRepository(this._client);

  Future<EntrepreneurMetricsModel> getMyMetrics() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/entrepreneur/me/metrics',
      );
      return EntrepreneurMetricsModel.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<EntrepreneurIncomeModel> getMyIncome() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/entrepreneur/me/income',
      );
      return EntrepreneurIncomeModel.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<List<EntrepreneurPostModel>> getMyPosts() async {
    try {
      final response = await _client.get<List<dynamic>>(
        '/entrepreneur/me/posts',
      );
      return (response.data ?? [])
          .map(
            (item) =>
                EntrepreneurPostModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<EntrepreneurPostModel> createPost({
    required String title,
    required String content,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/entrepreneur/me/posts',
        data: {'title': title, 'content': content},
      );
      return EntrepreneurPostModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<EntrepreneurPostModel> updatePost({
    required String postId,
    required String title,
    required String content,
  }) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        '/entrepreneur/me/posts/$postId',
        data: {'title': title, 'content': content},
      );
      return EntrepreneurPostModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _client.delete<void>('/entrepreneur/me/posts/$postId');
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}
