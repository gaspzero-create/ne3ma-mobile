class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final bool isActive;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      isActive: map['isActive'] ?? true,
    );
  }
}
