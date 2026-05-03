import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/network/api_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../models/category_model.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(apiClientProvider));
});

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  return ref.watch(categoryRepositoryProvider).getCategories();
});

final categoryNameMapProvider = Provider<Map<int, String>>((ref) {
  final categories = ref
      .watch(categoriesProvider)
      .maybeWhen(data: (items) => items, orElse: () => const <CategoryModel>[]);
  return {for (final category in categories) category.id: category.name};
});

class CategoryRepository {
  final DioClient _client;

  const CategoryRepository(this._client);

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _client.get<List<dynamic>>('/categories/');
      return (response.data ?? [])
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}
