import 'package:flutter/material.dart';
import 'login_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideTextAnimation;
  late Animation<Offset> _slideImageAnimation;
  late Animation<Offset> _slideCardsAnimation;

  @override
  void initState() {
    super.initState();
    // Inisialisasi AnimationController
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Fade-in umum
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.8, curve: Curves.easeOut)),
    );

    // Animasi teks herosection masuk dari sisi kiri
    _slideTextAnimation = Tween<Offset>(begin: const Offset(-0.2, 0.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)),
    );

    // Animasi ilustrasi masuk dari sisi kanan
    _slideImageAnimation = Tween<Offset>(begin: const Offset(0.2, 0.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic)),
    );

    // Animasi fitur kartu masuk dari bawah ke atas
    _slideCardsAnimation = Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic)),
    );

    // Memuat animasi saat halaman pertama kali dibuka
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mendapatkan properti ukuran layar untuk menentukan layout (Responsive)
    var size = MediaQuery.of(context).size;
    bool isDesktop = size.width >= 900;
    bool isTablet = size.width >= 600 && size.width < 900;
    bool isMobile = size.width < 600;

    double horizontalPadding = isDesktop ? 60.0 : (isTablet ? 40.0 : 20.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F3A1D), 
              Color(0xFF1A6B32),
              Color(0xFF092913),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isMobile ? 30.0 : 50.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroSection(context, isDesktop, isMobile),
                SizedBox(height: isMobile ? 60 : 100),
                _buildFeaturesRow(context, isMobile),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDesktop, bool isMobile) {
    // Membungkus elemen kiri dan kanan dengan animasi yang sudah dibuat
    List<Widget> content = [
      // Kiri (Teks dan Button)
      FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideTextAnimation,
          child: Container(
            width: isDesktop ? 550 : double.infinity,
            padding: EdgeInsets.only(bottom: isDesktop ? 0 : 40),
            child: Column(
              crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Text(
                  'Transparansi Keuangan RT/RW',
                  textAlign: isMobile ? TextAlign.center : TextAlign.left,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 36 : 48,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Berbasis Platform Digital',
                  textAlign: isMobile ? TextAlign.center : TextAlign.left,
                  style: TextStyle(
                    color: const Color(0xFFCDEBD6),
                    fontSize: isMobile ? 22 : 28,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w300,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  'Sistem terintegrasi untuk membantu pengurus RT/RW dalam mengelola iuran, mencatat pengeluaran, serta menyajikan laporan secara real-time. Membangun lingkungan yang jujur, aman, dan dapat divalidasi oleh setiap warganya.',
                  textAlign: isMobile ? TextAlign.center : TextAlign.left,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: isMobile ? 15 : 16,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 35),
                
                // Group Tombol
                Wrap(
                  alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
                  spacing: 15,
                  runSpacing: 15,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Animasi kecil saat pindah ke halaman login
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF165928),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        elevation: 10,
                        shadowColor: Colors.black38,
                      ),
                      child: const Text(
                        'Akses Portal Login',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF88D29B), width: 1.5),
                        backgroundColor: const Color(0xFF88D29B).withOpacity(0.15),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Jelajahi Fitur',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
      
      // Kanan (Ilustrasi Interaktif)
      FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideImageAnimation,
          child: SizedBox(
            width: isDesktop ? 450 : double.infinity,
            height: isMobile ? 280 : 350,
            child: Image.asset(
              'assets/images/landing_illustration.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      )
    ];

    return isDesktop 
      ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: content) 
      : Column(children: content);
  }

  Widget _buildFeaturesRow(BuildContext context, bool isMobile) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideCardsAnimation,
        child: Wrap(
          spacing: 20,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            _buildFeatureCard(
              isMobile: isMobile,
              icon: Icons.payments_outlined,
              title: 'Kelola\nIuran',
              subtitle: 'Catat pembayaran warga dengan cepat & akurat',
            ),
            _buildFeatureCard(
              isMobile: isMobile,
              icon: Icons.bar_chart_rounded,
              title: 'Laporan\nTransparan',
              subtitle: 'Pantau rekap arus kas secara real-time',
            ),
            _buildFeatureCard(
              isMobile: isMobile,
              icon: Icons.verified_user_outlined,
              title: 'Validasi\nWarga',
              subtitle: 'Fitur persetujuan kolektif demi integritas data',
            ),
            _buildFeatureCard(
              isMobile: isMobile,
              icon: Icons.notifications_active_outlined,
              title: 'Notifikasi\nOtomatis',
              subtitle: 'Pengingat iuran bulanan dan pembaruan sistem',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required bool isMobile,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: isMobile ? double.infinity : 260,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 15 : 20, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03), // Sedikit fill transparan agar card lebih menyala
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF1A6B32), size: 28),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
