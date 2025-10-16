import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../PdfPreviewPage.dart';
import '../pdf_utils.dart';

class DetailPage extends StatefulWidget {
  final int courseId;

  const DetailPage({super.key, required this.courseId});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Map<String, dynamic>? courseData;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchCourseDetail();
  }

  Future<void> _fetchCourseDetail() async {
    try {
      final url =
          'http://oss.nexis.id/modul/training/android/get_courses.php?course_id=${widget.courseId}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded.containsKey('error')) {
          setState(() {
            hasError = true;
            isLoading = false;
          });
          return;
        }
        setState(() {
          courseData = decoded;
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double imageHeight = screenWidth / 2.25;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (hasError || courseData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Detail Course")),
        body: const Center(child: Text("Gagal memuat data course.")),
      );
    }

    final thumbnailUrl =
    courseData!['thumbnail_mobile'] != null && courseData!['thumbnail_mobile'] != ''
        ? 'http://oss.nexis.id/modul/training/assets/img/thumbnail/thumbnail_mobile/${courseData!['thumbnail_mobile']}'
        : null;

    final galleryImages = [
      if (courseData!['description_image'] != null && courseData!['description_image'] != '')
        'http://oss.nexis.id/modul/training/assets/img/brosur/${courseData!['description_image']}',
      if (courseData!['description_image2'] != null && courseData!['description_image2'] != '')
        'http://oss.nexis.id/modul/training/assets/img/brosur/${courseData!['description_image2']}',
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ==================== GAMBAR UTAMA ====================
          if (thumbnailUrl != null)
            Image.network(
              thumbnailUrl,
              width: double.infinity,
              height: imageHeight,
              fit: BoxFit.cover,
            )
          else
            Container(
              width: double.infinity,
              height: imageHeight,
              color: Colors.grey.shade300,
              child: const Center(child: Text("Thumbnail belum tersedia")),
            ),

          // ==================== TOMBOL BACK ====================
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white70,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
          ),

          // ==================== KONTEN ====================
          Container(
            margin: EdgeInsets.only(top: imageHeight - 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Modul & Panduan Penggunaan",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    courseData!['title'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ================= DISTANCE & RATING =================
                  const Text(
                    "Modul ini berisi mengenai panduan lengkap mengenai panduan, perawatan dan troubleshooting sistem. Modul ini dirancang untuk membantu teknisi memahami cara kerja mesin secara menyeluruh guna menunjang operasional yang efisien dan minim gangguan.",
                    style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                  ),
                  const SizedBox(height: 20),

                  // ================= REKOMENDASI TEMPAT ================

                  // Widget kategori + daftar tempat
                  _CategorySection(courseData: courseData!),

                  const SizedBox(height: 20),

                  // ==================== GALLERY ====================
                  const Text(
                    "Deskripsi",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  if (galleryImages.isEmpty)
                    const Center(
                      child: Text(
                        "Deskripsi belum tersedia",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: galleryImages.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ImageZoomViewer(
                                    images: galleryImages,
                                    initialIndex: index,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: NetworkImage(galleryImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatefulWidget {
  final Map<String, dynamic> courseData;
  const _CategorySection({super.key, required this.courseData});

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  String selectedCategory = "All";

  // Kategori
  final List<String> categories = ["All", "Modul Training", "Manual Book", "Service Manual"];

  Future<File?> _getCachedPdfThumbnail(String pdfUrl, String id) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cachePath = '${dir.path}/pdfthumb_${id.hashCode}.jpg';
      final cacheFile = File(cachePath);

      if (await cacheFile.exists()) return cacheFile;

      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode != 200) throw Exception("Failed to load PDF");

      final bytes = response.bodyBytes;
      final doc = await PdfDocument.openData(bytes);
      final page = await doc.getPage(1);

      // DETEKSI ORIENTASI HALAMAN
      final pageWidth = page.width;
      final pageHeight = page.height;
      double renderWidth = 200;
      double renderHeight = 120;

      if (pageHeight > pageWidth) {
        // Vertikal
        renderWidth = 120;
        renderHeight = 200;
      }

      final pageImage = await page.render(
        width: renderWidth,
        height: renderHeight,
        format: PdfPageImageFormat.jpeg,
      );


      await page.close();
      await doc.close();

      return await cacheFile.writeAsBytes(pageImage?.bytes as List<int>);
    } catch (e) {
      debugPrint("❌ Gagal membuat thumbnail PDF: $e");
      return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    // Ambil daftar PDF sesuai kategori dari courseData
    List<Map<String, String>> pdfList = [];

    if (selectedCategory == "All" || selectedCategory == "Modul Training") {
      if (widget.courseData['pdf_module'] != null && widget.courseData['pdf_module'] != '') {
        // Split pdf_module menjadi list file individual
        final moduleFiles = widget.courseData['pdf_module']
            .toString()
            .split(',')
            .map((f) => f.trim())
            .where((f) => f.isNotEmpty)
            .toList();

        for (var file in moduleFiles) {
          pdfList.add({
            "category": "Modul Training",
            "pdf": "http://oss.nexis.id/modul/training/assets/dokumen/module/$file",
          });
        }
      }
    }

    if (selectedCategory == "All" || selectedCategory == "Manual Book") {
      if (widget.courseData['pdf_url'] != null && widget.courseData['pdf_url'] != '') {
        final manualFiles = widget.courseData['pdf_url']
            .toString()
            .split(',')
            .map((f) => f.trim())
            .where((f) => f.isNotEmpty)
            .toList();

        for (var file in manualFiles) {
          pdfList.add({
            "category": "Manual Book",
            "pdf": "http://oss.nexis.id/modul/training/assets/dokumen/$file",
          });
        }
      }
    }

    if (selectedCategory == "All" || selectedCategory == "Service Manual") {
      if (widget.courseData['pdf_service'] != null && widget.courseData['pdf_service'] != '') {
        final serviceFiles = widget.courseData['pdf_service']
            .toString()
            .split(',')
            .map((f) => f.trim())
            .where((f) => f.isNotEmpty)
            .toList();

        for (var file in serviceFiles) {
          pdfList.add({
            "category": "Service Manual",
            "pdf": "http://oss.nexis.id/modul/training/assets/dokumen/service/$file",
          });
        }
      }
    }


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ================= KATEGORI PILIHAN =================
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final bool isActive = selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => selectedCategory = cat),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.blue : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // ================= DAFTAR PDF =================
        if (pdfList.isEmpty)
          SizedBox(
            height: 150,
            child: Center(
              child: Text(
                "Dokumen belum tersedia",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else
          SizedBox(
            height: 240, // Tinggi card lebih tinggi untuk tombol di bawah
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: pdfList.length,
              itemBuilder: (context, index) {
                final pdf = pdfList[index]['pdf']!;
                return SizedBox(
                  width: 280, // Lebar card
                  child: _buildPdfCard(context, pdfAsset: pdf),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<Size> _getImageSizeFromFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = await decodeImageFromList(bytes);
      return Size(decoded.width.toDouble(), decoded.height.toDouble());
    } catch (e) {
      debugPrint("❌ Gagal membaca ukuran image: $e");
      return const Size(250, 140); // default
    }
  }

  Widget _buildPdfCard(BuildContext context, {required String pdfAsset}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Thumbnail PDF
            FutureBuilder<File?>(
              future: _getCachedPdfThumbnail(pdfAsset, pdfAsset),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    width: 250,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasData && snapshot.data != null) {
                  final file = snapshot.data!;
                  return FutureBuilder<Size>(
                    future: _getImageSizeFromFile(file),
                    builder: (context, sizeSnapshot) {
                      double width = 250;
                      double height = 140;
                      if (sizeSnapshot.hasData) {
                        final size = sizeSnapshot.data!;
                        if (size.height > size.width) {
                          // PDF Vertikal
                          width = 130;
                          height = 140;
                        } else {
                          // PDF Horizontal
                          width = 250;
                          height = 140;
                        }
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          file,
                          width: width,
                          height: height,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  );
                } else {
                  return Container(
                    width: 250,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.picture_as_pdf, size: 40, color: Colors.redAccent),
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 12),

            // Tombol Download & Preview
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final filePath =
                      await downloadPdf(context, pdfAsset, pdfAsset.split('/').last);
                      if (filePath != null) await openPdfFile(filePath);
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text("Download"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final filePath =
                      await downloadPdf(context, pdfAsset, pdfAsset.split('/').last);
                      if (filePath != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PdfPreviewPage(
                              filePath: filePath,
                              title: pdfAsset.split('/').last,
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text("Preview"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}




// ==================== HALAMAN ZOOM IMAGE ====================
class ImageZoomViewer extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const ImageZoomViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    PageController controller = PageController(initialPage: initialIndex);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            itemCount: images.length,
            pageController: controller,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(images[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3.0,
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

