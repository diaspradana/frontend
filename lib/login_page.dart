import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config.dart';
import 'admin/admin_dashboard.dart';
import 'admin/approver_dashboard.dart';
import 'warga/warga_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isObscure = true; // State untuk menyembunyikan password
  bool _rememberMe = false; // State untuk toggle Remember Me

  // Animation Variables
  late AnimationController _animController;
  late Animation<Offset> _slideTopAnimation;
  late Animation<Offset> _slideBottomAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();

    _animController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 1400)
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut)
    );

    _slideTopAnimation = Tween<Offset>(begin: const Offset(0.0, -0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic))
    );

    _slideBottomAnimation = Tween<Offset>(begin: const Offset(0.0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic))
    );

    _animController.forward();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('saved_username');
    final savedPassword = prefs.getString('saved_password');
    if (savedUsername != null && savedPassword != null) {
      setState(() {
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  // Helper function untuk pop-up notifikasi di atas
  void _showTopNotification(String message, Color color) {
    FocusManager.instance.primaryFocus?.unfocus(); // Sembunyikan keyboard terlebih dahulu
    final screenHeight = MediaQuery.of(context).size.height;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: screenHeight - 150, // Posisikan di atas layar
          left: 20,
          right: 20,
        ),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _login() async {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    // 1. Validasi Input Kosong
    if (username.isEmpty || password.isEmpty) {
      _showTopNotification('Username dan Password tidak boleh kosong!', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 2. HTTP POST Request ke backend Node.js
      // Gunakan 10.0.2.2 karena kita menggunakan Android Emulator
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Jika status 200 (Login Berhasil)
        final String token = data['token'];
        final String role = data['user']['role'];
        final String usernameRes = data['user']['username'] ?? username;

        // Simpan jwt token dan data role ke shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('user_role', role);
        await prefs.setString('username', usernameRes);

        // Jika Remember Me dicentang, simpan kredensial secara lokal
        if (_rememberMe) {
          await prefs.setString('saved_username', username);
          await prefs.setString('saved_password', password);
        } else {
          // Jika tidak, hapus kredensial jika sebelumnya pernah tersimpan
          await prefs.remove('saved_username');
          await prefs.remove('saved_password');
        }

        if (!mounted) return;

        // Popup: Login Berhasil
        _showTopNotification('Login Berhasil!', Colors.green);

        // 3. Routing Berdasarkan Role
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        } else if (role == 'rt' || role == 'rw') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ApproverDashboard()),
          );
        } else if (role == 'warga') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WargaDashboard()),
          );
        }
      } else {
        // Popup: Login Gagal dari backend (contoh: password salah)
        if (!mounted) return;
        _showTopNotification(data['message'] ?? 'Username atau Password salah!', Colors.red);
      }
    } catch (e) {
      // Popup: Gagal Network / Server mati
      if (!mounted) return;
      _showTopNotification('Gagal terhubung ke server. Pastikan API menyala.', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0C2A15),
              Color(0xFF1A6B32),
              Color(0xFF2CB5B3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // --- Bagian Atas (Teks Header) ---
              Expanded(
                flex: 4,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideTopAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tombol Kembali
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Judul Besar
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.almendra(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.normal,
                                height: 1.2,
                              ),
                              children: const [
                                TextSpan(text: 'Masuk Untuk Terus\n'),
                                TextSpan(
                                  text: 'Memantau ',
                                  style: TextStyle(color: Color(0xFFA1EAE9)),
                                ),
                                TextSpan(text: 'Transaparansi\nKeuangan.'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // --- Bagian Bawah (Card Putih Rounded) ---
              Expanded(
                flex: 7,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideBottomAnimation,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40),
                          child: Column(
                            children: [
                              Text(
                                'Selamat Datang!',
                                style: GoogleFonts.almendra(
                                  color: Colors.black,
                                  fontSize: 38,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 15),
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                  children: [
                                    TextSpan(text: 'Silakan masuk dengan akun Anda'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),

                              // Form Input Username
                              TextField(
                                controller: _usernameController, // Controller terpasang
                                decoration: InputDecoration(
                                  hintText: 'Username',
                                  hintStyle: TextStyle(color: Colors.grey.shade500),
                                  prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade500),
                                  filled: true,
                                  fillColor: const Color(0xFFF7F7F7),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Form Input Password
                              TextField(
                                controller: _passwordController, // Controller terpasang
                                obscureText: _isObscure,
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: TextStyle(color: Colors.grey.shade500),
                                  prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade500),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isObscure ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey.shade500,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isObscure = !_isObscure;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF7F7F7),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 25),

                              // Remember Me
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                      activeColor: const Color(0xFF2CB5B3),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Remember Me',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 40),

                              // Tombol Submit Login
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login, // Eksekusi fungsi login
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 0, 131, 39),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text(
                                          'Login',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
