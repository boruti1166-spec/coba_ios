import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Training App",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(), // Pertama kali buka, ke Splash dulu
    );
  }
}
