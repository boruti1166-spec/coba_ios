import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_page.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  bool showX = false;

  @override
  void initState() {
    super.initState();

    // Animasi fade-in untuk logo N
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();

    // Animasi slide untuk logo X
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Tampilkan logo X setelah 1.2 detik
    Future.delayed(const Duration(milliseconds: 1200), () {
      setState(() {
        showX = true;
      });
      _slideController.forward();
    });

    // Setelah 3 detik, cek login
    Timer(const Duration(milliseconds: 3000), () async {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id");

      if (!mounted) return;
      if (userId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Image.asset(
                "assets/logon.png",
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(width: 10),
            if (showX)
              SlideTransition(
                position: _slideAnimation,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset("assets/logox1.png", width: 100, height: 100),
                    Image.asset("assets/logox2.png", width: 100, height: 100),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
