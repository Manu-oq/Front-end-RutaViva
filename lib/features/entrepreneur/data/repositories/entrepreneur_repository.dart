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

final poiAnalyticsProvider = FutureProvider.family<PoiAnalyticsModel, String>((
  ref,
  poiId,
) async {
  return ref.watch(entrepreneurRepositoryProvider).getPoiAnalytics(poiId);
});

final poiActivityProvider =
    FutureProvider.family<List<PoiActivityEvent>, String>((ref, poiId) async {
      return ref.watch(entrepreneurRepositoryProvider).getPoiActivity(poiId);
    });

final poiPostsProvider =
    FutureProvider.family<List<EntrepreneurPostModel>, String>((
      ref,
      poiId,
    ) async {
      return ref.watch(entrepreneurRepositoryProvider).getPoiPosts(poiId);
    });

final poiPublicPostsProvider = FutureProvider.autoDispose
    .family<List<EntrepreneurPostModel>, String>((ref, poiId) async {
      return ref.watch(entrepreneurRepositoryProvider).getPublicPoiPosts(poiId);
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
      final response = await _client.get<dynamic>('/entrepreneur/me/posts');
      return _postListFromResponse(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<EntrepreneurPostModel> createPost({
    required String poiId,
    required String title,
    required String content,
    String? imageUrl,
    bool? isPublished,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/entrepreneur/me/posts',
        data: {
          'poi_id': poiId,
          'title': title,
          'content': content,
          // ignore: use_null_aware_elements
          if (imageUrl != null) 'image_url': imageUrl,
          // ignore: use_null_aware_elements
          if (isPublished != null) 'is_published': isPublished,
        },
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
    bool? isPublished,
    bool? isPinned,
  }) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        '/entrepreneur/me/posts/$postId',
        data: {
          'title': title,
          'content': content,
          // ignore: use_null_aware_elements
          if (isPublished != null) 'is_published': isPublished,
          // ignore: use_null_aware_elements
          if (isPinned != null) 'is_pinned': isPinned,
        },
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

  Future<PoiAnalyticsModel> getPoiAnalytics(String poiId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/entrepreneur/pois/$poiId/analytics',
      );
      return PoiAnalyticsModel.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<List<PoiActivityEvent>> getPoiActivity(String poiId) async {
    try {
      final response = await _client.get<List<dynamic>>(
        '/entrepreneur/pois/$poiId/activity',
      );
      return (response.data ?? [])
          .map(
            (item) => PoiActivityEvent.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<List<EntrepreneurPostModel>> getPoiPosts(String poiId) async {
    try {
      final response = await _client.get<dynamic>(
        '/entrepreneur/pois/$poiId/posts',
      );
      return _postListFromResponse(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<EntrepreneurPostModel> createPoiPost({
    required String poiId,
    required String title,
    required String content,
    String? imageUrl,
    bool? isPublished,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/entrepreneur/pois/$poiId/posts',
        data: {
          'title': title,
          'content': content,
          // ignore: use_null_aware_elements
          if (imageUrl != null) 'image_url': imageUrl,
          // ignore: use_null_aware_elements
          if (isPublished != null) 'is_published': isPublished,
        },
      );
      return EntrepreneurPostModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<EntrepreneurPostModel> updatePoiPost({
    required String poiId,
    required String postId,
    required String title,
    required String content,
    bool? isPublished,
  }) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        '/entrepreneur/pois/$poiId/posts/$postId',
        data: {
          'title': title,
          'content': content,
          // ignore: use_null_aware_elements
          if (isPublished != null) 'is_published': isPublished,
        },
      );
      return EntrepreneurPostModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<void> deletePoiPost({
    required String poiId,
    required String postId,
  }) async {
    try {
      await _client.delete<void>('/entrepreneur/pois/$poiId/posts/$postId');
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<EntrepreneurPostModel> pinPoiPost({
    required String poiId,
    required String postId,
    required bool pinned,
  }) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/entrepreneur/pois/$poiId/posts/$postId/pin',
        data: {'is_pinned': pinned},
      );
      return EntrepreneurPostModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<List<EntrepreneurPostModel>> getPublicPoiPosts(String poiId) async {
    try {
      final response = await _client.get<dynamic>('/pois/$poiId/posts');
      return _postListFromResponse(
        response.data,
      ).where((p) => p.isPublished).toList(growable: false);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<void> reorderPoiPosts({
    required String poiId,
    required List<Map<String, dynamic>> posts,
  }) async {
    try {
      await _client.put<dynamic>(
        '/entrepreneur/pois/$poiId/posts/reorder',
        data: {'posts': posts},
      );
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  static List<Map<String, dynamic>> buildPostReorderPayload(
    List<EntrepreneurPostModel> posts,
  ) {
    return posts
        .asMap()
        .entries
        .map((entry) {
          return {'post_id': entry.value.id, 'position': entry.key};
        })
        .toList(growable: false);
  }

  static List<EntrepreneurPostModel> sortPostsForDisplay(
    List<EntrepreneurPostModel> posts,
  ) {
    final sorted = [...posts];
    sorted.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      final aOrder = a.displayOrder;
      final bOrder = b.displayOrder;
      if (aOrder != null && bOrder != null && aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }
      if (aOrder != null && bOrder == null) return -1;
      if (aOrder == null && bOrder != null) return 1;
      final aDate = a.createdAt;
      final bDate = b.createdAt;
      if (aDate != null && bDate != null) {
        return bDate.compareTo(aDate);
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return sorted;
  }

  static List<EntrepreneurPostModel> _postListFromResponse(dynamic data) {
    final list = switch (data) {
      final List<dynamic> value => value,
      {'items': final List<dynamic> value} => value,
      {'posts': final List<dynamic> value} => value,
      {'data': final List<dynamic> value} => value,
      _ => const <dynamic>[],
    };
    final posts = list
        .whereType<Map<String, dynamic>>()
        .map(EntrepreneurPostModel.fromJson)
        .toList(growable: false);
    return sortPostsForDisplay(posts);
  }
}
