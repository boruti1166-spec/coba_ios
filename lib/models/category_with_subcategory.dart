import 'subcategory.dart';

class CategoryWithSubcategory {
  final int id;
  final String name;
  final List<Subcategory> subcategories;

  CategoryWithSubcategory({
    required this.id,
    required this.name,
    required this.subcategories,
  });

  factory CategoryWithSubcategory.fromJson(Map<String, dynamic> json) {
    return CategoryWithSubcategory(
      id: json['id'],
      name: json['name'],
      subcategories: (json['subcategories'] as List)
          .map((s) => Subcategory.fromJson(s))
          .toList(),
    );
  }
}
