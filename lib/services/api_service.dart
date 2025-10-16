// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/training_models.dart';

class ApiService {
  static const String baseUrl = "http://oss.nexis.id/modul/training/android/";
  static const String categoryEndpoint = 'get_categories.php';
  static const String categorywithsubcategoryEndpoint = 'get_categories_subcategories.php';

  // FUNGSI 1: Fetch Categories
  Future<List<Category>> fetchCategoriesTask() async {
    final response = await http.get(Uri.parse('$baseUrl$categoryEndpoint'));

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body is Map && body['success'] == true && body['data'] is List) {
        return (body['data'] as List)
            .map((i) => Category.fromJson(i))
            .toList();
      } else {
        throw Exception('Format JSON tidak sesuai');
      }
    } else {
      throw Exception('Gagal memuat kategori. Code: ${response.statusCode}');
    }
  }

  // FUNGSI 2: Fetch Categories + Subcategories
  Future<List<CategoryWithSubcategory>> fetchCategoriesWithSubcategories() async {
    final response = await http.get(Uri.parse('$baseUrl$categorywithsubcategoryEndpoint'));

    if (response.statusCode == 200) {
      final body = json.decode(response.body);

      if (body is Map && body['success'] == true && body['data'] is List) {
        final List<dynamic> jsonList = body['data'];
        return jsonList
            .map((json) => CategoryWithSubcategory.fromJson(json))
            .toList();
      } else if (body is List) {
        // Jika langsung list tanpa field 'data'
        return body
            .map((json) => CategoryWithSubcategory.fromJson(json))
            .toList();
      } else {
        throw Exception('Format JSON tidak sesuai');
      }
    } else {
      throw Exception('Gagal memuat kategori & subkategori. Code: ${response.statusCode}');
    }
  }

  // FUNGSI 3: Fetch Semua Course
  Future<List<Course>> fetchAllCourses() async {
    final response = await http.get(Uri.parse('${baseUrl}get_all_courses.php'));

    if (response.statusCode == 200) {
      final body = json.decode(response.body);

      if (body is List) {
        // ✅ langsung list (seperti contoh kamu)
        return body.map((json) => Course.fromJson(json)).toList();
      } else if (body is Map && body['data'] is List) {
        // fallback kalau nanti backend ditambah field "data"
        return (body['data'] as List)
            .map((json) => Course.fromJson(json))
            .toList();
      } else {
        throw Exception('Format JSON tidak sesuai');
      }
    } else {
      throw Exception('Gagal memuat semua course. Code: ${response.statusCode}');
    }
  }

  // FUNGSI 4: Fetch Course by Subcategory
  Future<List<Course>> fetchCoursesBySubcategory(int subcategoryId) async {
    final url = Uri.parse('${baseUrl}get_courses_andro.php?subcategory_id=$subcategoryId');
    print("🌐 [API CALL] GET $url"); // Log URL

    try {
      final response = await http.get(url);
      print("📥 [RESPONSE STATUS] ${response.statusCode}");
      print("📦 [RAW BODY] ${response.body}");

      if (response.statusCode == 200) {
        dynamic body;

        try {
          body = json.decode(response.body);
          print("🧩 [DECODED JSON TYPE] ${body.runtimeType}");
        } catch (e) {
          print("❌ [ERROR] Gagal decode JSON: $e");
          throw Exception("JSON Decode Error: $e");
        }

        // Jika server mengembalikan objek tunggal
        if (body is Map<String, dynamic>) {
          print("✅ [INFO] Detected single course object");
          return [Course.fromJson(body)];
        }

        // Jika server mengembalikan list
        if (body is List) {
          print("✅ [INFO] Detected list of courses (${body.length} items)");
          return body.map((json) => Course.fromJson(json)).toList();
        }

        print("⚠️ [WARNING] Format JSON tidak dikenali: ${body.runtimeType}");
        throw Exception('Format JSON tidak sesuai');
      } else {
        print("❌ [ERROR] HTTP Code: ${response.statusCode}");
        throw Exception('Gagal memuat course subkategori. Code: ${response.statusCode}');
      }
    } catch (e) {
      print("🔥 [EXCEPTION] fetchCoursesBySubcategory($subcategoryId): $e");
      rethrow;
    }
  }




  // FUNGSI 5: Search
  Future<List<SearchItem>> searchCourses(String keyword) async {
    final encoded = Uri.encodeComponent(keyword);
    final url = Uri.parse('${baseUrl}search.php?query=$encoded');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is Map && data['status'] == true && data['data'] is List) {
        return (data['data'] as List)
            .map((i) => SearchItem.fromJson(i))
            .toList();
      }
      return [];
    } else {
      throw Exception('Gagal mencari data. Code: ${response.statusCode}');
    }
  }
}
