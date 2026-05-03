import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';

/// Exposes the backend categories indexed by their numeric id.
///
/// Built on top of [categoriesProvider]: re-emits whenever the underlying
/// `FutureProvider<List<CategoryModel>>` changes, transforming the list
/// into a `Map<int, CategoryModel>` keyed by [CategoryModel.id].
///
/// The provider returns the [AsyncValue] directly so consumers can decide
/// how to handle loading/error states (e.g. show a placeholder, fall back
/// to a literal label, or surface an error).
///
/// If the upstream list contains duplicate ids, later occurrences win
/// (last-wins semantics of `Map.fromEntries`).
final categoriesByIdProvider =
    Provider<AsyncValue<Map<int, CategoryModel>>>((ref) {
  final asyncCategories = ref.watch(categoriesProvider);
  return asyncCategories.whenData(
    (items) => {for (final category in items) category.id: category},
  );
});
