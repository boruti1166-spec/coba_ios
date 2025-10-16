import 'package:flutter/material.dart';

class UjianPage extends StatelessWidget {
  const UjianPage({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double imageHeight = screenWidth / 2.25; // sesuai rasio 1500x667

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ==================== GAMBAR UTAMA (NO MARGIN TOP) ====================
          Image.network(
            'http://oss.nexis.id/modul/training/assets/img/thumbnail/thumbnail_mobile/SSTCR.webp',
            width: double.infinity,
            height: imageHeight,
            fit: BoxFit.cover,
          ),

          // ==================== TOMBOL BACK DI ATAS GAMBAR ====================
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

          // ==================== KONTEN BULAT DI BAWAH ====================
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
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================= TITLE =================
                  const Text(
                    "Modul & Panduan Penggunaan IX-1000",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                  _CategorySection(),

                  const SizedBox(height: 20),

                  // ================= GALLERY =================
                  const Text(
                    "Gallery",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildGalleryItem(
                            "https://upload.wikimedia.org/wikipedia/commons/f/f1/Warsaw_Palace_of_Culture_and_Science.jpg"),
                        _buildGalleryItem(
                            "https://upload.wikimedia.org/wikipedia/commons/e/ef/Palace_of_Culture_and_Science_in_Warsaw_%282019%29.jpg"),
                        _buildGalleryItem(
                            "https://upload.wikimedia.org/wikipedia/commons/8/8a/Palac_Kultury_i_Nauki_1.jpg"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryItem(String imageUrl) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
      ),
    );
  }
}

class _CategorySection extends StatefulWidget {
  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  String selectedCategory = "All";

  // Data dummy
  final List<Map<String, dynamic>> places = [
    {
      "category": "Sightseeing",
      "title": "Palace of Culture and Science",
      "distance": "500 m",
      "image":
      "https://upload.wikimedia.org/wikipedia/commons/f/f1/Warsaw_Palace_of_Culture_and_Science.jpg",
    },
    {
      "category": "Museums",
      "title": "The Royal Castle, Warsaw",
      "distance": "2.5 km",
      "image":
      "https://upload.wikimedia.org/wikipedia/commons/8/88/Royal_Castle_in_Warsaw.jpg",
    },
    {
      "category": "Parks",
      "title": "Lazienki Park",
      "distance": "3.2 km",
      "image":
      "https://upload.wikimedia.org/wikipedia/commons/d/d3/Lazienki_Park_Warsaw.jpg",
    },
    {
      "category": "Food",
      "title": "Zapiecek Restaurant",
      "distance": "1.1 km",
      "image":
      "https://upload.wikimedia.org/wikipedia/commons/f/f7/Pierogi_ruskie_3.jpg",
    },
  ];

  final List<String> categories = ["All", "Sightseeing", "Museums", "Parks", "Food"];

  @override
  Widget build(BuildContext context) {
    // Filter sesuai kategori
    final filteredPlaces = selectedCategory == "All"
        ? places
        : places.where((p) => p["category"] == selectedCategory).toList();

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
                    color: isActive ? Colors.orange : Colors.grey.shade200,
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

        // ================= DAFTAR TEMPAT =================
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filteredPlaces.length,
            itemBuilder: (context, index) {
              final place = filteredPlaces[index];
              return _buildPlaceCard(
                imageUrl: place["image"],
                title: place["title"],
                distance: place["distance"],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceCard({
    required String imageUrl,
    required String title,
    required String distance,
  }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar dengan icon love
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(Icons.favorite_border,
                      size: 18, color: Colors.orange),
                ),
              ),
            ],
          ),

          // Teks bawah
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      distance,
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

