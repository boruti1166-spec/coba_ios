class Subcategory {
  final int id;
  final String name;

  Subcategory({required this.id, required this.name});

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'],
      name: json['name'],
    );
  }
}
