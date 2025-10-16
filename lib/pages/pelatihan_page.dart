// lib/pelatihan_page.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';

//
// PelatihanPage.dart
// Implementasi Flutter yang meniru PracticeFragment.java (Android Java)
//

// ------------------ Konstanta endpoint ------------------
const String VIDEO_STRUCTURE_URL =
    'http://oss.nexis.id/modul/training/android/get_video_structure.php';
const String TOTAL_INFO_BY_COURSE_URL =
    'http://oss.nexis.id/modul/training/android/get_total_info_by_course.php';
const String CHECK_PROGRESS_URL =
    'http://oss.nexis.id/modul/training/android/check_progress.php';
const String VIDEO_API = 'http://oss.nexis.id/modul/training/android/get_subvideos_by_course.php';
const String CHECK_ACCESS_API = 'http://oss.nexis.id/modul/training/android/check_access.php';
const String SAVE_PROGRESS_API = 'http://oss.nexis.id/modul/training/android/save_progress.php';
const String API_JENIS_TES = 'http://oss.nexis.id/modul/training/android/getJenisTesMesin.php';
const String API_TYPE_MESIN = 'http://oss.nexis.id/modul/training/android/get_TypeMesin.php';
const String API_EXAM = 'http://oss.nexis.id/modul/training/android/api_mesin.php';

// ------------------ Model ------------------
class Subvideo {
  final int id;
  final String name;
  final String videoUrl;
  final int videoId;
  final int position;
  final int courseId;
  final int progressCourseInitial;
  bool watched;

  // runtime fields
  int progressCourse; // 0..100 (mutable)
  bool _progressRequested = false;

  Subvideo({
    required this.id,
    required this.name,
    required this.videoUrl,
    required this.videoId,
    required this.position,
    required this.courseId,
    required this.progressCourseInitial,
    this.watched = false,
  }) : progressCourse = progressCourseInitial;

  factory Subvideo.fromJson(Map<String, dynamic> json) {
    return Subvideo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      videoUrl: json['video_url'] ?? '',
      videoId: json['video_id'] ?? 0,
      position: json['position'] ?? 0,
      courseId: json['course_id'] ?? (json['course_id'] is String ? int.tryParse(json['course_id']) ?? -1 : -1),
      progressCourseInitial: json['progress_course'] ?? 0,
    );
  }

  String get thumbnailUrl {
    // Sama persis mapping thumbnail di Java (pakai id)
    final base = 'http://oss.nexis.id/modul/training/assets/img/thumbnail/thumbnail_mobile/';
    switch (id) {
      case 3:
        return '${base}IX-DEPOS.webp';
      case 9:
        return '${base}SSTCR.webp';
      case 43:
        return '${base}Thumbnail APK 1.jpg';
      case 39:
        return '${base}NX-1300.webp';
      case 35:
        return '${base}NX-1900.webp';
      case 34:
        return '${base}NX-2200.webp';
      case 32:
        return '${base}NX-3000.webp';
      case 40:
        return '${base}NX-4200.webp';
      case 49:
        return '${base}NX-5500.webp';
      case 57:
        return '${base}NX-7700.webp';
      case 56:
        return '${base}NX-8200.webp';
      case 59:
        return '${base}NX-9200.webp';
      case 6:
        return '${base}NX-9300.webp';
      default:
        return '';
    }
  }
}

class TypeMesin {
  final String id;
  final String name;
  TypeMesin({required this.id, required this.name});
  factory TypeMesin.fromJson(Map<String, dynamic> j) => TypeMesin(id: j['id'].toString(), name: j['name'].toString());
  @override
  String toString() => name;
}

class VideoModel {
  final int id;
  final String name;
  final int courseId;
  final int position;
  final List<Subvideo> subvideos;

  VideoModel({
    required this.id,
    required this.name,
    required this.courseId,
    required this.position,
    required this.subvideos,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    int courseId = -1;
    if (json.containsKey('course_ids') && json['course_ids'] is List && (json['course_ids'] as List).isNotEmpty) {
      final first = (json['course_ids'] as List)[0];
      courseId = first is int ? first : int.tryParse(first.toString()) ?? -1;
    } else if (json.containsKey('course_id')) {
      courseId = json['course_id'] is int ? json['course_id'] : int.tryParse(json['course_id'].toString()) ?? -1;
    }

    // ✅ Ambil hanya subvideo dengan position == 1
    final List<Subvideo> subs = [];
    if (json['subvideos'] is List) {
      for (var s in (json['subvideos'] as List)) {
        final sub = Subvideo.fromJson(Map<String, dynamic>.from(s));
        if (sub.position == 1) subs.add(sub);
      }
    }

    return VideoModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      courseId: courseId,
      position: json['position'] ?? 0,
      subvideos: subs,
    );
  }
}

// ------------------ PelatihanPage ------------------
class PelatihanPage extends StatefulWidget {
  const PelatihanPage({super.key});

  @override
  State<PelatihanPage> createState() => _PelatihanPageState();
}

class _PelatihanPageState extends State<PelatihanPage> {
  bool showGrid = false; // seperti recyclerGridSubvideo visibility
  List<VideoModel> videoList = [];
  List<Subvideo> currentSubvideoList = [];

  bool isLoading = true;
  String? error;
  String? currentVideoName;

  String? userId;

  // Caches to reduce network calls
  final Map<int, int> subvideoCountCache = {}; // courseId -> total_subvideos
  final Map<int, int> totalDurationCache = {}; // courseId -> total_duration (seconds)
  final Map<String, int> progressCache = {}; // key = "$userId|$videoId|$subvideoId" -> progress int

  @override
  void initState() {
    super.initState();
    _initAndFetch();
  }

  Future<void> _initAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id') ?? null;
    await fetchVideoData();
  }

  Future<void> fetchVideoData() async {
    setState(() {
      isLoading = true;
      error = null;
      videoList.clear();
      currentSubvideoList.clear();
    });

    try {
      final resp = await http.get(Uri.parse(VIDEO_STRUCTURE_URL)).timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final parsed = jsonDecode(resp.body);
        List<VideoModel> tmp = [];

        if (parsed is List) {
          tmp = parsed.map((v) => VideoModel.fromJson(Map<String, dynamic>.from(v))).toList();
        } else if (parsed is Map && parsed.containsKey('data') && parsed['data'] is List) {
          tmp = (parsed['data'] as List).map((v) => VideoModel.fromJson(Map<String, dynamic>.from(v))).toList();
        } else {
          throw Exception('Format JSON tidak sesuai');
        }

        // === Gabungkan video berdasarkan courseId ===
        final Map<int, VideoModel> merged = {};
        for (var v in tmp) {
          if (!merged.containsKey(v.courseId)) {
            merged[v.courseId] = VideoModel(
              id: v.id,
              name: v.name,
              courseId: v.courseId,
              position: v.position,
              subvideos: List.from(v.subvideos),
            );
          } else {
            merged[v.courseId]!.subvideos.addAll(v.subvideos);
          }
        }

        setState(() {
          videoList = merged.values.toList();
          isLoading = false;
          showGrid = false;
          currentSubvideoList = [];
        });
      } else {
        throw Exception('HTTP ${resp.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        error = 'Gagal memuat data: $e';
      });
    }
  }


  Future<void> fetchCourseInfoIfNeeded(int courseId) async {
    if (subvideoCountCache.containsKey(courseId) && totalDurationCache.containsKey(courseId)) return;
    try {
      final resp = await http.get(Uri.parse('$TOTAL_INFO_BY_COURSE_URL?course_id=$courseId')).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final parsed = jsonDecode(resp.body);
        if (parsed is Map) {
          final int totalSubs = parsed['total_subvideos'] is int ? parsed['total_subvideos'] : int.tryParse(parsed['total_subvideos'].toString()) ?? 0;
          final int totalDuration = parsed['total_duration'] is int ? parsed['total_duration'] : int.tryParse(parsed['total_duration'].toString()) ?? 0;
          subvideoCountCache[courseId] = totalSubs;
          totalDurationCache[courseId] = totalDuration;
        }
      }
    } catch (_) {
      // ignore network error - leave default missing cache
    }
  }

  Future<int> fetchProgressForSubvideo({required int videoId, required int subvideoId}) async {
    if (userId == null) return 0;
    final key = '$userId|$videoId|$subvideoId';
    if (progressCache.containsKey(key)) return progressCache[key]!;

    try {
      final resp = await http.get(Uri.parse('$CHECK_PROGRESS_URL?user_id=$userId&video_id=$videoId&subvideo_id=$subvideoId')).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final parsed = jsonDecode(resp.body);
        if (parsed is Map) {
          final int progress = parsed.containsKey('progress_course')
              ? (parsed['progress_course'] is int ? parsed['progress_course'] : int.tryParse(parsed['progress_course'].toString()) ?? 0)
              : 0;
          progressCache[key] = progress;
          return progress;
        }
      }
    } catch (_) {}
    return 0;
  }

  String formatDuration(int seconds) {
    if (seconds >= 3600) {
      final h = seconds ~/ 3600;
      return '$h jam';
    } else if (seconds >= 60) {
      final m = seconds ~/ 60;
      return '$m menit';
    } else {
      return '$seconds detik';
    }
  }

  // ------------------ UI Widgets ------------------
  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(error ?? 'Terjadi kesalahan'),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: fetchVideoData, child: const Text('Coba lagi'))
      ]),
    );
  }

  Widget _buildVideoList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: videoList.length,
      itemBuilder: (context, index) {
        final v = videoList[index];
        return _buildCategoryItem(v);
      },
    );
  }

  Widget _buildCategoryItem(VideoModel video) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(children: [
            Expanded(child: Text(video.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
            GestureDetector(
              onTap: () {
                setState(() {
                  currentSubvideoList = List<Subvideo>.from(video.subvideos);
                  currentVideoName = video.name; // ✅ simpan nama video
                  showGrid = true;
                });
              },
              child: const Text(
                'Lihat Semua',
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 165,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: video.subvideos.length,
            itemBuilder: (context, idx) {
              final sub = video.subvideos[idx];
              return _buildSubvideoItem(sub);
            },
          ),
        ),
      ]),
    );
  }

  Widget _buildSubvideoItem(Subvideo subvideo) {
    return Container(
      width: 190,
      margin: const EdgeInsets.all(5),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: const Color(0xFFF7F7F7),
          ),
          child: Column(
            children: [
              // ✅ Thumbnail (klik diarahkan ke sini)
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerPage(
                        videoUrl: subvideo.videoUrl,
                        courseId: subvideo.courseId,
                        videoId: subvideo.videoId,
                        subvideoId: subvideo.id,
                        userId: userId,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(5),
                  ),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: subvideo.thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: subvideo.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      errorWidget: (c, u, e) =>
                      const Center(child: Icon(Icons.image_not_supported)),
                    )
                        : const Center(
                        child: Icon(Icons.image, size: 48, color: Colors.grey)),
                  ),
                ),
              ),

              // ProgressBar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: SizedBox(
                  width: 180,
                  height: 6,
                  child: FutureBuilder<int>(
                    future: _ensureProgressAndReturn(subvideo),
                    builder: (context, snapshot) {
                      final progress = snapshot.hasData
                          ? snapshot.data!.clamp(0, 100)
                          : subvideo.progressCourse.clamp(0, 100);
                      final value = progress / 100.0;
                      final color =
                      progress >= 100 ? Colors.blue : const Color(0xFF157eb5);
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(color),
                      );
                    },
                  ),
                ),
              ),

              // Bab dan Durasi
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FutureBuilder<void>(
                      future: fetchCourseInfoIfNeeded(subvideo.courseId),
                      builder: (context, snap) {
                        final count = subvideoCountCache[subvideo.courseId];
                        final text = (count != null && count > 0)
                            ? '$count Video'
                            : (snap.connectionState == ConnectionState.waiting
                            ? 'Memuat...'
                            : '- Video');
                        return Row(
                          children: [
                            const Icon(Icons.play_arrow,
                                size: 16, color: Colors.black54),
                            const SizedBox(width: 4),
                            Text(text,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                          ],
                        );
                      },
                    ),
                    FutureBuilder<void>(
                      future: fetchCourseInfoIfNeeded(subvideo.courseId),
                      builder: (context, snap) {
                        final dur = totalDurationCache[subvideo.courseId];
                        final text = (dur != null && dur > 0)
                            ? formatDuration(dur)
                            : (snap.connectionState == ConnectionState.waiting
                            ? 'Memuat...'
                            : '-');
                        return Row(
                          children: [
                            const Icon(Icons.timer,
                                size: 16, color: Colors.black54),
                            const SizedBox(width: 4),
                            Text(text,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ❌ Hilangkan judul (text subvideo)
            ],
          ),
        ),
      ),
    );
  }


  // memastikan progress hanya dipanggil 1x per subvideo dan update cache
  Future<int> _ensureProgressAndReturn(Subvideo sub) async {
    if (sub._progressRequested) {
      final key = '${userId ?? 'null'}|${sub.videoId}|${sub.id}';
      return progressCache[key] ?? sub.progressCourse;
    }
    sub._progressRequested = true;
    final p = await fetchProgressForSubvideo(videoId: sub.videoId, subvideoId: sub.id);
    setState(() {
      sub.progressCourse = p;
      final key = '${userId ?? 'null'}|${sub.videoId}|${sub.id}';
      progressCache[key] = p;
    });
    return p;
  }

  Widget _buildGridView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = 2;
    final spacing = 8;
    // hitung lebar aktual item
    final itemWidth = (screenWidth - (spacing * (crossAxisCount + 1))) / crossAxisCount;
    // atur tinggi biar proporsional (ubah multiplier sesuai bentuk ideal)
    final itemHeight = itemWidth * 1.0;
    final aspectRatio = itemWidth / itemHeight;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {
            setState(() {
              showGrid = false;
              currentSubvideoList = [];
            });
          }),
          const SizedBox(width: 8),
          Text(
            currentVideoName != null ? '${currentVideoName!}' : 'Semua Subvideo',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ]),
      ),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: spacing.toDouble(),
            mainAxisSpacing: spacing.toDouble(),
          ),
          itemCount: currentSubvideoList.length,
          itemBuilder: (context, idx) {
            final sub = currentSubvideoList[idx];
            return _buildSubvideoItem(sub);
          },
        ),
      ),
    ]);
  }


  // ------------------ Build Page ------------------
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (showGrid) {
          // kalau sedang di halaman grid subvideo, jangan keluar — tapi kembali ke list video
          setState(() {
            showGrid = false;
            currentSubvideoList = [];
          });
          return false; // cegah keluar dari halaman
        }
        return true; // boleh keluar kalau bukan di grid
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          onRefresh: fetchVideoData,
          child: isLoading
              ? _buildLoading()
              : (error != null
              ? _buildError()
              : (showGrid ? _buildGridView() : _buildVideoList())),
        ),
      ),
    );
  }

}

// ------------------ VideoPlayerPage Full Implementation ------------------
class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final int courseId;
  final int videoId;
  final int subvideoId;
  final String? userId;

  const VideoPlayerPage({
    super.key,
    required this.videoUrl,
    required this.courseId,
    required this.videoId,
    required this.subvideoId,
    required this.userId,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  bool isLoading = true;

  List<Subvideo> relatedSubvideos = [];
  bool showSubvideoList = true;

  // 🟢 Tambahan baru
  int? currentSubvideoId;
  Map<int, bool> accessMap = {}; // subvideoId -> canWatch

  @override
  void initState() {
    super.initState();
    _fetchSubvideosAndCheckAccess();
  }

  Future<void> _fetchSubvideosAndCheckAccess() async {
    await _fetchSubvideos(widget.courseId);

    // Inisialisasi default akses false
    for (var sub in relatedSubvideos) {
      accessMap[sub.id] = false;
    }

    // Jalankan semua check_access paralel (lebih cepat)
    await Future.wait(relatedSubvideos.map((sub) async {
      await _checkVideoAccess(sub.videoId, sub.id, sub.videoUrl, autoPlay: false);
    }));

    // Setelah semua selesai dicek → mainkan subvideo aktif
    final activeId = widget.subvideoId;
    if (accessMap[activeId] == true) {
      currentSubvideoId = activeId;
      await _playVideo(widget.videoUrl, widget.videoId, widget.subvideoId);
    }

    setState(() {});
  }




  Future<void> _fetchSubvideos(int courseId) async {
    try {
      final resp = await http
          .get(Uri.parse('$VIDEO_API?course_id=$courseId&user_id=${widget.userId}'))
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final jsonArray = jsonDecode(resp.body);
        if (jsonArray is List) {
          relatedSubvideos = jsonArray
              .map((e) => Subvideo.fromJson(Map<String, dynamic>.from(e)))
              .toList();

          // ✅ Urutkan berdasarkan videoId dulu, baru position
          relatedSubvideos.sort((a, b) {
            final compareVideo = a.videoId.compareTo(b.videoId);
            if (compareVideo != 0) return compareVideo;
            return a.position.compareTo(b.position);
          });
        }
      } else {
        debugPrint('Gagal fetch subvideos: status ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal fetch subvideos: $e');
    }

    setState(() {});
  }


  Future<void> _checkVideoAccess(int videoId, int subvideoId, String videoUrl, {bool autoPlay = false}) async {
    try {
      final resp = await http
          .get(Uri.parse('$CHECK_ACCESS_API?user_id=${widget.userId}&video_id=$videoId&subvideo_id=$subvideoId'))
          .timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200) {
        final jsonResp = jsonDecode(resp.body);
        final canWatch = jsonResp['can_watch'] == true;
        accessMap[subvideoId] = canWatch;

        // Autoplay hanya untuk video yang ditentukan
        if (autoPlay && canWatch) {
          currentSubvideoId = subvideoId;
          await _playVideo(videoUrl, videoId, subvideoId);
        }
        setState(() {});
      }
    } catch (e) {
      debugPrint('Check access error: $e');
    }
  }





  // ---------------- Safe _playVideo ----------------
  Future<void> _playVideo(String url, int videoId, int subvideoId) async {
    try {
      // 🔹 Dispose controller lama jika ada
      _chewieController?.dispose();
      if (_videoPlayerController != null) {
        await _videoPlayerController!.pause();
        await _videoPlayerController!.dispose();
      }

      // 🔹 Buat controller baru
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
      );

      _videoPlayerController!.addListener(() async {
        final controller = _videoPlayerController!;
        if (!controller.value.isInitialized) return;

        if (controller.value.position >= controller.value.duration &&
            !controller.value.isPlaying) {
          await _saveProgress(videoId, subvideoId);
        }
      });

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Play video error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }


  Future<File?> _getCachedThumbnail(String videoUrl, String id) async {
    try {
      // Gunakan direktori permanen agar cache tetap ada meski app ditutup
      final dir = await getApplicationDocumentsDirectory();
      final thumbPath = '${dir.path}/thumb_$id.jpg';
      final file = File(thumbPath);

      // Kalau sudah ada thumbnail-nya di cache, langsung pakai
      if (await file.exists()) return file;

      // Kalau belum, generate thumbnail baru
      final uint8list = await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 128,
        quality: 75,
        timeMs: 1000,
      );

      if (uint8list == null) return null;

      // Simpan thumbnail ke file cache
      await file.writeAsBytes(uint8list);
      return file;
    } catch (e) {
      print('❌ Thumbnail error: $e');
      return null;
    }
  }


  Future<void> _saveProgress(int videoId, int subvideoId) async {
    try {
      final resp = await http.post(
        Uri.parse(SAVE_PROGRESS_API),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'user_id': widget.userId ?? '',
          'video_id': videoId.toString(),
          'subvideo_id': subvideoId.toString(),
        },
      ).timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200) {
        // Update progress current video
        for (var sub in relatedSubvideos) {
          if (sub.id == subvideoId) sub.progressCourse = 100;
        }

        // 🔓 Unlock next video jika ada
        final currentIndex = relatedSubvideos.indexWhere((s) => s.id == subvideoId);
        if (currentIndex >= 0 && currentIndex < relatedSubvideos.length - 1) {
          final nextSub = relatedSubvideos[currentIndex + 1];
          accessMap[nextSub.id] = true;
          setState(() {});
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text('Video berikutnya "${nextSub.name}" telah terbuka 🔓')),
          // );

          // 🔁 Auto-play video berikutnya
          await Future.delayed(const Duration(seconds: 1));
          setState(() {
            currentSubvideoId = nextSub.id;
            isLoading = true;
          });
          await _playVideo(nextSub.videoUrl, nextSub.videoId, nextSub.id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Semua video sudah selesai ✅')),
          );
        }
      }
    } catch (e) {
      debugPrint('Save progress error: $e');
    }
  }


  // ---------------- Safe _onSubvideoClick ----------------
  void _onSubvideoClick(Subvideo sub) async {
    if (isLoading) return; // 🔹 batasi klik saat video masih loading
    if (accessMap[sub.id] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video ini terkunci 🔒')),
      );
      return;
    }

    setState(() {
      currentSubvideoId = sub.id;
      isLoading = true;
    });

    await _playVideo(sub.videoUrl, sub.videoId, sub.id);
  }



  void _showExamDialog() {
    if (widget.courseId == -1) return;

    showDialog(
      context: context,
      builder: (context) {
        final etNama = TextEditingController();
        String? selectedJenisTes;
        String? selectedTypeMesin;
        String? selectedGender;
        List<String> jenisTesList = ["-- Pilih Jenis Tes --"];
        List<String> typeMesinList = ["-- Pilih Type Mesin --"];
        List<String> genderList = ["-- Pilih Jenis Kelamin --", "Laki-laki", "Perempuan"];

        // Ambil jenis tes & type mesin dari API
        http.get(Uri.parse('$API_JENIS_TES?user_id=${widget.userId}&id=${widget.courseId}')).then((r) {
          if (r.statusCode == 200) {
            final arr = jsonDecode(r.body);
            if (arr is List) jenisTesList.addAll(arr.map((e) => e.toString()));
            setState(() {});
          }
        });
        http.get(Uri.parse('$API_TYPE_MESIN?course_id=${widget.courseId}')).then((r) {
          if (r.statusCode == 200) {
            final arr = jsonDecode(r.body);
            if (arr is List) typeMesinList.addAll(arr.map((e) => e['name'].toString()));
            setState(() {});
          }
        });

        return AlertDialog(
          title: const Text('Form Pelatihan'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: etNama, decoration: const InputDecoration(labelText: 'Nama')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedJenisTes,
                  items: jenisTesList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => selectedJenisTes = v,
                  decoration: const InputDecoration(labelText: 'Jenis Tes'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedTypeMesin,
                  items: typeMesinList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => selectedTypeMesin = v,
                  decoration: const InputDecoration(labelText: 'Type Mesin'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  items: genderList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => selectedGender = v,
                  decoration: const InputDecoration(labelText: 'Gender'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final nama = etNama.text.trim();
                if (nama.isEmpty || selectedJenisTes == null || selectedGender == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi semua data!')));
                  return;
                }

                // TODO: panggil API_EXAM & pindah ke TestPage
                Navigator.of(context).pop();
              },
              child: const Text('Mulai Test'),
            )
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _videoPlayerController!.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player'),
        actions: [
          IconButton(
            icon: const Icon(Icons.school),
            onPressed: _showExamDialog,
          ),
          IconButton(
            icon: Icon(showSubvideoList ? Icons.arrow_drop_up : Icons.arrow_drop_down),
            onPressed: () => setState(() => showSubvideoList = !showSubvideoList),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          AspectRatio(
            aspectRatio: _videoPlayerController?.value.aspectRatio ?? 16/9,
            child: _chewieController != null
                ? Chewie(controller: _chewieController!)
                : const Center(child: CircularProgressIndicator()),
          )
          ,
          if (showSubvideoList)
            Expanded(
              child: ListView.builder(
                itemCount: relatedSubvideos.length,
                itemBuilder: (context, index) {
                  final sub = relatedSubvideos[index];
                  final bool isActive = sub.id == currentSubvideoId;
                  final bool? canWatch = accessMap[sub.id];

                  return Container(
                    color: isActive ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                    child: ListTile(
                      // ✅ pakai cache thumbnail lokal
                      leading: FutureBuilder<File?>(
                        future: _getCachedThumbnail(sub.videoUrl, sub.id.toString()),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              width: 64,
                              height: 36,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          }
                          if (snapshot.hasData && snapshot.data != null) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.file(
                                snapshot.data!,
                                width: 64,
                                height: 36,
                                fit: BoxFit.cover,
                              ),
                            );
                          }
                          return const Icon(Icons.error);
                        },
                      ),

                      title: Text(
                        sub.name,
                        style: TextStyle(
                          fontSize: 13, // 🔹 kecilin font title
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: canWatch == false ? Colors.grey : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        '${sub.progressCourse}% watched',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: canWatch == false
                          ? const Icon(Icons.lock, color: Colors.red)
                          : (isActive
                          ? const Icon(Icons.play_arrow, color: Colors.blue)
                          : null),
                      tileColor: isActive ? Colors.blue.withOpacity(0.1) : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      onTap: canWatch == false ? null : () => _onSubvideoClick(sub),
                    ),
                  );
                },
              ),
            ),


        ],
      ),
    );
  }
}

