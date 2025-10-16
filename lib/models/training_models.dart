// models/training_models.dart

// Fungsi Helper untuk parsing nilai (menangani String ke Int)
import 'dart:convert';

int _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

class Subcategory {
  final int id;
  final String name;

  Subcategory({required this.id, required this.name});

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: _parseInt(json['id']),
      name: json['name'] as String? ?? 'N/A',
    );
  }
}

class CategoryWithSubcategory {
  final int id;
  final String name;
  final List<Subcategory> subcategories;

  CategoryWithSubcategory({required this.id, required this.name, required this.subcategories});

  factory CategoryWithSubcategory.fromJson(Map<String, dynamic> json) {
    final categoryId = _parseInt(json['id'] ?? json['category_id']);

    // Deteksi apakah subcategories berupa List langsung atau JSON String
    dynamic subData = json['subcategories'];
    List<Subcategory> subs = [];

    if (subData != null) {
      if (subData is String) {
        // Jika bentuknya string JSON (misal "[{...},{...}]")
        try {
          final decoded = jsonDecode(subData);
          if (decoded is List) {
            subs = decoded
                .map((i) => Subcategory.fromJson(i as Map<String, dynamic>))
                .toList();
          }
        } catch (e) {
          print("⚠️ Gagal decode subcategories string: $e");
        }
      } else if (subData is List) {
        subs = subData
            .map((i) => Subcategory.fromJson(i as Map<String, dynamic>))
            .toList();
      }
    }

    return CategoryWithSubcategory(
      id: categoryId,
      name: json['category_name'] as String? ??
          json['name'] as String? ??
          'N/A',
      subcategories: subs,
    );
  }

}

class Category {
  final String name;
  final int subcategoryCount;

  Category({required this.name, required this.subcategoryCount});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['category_name'] as String? ?? 'N/A',
      subcategoryCount: _parseInt(json['subcategory_count']),
    );
  }
}


class Course {
  final int id;
  final String title;
  final String imageUrl; // image_url
  final String descriptionImage; // description_image
  final String descriptionImage2; // description_image2

  Course({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.descriptionImage,
    required this.descriptionImage2,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: _parseInt(json['id']),
      title: json['title'] as String? ?? 'No Title',
      imageUrl: json['image_url'] as String? ?? '',
      descriptionImage: json['description_image'] as String? ?? '',
      descriptionImage2: json['description_image2'] as String? ?? '',
    );
  }
}

class SearchItem {
  final int id;
  final String title;

  SearchItem({required this.id, required this.title});

  factory SearchItem.fromJson(Map<String, dynamic> json) {
    return SearchItem(
      id: _parseInt(json['id']),
      title: json['title'] as String? ?? 'No Title',
    );
  }
}