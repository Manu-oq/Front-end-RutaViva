class CategoryModel {
  final int id;
  final String name;
  final String? iconUrl;
  final int? parentId;

  const CategoryModel({
    required this.id,
    required this.name,
    this.iconUrl,
    this.parentId,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      iconUrl: json['icon_url'] as String?,
      parentId: (json['parent_id'] as num?)?.toInt(),
    );
  }

  bool get isParent => parentId == null;

  bool get isInfrastructure => id == 13 || id == 14;
}

extension CategoryHierarchyX on Iterable<CategoryModel> {
  List<CategoryModel> topLevelAttractionCategories() {
    return where(
      (category) => category.isParent && !category.isInfrastructure,
    ).toList(growable: false);
  }

  List<CategoryModel> childrenOf(int parentId) {
    return where(
      (category) => category.parentId == parentId,
    ).toList(growable: false);
  }
}
