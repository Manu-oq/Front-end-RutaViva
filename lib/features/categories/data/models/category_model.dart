class CategoryModel {
  final int id;
  final String name;
  final String? iconUrl;

  const CategoryModel({required this.id, required this.name, this.iconUrl});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      iconUrl: json['icon_url'] as String?,
    );
  }
}
