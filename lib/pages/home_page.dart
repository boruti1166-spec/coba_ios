import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../PdfPreviewPage.dart';
import '../models/training_models.dart'; // Ganti dengan path yang benar
import '../pdf_utils.dart';
import '../services/api_service.dart';
import '../widgets/detail_page.dart'; // Ganti dengan path yang benar

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final List<SearchItem> _searchResults = [];

  // Data State
  String _userName = "Guest";
  String _profileImageUrl = "https://picsum.photos/200"; // Default atau placeholder
  int _selectedCategoryId = 0; // Kategori yang dipilih
  int _selectedSubcategoryId = 0; // Subkategori yang dipilih
  bool _expanded = false; // untuk kontrol tampilan

  // Data API
  List<Category> _categoryListRecyclerA = []; // Untuk Recycler 1 (FetchCategoriesTask)
  List<CategoryWithSubcategory> _categoriesWithSubs = []; // Untuk Recycler Kategori & Subkategori
  List<Subcategory> _currentSubcategories = []; // Subkategori yang ditampilkan
  List<Course> _courseData = []; // Untuk Recycler Rekomendasi

  // State Pemuatan
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Mirip dengan fungsi _loadUserData() & SharedPreferences di Android
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    // Ganti 'fullname' dan 'photo' dengan key SharedPreferences Anda yang sebenarnya
    setState(() {
      _userName = prefs.getString('fullname') ?? 'Adnan';
      String? photo = prefs.getString('photo');
      if (photo != null && photo.isNotEmpty) {
        _profileImageUrl = photo;
      }
    });
  }

  // Mirip dengan fetchCategories(), fetchAllCourses(), dan FetchCategoriesTask
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // 1️⃣ Fetch Categories
      _categoryListRecyclerA = await _apiService.fetchCategoriesTask();
      print("✅ Categories: ${_categoryListRecyclerA.length}");

      // 2️⃣ Fetch Categories with Subcategories
      try {
        _categoriesWithSubs = await _apiService.fetchCategoriesWithSubcategories();
        print("✅ CategoriesWithSubs: ${_categoriesWithSubs.length}");
      } catch (e) {
        print("❌ Error di fetchCategoriesWithSubcategories: $e");
      }

      // 3️⃣ Fetch All Courses
      try {
        _courseData = await _apiService.fetchAllCourses();
        print("✅ Courses: ${_courseData.length}");
      } catch (e) {
        print("❌ Error di fetchAllCourses: $e");
      }

    } catch (e) {
      print("❌ Error saat fetch data utama: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  // Fungsi yang dipicu saat kategori diklik (mirip CategoryWithSubcategoryAdapter callback)
  void _onCategorySelected(CategoryWithSubcategory category) {
    setState(() {
      _selectedCategoryId = category.id;
      _currentSubcategories = category.subcategories;
      // Reset subkategori yang dipilih
      _selectedSubcategoryId = 0;
      // Saat kategori dipilih, tampilkan semua kursus yang terkait dengan kategori tersebut jika perlu,
      // atau biarkan Recycler Course menampilkan semua atau data yang sudah ada
      // Untuk tujuan ini, kita tidak melakukan fetch kursus di sini, tetapi di Subcategory.
    });
  }

  // Fungsi yang dipicu saat subkategori diklik (mirip SubcategoryAdapter callback)
  void _onSubcategorySelected(Subcategory subcategory) async {
    setState(() {
      _selectedSubcategoryId = subcategory.id;
    });

    try {
      // Mirip fetchCoursesBySubcategory(subcategoryId)
      _courseData = await _apiService.fetchCoursesBySubcategory(subcategory.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat kursus: $e')),
      );
    } finally {
      setState(() {});
    }
  }

  // Menggabungkan semua inisialisasi
  Future<void> _loadInitialData() async {
    await _loadUserData();
    await _fetchData();
  }

  // Fungsi Refresh (mirip swipeRefreshLayout.setOnRefreshListener)
  Future<void> _onRefresh() async {
    setState(() {
      // 🔁 Reset semua pilihan ke kondisi awal
      _selectedCategoryId = 0;
      _selectedSubcategoryId = 0;
      _currentSubcategories = [];
      _courseData = [];
    });

    // 🔄 Muat ulang data user, kategori, subkategori, dan kursus
    await _loadInitialData();

    // Opsional: tampilkan notifikasi kecil saat refresh selesai
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data berhasil diperbarui')),
    );
  }


  // Fungsi Pencarian (mirip searchFromServer)
  void _searchCourses(String keyword) async {
    if (keyword.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    try {
      final results = await _apiService.searchCourses(keyword);
      setState(() {
        _searchResults.clear();
        _searchResults.addAll(results);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pencarian gagal: $e')),
      );
      setState(() {
        _searchResults.clear();
      });
    }
  }

  // Fungsi saat Item Hasil Pencarian di-tap (mirip listView.setOnItemClickListener)
  void _onSearchResultTap(SearchItem item) {
    FocusManager.instance.primaryFocus?.unfocus();
    _searchController.clear();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPage(courseId: item.id),
      ),
    ).then((_) {
      // Setelah kembali dari halaman detail, bersihkan hasil pencarian
      setState(() {
        _searchResults.clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= HEADER =================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF0D47A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      // Gambar Profil (mirip Glide + CircleCrop)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          image: DecorationImage(
                            image: NetworkImage(_profileImageUrl),
                            fit: BoxFit.cover,
                            // Fallback jika network image gagal
                            onError: (exception, stackTrace) => const AssetImage("assets/default_user.png"),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hi $_userName", // Data dari SharedPreferences
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            "Welcome 👋",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ================= SEARCH BAR =================
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search...",
                    prefixIcon: const Icon(Icons.search, color: Colors.black),
                    hintStyle: const TextStyle(color: Colors.black54),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: _searchCourses, // Memicu fungsi pencarian API
                ),
              ),

              // ================= SEARCH RESULT (ListView) =================
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2)),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_searchResults[index].title),
                        onTap: () => _onSearchResultTap(_searchResults[index]),
                      );
                    },
                  ),
                ),

              // ================= SISA KOMPONEN UI =================

              if (_isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Colors.blue),
                ))
              else ...[
                // ================= BANNER IMAGE =================
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  height: 220,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: const DecorationImage(
                            image: AssetImage("assets/img_3395.jpg"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= TITLE =================
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Apa itu Training Center?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                // ================= DESCRIPTION =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
                  child: AnimatedCrossFade(
                    firstChild: const Text(
                      "Training Center di Semarang hadir sebagai solusi untuk meningkatkan keahlian dan kompetensi para teknisi...",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    secondChild: const Text(
                      "Training Center di Semarang hadir untuk meningkatkan keahlian dan kompetensi para teknisi. "
                          "Dengan program pelatihan yang dirancang secara profesional, para teknisi akan mendapatkan pembelajaran yang mendalam tentang prinsip kerja mesin, metode perawatan yang efektif, serta teknik pemecahan masalah yang akurat."
                          "Dengan mengikuti pelatihan ini, para teknisi tidak hanya diharapkan menjadi lebih handal dan mumpuni, tetapi juga siap menjadi tenaga profesional yang dapat memberikan kontribusi nyata dalam meningkatkan efisiensi dan produktivitas perusahaan.",
                      textAlign: TextAlign.justify,
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    crossFadeState: _expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ),

                // ================= TOGGLE BUTTON =================
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _expanded = !_expanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _expanded ? "Sembunyikan" : "Lihat Selengkapnya",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),

                // ================= RECYCLERVIEWS =================

                // Recycler 1 (Data dari FetchCategoriesTask)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  height: 120, // Tinggi yang sesuai untuk Card
                  color: const Color(0xFFEFF5FA), // WARNA BACKGROUND #EFF5FA
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categoryListRecyclerA.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final category = _categoryListRecyclerA[index];

                      // Fungsi untuk mendapatkan jalur gambar (tetap sama)
                      String _getAssetPathForCategory(String name) {
                        switch (name) {
                          case "Banking":
                            return "assets/icon_banking.png";
                          case "Digital Media":
                            return "assets/icon_digital_media.png";
                          case "Mesin Penghitung Uang":
                            return "assets/icon_mesin_penghitung.png";
                          case "Mesin Sortir Uang":
                            return "assets/icon_mesin_sortir.png";
                          case "Pengharum Ruangan":
                            return "assets/icon_pengharum.png";
                          case "Mesin Pengikat Uang":
                            return "assets/icon_mesin_pengikat.png";
                          case "Panduan OSS":
                            return "assets/icon_warehouse.png";
                          default:
                            return "assets/icon_default.png";
                        }
                      }

                      // Fungsi untuk mendapatkan warna background lingkaran (opsional)
                      Color getCircleColor(String name) {
                        switch (name) {
                          case "Banking": return const Color(0xFF4A90E2);
                          case "Digital Media": return const Color(0xFF4A90E2);
                          case "Mesin Penghitung Uang": return const Color(0xFF4A90E2);
                          case "Mesin Sortir Uang": return const Color(0xFF4A90E2);
                          case "Pengharum Ruangan": return const Color(0xFF4A90E2);
                          case "Mesin Pengikat Uang": return const Color(0xFF4A90E2);
                          case "Panduan OSS": return const Color(0xFF4A90E2);
                          default: return Colors.grey;
                        }
                      }

                      return GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Kategori ${category.name} diklik!')),
                          );
                        },
                        child: Container(
                          width: 180, // Lebar Card
                          margin: const EdgeInsets.only(right: 8),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Gambar Asset
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: getCircleColor(category.name), // Warna background lingkaran
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.asset(
                                        _getAssetPathForCategory(category.name),
                                        // ================= PERUBAHAN UTAMA DI SINI =================
                                        color: Colors.white, // Memberikan warna (tint) putih pada gambar
                                        // ==========================================================
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error_outline, size: 20, color: Colors.white),
                                      ),
                                    ),
                                  ),

                                  // Subcategory Count
                                  const SizedBox(height: 4),
                                  Text(
                                    '${category.subcategoryCount}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),

                                  // Category Name
                                  Text(
                                    category.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // ==================== SOP / TESTIMONIALS SECTION ====================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "STANDARD OPERATION PROCEDURE (SOP)",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "SOP ini dirancang untuk membantu teknisi memahami cara kerja mesin secara menyeluruh guna menunjang operasional yang efisien dan minim gangguan.",
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),

                      // 🔹 Scroll horizontal sejajar
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 500,
                              child: _buildPdfCard(
                                context,
                                title: "Standar Prosedur Pelayanan Teknisi",
                                description:
                                "Prosedur ini membantu teknisi bekerja sesuai standar, meningkatkan kualitas layanan, serta meminimalkan risiko kesalahan.",
                                pdfAsset:
                                "http://oss.nexis.id/modul/training/assets/dokumen/module/STANDARD OPERATION PROCEDURE.pdf",
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 500,
                              child: _buildPdfCard(
                                context,
                                title: "Prosedur Administrasi & Pelaporan Teknisi",
                                description:
                                "Prosedur ini membantu menjaga konsistensi administrasi, meningkatkan ketepatan pelaporan, serta mendukung kelancaran proses kerja teknisi.",
                                pdfAsset:
                                "http://oss.nexis.id/modul/training/assets/dokumen/module/prosedur administrasi teknisi.pdf",
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),

                // ==================== CATEGORY RECYCLER ====================
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categoriesWithSubs.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemBuilder: (context, index) {
                      final category = _categoriesWithSubs[index];
                      final isSelected = category.id == _selectedCategoryId;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          onPressed: () => _onCategorySelected(category),
                          style: ElevatedButton.styleFrom(
                            elevation: 4,
                            backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
                            foregroundColor: isSelected ? Colors.white : Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            minimumSize: const Size(0, 45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            category.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

// ==================== SUBCATEGORY (JIKA ADA) ====================
                if (_currentSubcategories.isNotEmpty)
                  SizedBox(
                    height: 55,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _currentSubcategories.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemBuilder: (context, index) {
                        final subcategory = _currentSubcategories[index];
                        final isSelected = subcategory.id == _selectedSubcategoryId;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          child: ElevatedButton(
                            onPressed: () => _onSubcategorySelected(subcategory),
                            style: ElevatedButton.styleFrom(
                              elevation: 4,
                              backgroundColor: isSelected ? Colors.blue[100] : Colors.grey[200],
                              foregroundColor: isSelected ? Colors.blue : Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              minimumSize: const Size(0, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              subcategory.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                if (_currentSubcategories.isNotEmpty)
                  const SizedBox(height: 8),

// ==================== RECOMMENDATION RECYCLER ====================
// Jika subcategory kosong → tampil langsung di bawah kategori
// Jika ada subcategory → tampil di bawah subcategory
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _courseData.length,
                    itemBuilder: (context, index) {
                      final course = _courseData[index];
                      final imageUrl =
                          "http://oss.nexis.id/modul/training/assets/img/${course.imageUrl}";

                      debugPrint("📘 [${index + 1}] ${course.title} (${course.id}) -> $imageUrl");

                      return GestureDetector(
                        onTap: () {
                          debugPrint("👆 Klik: ${course.title} (ID: ${course.id})");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailPage(courseId: course.id),
                            ),
                          );
                        },

                        child: Card(
                          elevation: 4,
                          shadowColor: Colors.black26,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                          child: Container(
                            width: 140,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    imageUrl,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return const SizedBox(
                                        width: 120,
                                        height: 120,
                                        child: Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint("⚠️ Gagal load gambar: $imageUrl");
                                      return Image.asset(
                                        "assets/default_course.png",
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.contain,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  course.title,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),


              ]
            ],
          ),
        ),
      ),
    );
  }
}

Future<File?> _getCachedPdfThumbnail(String pdfUrl, String id) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final cachePath = '${dir.path}/pdfthumb_${id.hashCode}.jpg';
    final cacheFile = File(cachePath);

    // Jika thumbnail sudah tersimpan, langsung pakai
    if (await cacheFile.exists()) {
      return cacheFile;
    }

    // Download PDF dari URL
    final response = await http.get(Uri.parse(pdfUrl));
    if (response.statusCode != 200) throw Exception("Failed to load PDF");

    // Render halaman pertama PDF
    final bytes = response.bodyBytes;
    final doc = await PdfDocument.openData(bytes);
    final page = await doc.getPage(1);
    final pageImage = await page.render(
      width: 200,
      height: 120,
      format: PdfPageImageFormat.jpeg,
    );
    await page.close();
    await doc.close();

    // Simpan hasil render ke file lokal
    final imgFile = await cacheFile.writeAsBytes(pageImage?.bytes as List<int>);
    return imgFile;
  } catch (e) {
    debugPrint("❌ Gagal membuat thumbnail PDF: $e");
    return null;
  }
}


Widget _buildPdfCard(
    BuildContext context, {
      required String title,
      required String description,
      required String pdfAsset,
    }) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Thumbnail PDF dengan cache
              FutureBuilder<File?>(
                future: _getCachedPdfThumbnail(pdfAsset, title),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      width: 200,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError || snapshot.data == null) {
                    return Container(
                      width: 200,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.picture_as_pdf, size: 40, color: Colors.redAccent),
                      ),
                    );
                  } else {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        snapshot.data!,
                        width: 200,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    );
                  }
                },
              ),

              const SizedBox(width: 12),

              // Judul + tombol + teks
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15, // 🔹 sedikit kecilin biar rapi
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Modul PDF",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final filePath =
                            await downloadPdf(context, pdfAsset, "$title.pdf");
                            if (filePath != null) {
                              await openPdfFile(filePath);
                            }
                          },
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text("Download"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final filePath =
                            await downloadPdf(context, pdfAsset, "$title.pdf");
                            if (filePath != null && context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PdfPreviewPage(
                                    filePath: filePath,
                                    title: title,
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.visibility, size: 18),
                          label: const Text("Preview"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Deskripsi di bawah
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}






