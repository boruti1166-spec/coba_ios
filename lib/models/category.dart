class Category {
  final String name;
  final int subcategoryCount;
  final String iconUrl;

  Category({required this.name, required this.subcategoryCount, required this.iconUrl});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['category_name'],
      subcategoryCount: json['subcategory_count'],
      iconUrl: json['icon_url'] ?? "", // kalau ada url gambar
    );
  }
}
