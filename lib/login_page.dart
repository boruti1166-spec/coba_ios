import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    final idKaryawan = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (idKaryawan.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ID Karyawan dan Password wajib diisi")),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final url = Uri.parse(
        "http://oss.nexis.id/modul/training/login_act_andro.php"
            "?id_karyawan=$idKaryawan&password=$password",
      );

      final response = await http.post(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("user_id", data["user_id"]);
          await prefs.setString("username", data["username"] ?? "");
          await prefs.setString("fullname", data["fullname"] ?? "");
          await prefs.setString("email", data["email"] ?? "");
          await prefs.setString("level_user", data["level_user"] ?? "");
          await prefs.setString(
            "photo",
            (data["photo"] ?? "http://oss.nexis.id/modul/training/assets/img/user/default-user.png").toString(),
          );

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainPage()),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login berhasil")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "Login gagal")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/logo12.jpg"), // background
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  "assets/logo1.png",
                  width: 100,
                  height: 100,
                ),
                const SizedBox(height: 15),

                // Judul Login
                const Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // @color/backgroundLight
                  ),
                ),

                const Text(
                  "Sign in to continue!",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),

                // Username
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.black), // textPrimary
                  decoration: InputDecoration(
                    hintText: "Masukkan ID Karyawan",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: "Password",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Tombol Login
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // @drawable/button_gradient (bisa custom)
                      minimumSize: const Size.fromHeight(50),
                      padding: const EdgeInsets.all(10),
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "Login",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                // Kalau mau tambah Register (commented di XML)
                // TextButton(
                //   onPressed: () {},
                //   child: const Text(
                //     "I'm a new user, Sign Up",
                //     style: TextStyle(color: Colors.grey, fontSize: 14),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
