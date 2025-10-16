import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String fullName = "Guest";
  String email = "Not Available";
  String username = "Unknown";
  String levelUser = "User";
  String photoUrl = "";
  String lastVisit = "";

  double progressPercentage = 0.0;
  int completedCount = 0;
  int totalVideo = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserProgress();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      fullName = prefs.getString("fullname") ?? "Guest";
      email = prefs.getString("email") ?? "Not Available";
      username = prefs.getString("username") ?? "Unknown";
      levelUser = prefs.getString("level_user") ?? "User";
      photoUrl = prefs.getString("photo") ?? "";
      lastVisit =
      "Last visit ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";
    });
  }

  Future<void> _loadUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdString = prefs.getString("user_id");
      if (userIdString == null || userIdString.isEmpty) return;
      final userId = int.tryParse(userIdString) ?? 0;


      if (userId == 0) return;

      final url = Uri.parse(
          "http://oss.nexis.id/modul/training/android/get_user_progress.php?user_id=$userId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            progressPercentage = (data["percentage"] ?? 0) / 100;
            completedCount = data["completed"] ?? 0;
            totalVideo = data["total"] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Error load progress: $e");
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    // Gunakan root navigator agar keluar dari MainPage sepenuhnya
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Logout berhasil!"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showWatchedVideosModal() async {
    final prefs = await SharedPreferences.getInstance();
    final userIdString = prefs.getString("user_id");
    if (userIdString == null || userIdString.isEmpty) return;
    final userId = int.tryParse(userIdString) ?? 0;
    if (userId == 0) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _WatchedVideosSheet(userId: userId);
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === HEADER dengan background gradient ===
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF0D47A1)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Tombol Logout
                      Positioned(
                        top: 30,
                        right: 16,
                        child: IconButton(
                          icon: const Icon(Icons.logout, size: 30, color: Colors.white),
                          onPressed: _logout,
                        ),
                      ),
                      // Foto + Nama + Last Visit
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 40,
                                backgroundImage: photoUrl.isNotEmpty
                                    ? NetworkImage(photoUrl)
                                    : const AssetImage("assets/images/default_user.png")
                                as ImageProvider,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              fullName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastVisit,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // === Weekly Progress Card overlay ===
                Positioned(
                  bottom: -70,
                  left: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: _showWatchedVideosModal, // klik di mana pun buka modal
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: InkWell(
                        // InkWell untuk efek ripple saat diklik
                        borderRadius: BorderRadius.circular(12),
                        onTap: _showWatchedVideosModal,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Circular progress
                              Container(
                                width: 60,
                                height: 60,
                                alignment: Alignment.center,
                                color: Colors.transparent,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 60,
                                      height: 60,
                                      child: CircularProgressIndicator(
                                        value: progressPercentage,
                                        strokeWidth: 6,
                                        backgroundColor: Colors.grey[200],
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                                      ),
                                    ),
                                    Text(
                                      "${(progressPercentage * 100).toStringAsFixed(0)}%",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Detail info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Progress Video",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text("Video Completed"),
                                        Text(
                                          "$completedCount / $totalVideo Video",
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              ],
            ),

            const SizedBox(height: 70), // beri jarak karena card overlay

            // === DETAIL INFORMASI ===
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Nama Lengkap"),
                  _buildValue(fullName),
                  const Divider(),

                  _buildLabel("Email"),
                  _buildValue(email),
                  const Divider(),

                  _buildLabel("Username"),
                  _buildValue(username),
                  const Divider(),

                  _buildLabel("Level User"),
                  _buildValue(levelUser),
                  const Divider(),

                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/edit_profile");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      "Edit Profil",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black54,
      ),
    );
  }

  Widget _buildValue(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _WatchedVideosSheet extends StatefulWidget {
  final int userId;
  const _WatchedVideosSheet({required this.userId});

  @override
  State<_WatchedVideosSheet> createState() => _WatchedVideosSheetState();
}

class _WatchedVideosSheetState extends State<_WatchedVideosSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isLoading = true;
  List<dynamic> _videos = [];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _fetchWatchedVideos();
    _controller.forward();
  }

  Future<void> _fetchWatchedVideos() async {
    try {
      final url = Uri.parse(
          "http://oss.nexis.id/modul/training/android/get_user_watched_videos.php?user_id=${widget.userId}");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            _videos = data["videos"];
          });
        }
      }
    } catch (e) {
      debugPrint("Error load watched videos: $e");
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return FractionalTranslation(
          translation: Offset(0, 1 - _animation.value),
          child: child,
        );
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Video yang Sudah Ditonton",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _videos.isEmpty
                    ? const Center(
                  child: Text("Belum ada video yang ditonton."),
                )
                    : ListView.separated(
                  itemCount: _videos.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final v = _videos[index];
                    return ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green.shade600),
                      title: Text(
                        v["subvideo_name"] ?? "-",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${v["video_name"]}\n${v["date_watched"]} • ${v["time_watched"]}",
                        style: const TextStyle(fontSize: 13),
                      ),
                      isThreeLine: true,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

