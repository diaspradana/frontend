import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import '../login_page.dart';

class WargaDashboard extends StatefulWidget {
  const WargaDashboard({super.key});

  @override
  State<WargaDashboard> createState() => _WargaDashboardState();
}

class _WargaDashboardState extends State<WargaDashboard> {
  String _username = '';
  String _namaWarga = '';
  List<dynamic> _tagihanList = [];
  bool _isLoading = true;

  int _currentIndex = 0; // 0: Tagihan Saya, 1: Laporan Keuangan

  // Financial transparency states
  List<dynamic> _iuranList = [];
  List<dynamic> _pengeluaranList = [];
  double _totalPemasukan = 0;
  double _totalPengeluaran = 0;
  double _saldoKas = 0;
  bool _isFinancialLoading = false;
  String _keuanganSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserDataAndFetch();
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    try {
      return double.parse(value.toString());
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> _fetchFinancialData() async {
    setState(() => _isFinancialLoading = true);
    try {
      final summaryRes = await http.get(Uri.parse('${AppConfig.baseUrl}/api/warga/keuangan-summary'));
      final iuranRes = await http.get(Uri.parse('${AppConfig.baseUrl}/api/warga/iuran'));
      final pengeluaranRes = await http.get(Uri.parse('${AppConfig.baseUrl}/api/warga/pengeluaran'));

      if (summaryRes.statusCode == 200 && iuranRes.statusCode == 200 && pengeluaranRes.statusCode == 200) {
        final summaryData = json.decode(summaryRes.body);
        setState(() {
          _totalPemasukan = _parseDouble(summaryData['totalIuran']);
          _totalPengeluaran = _parseDouble(summaryData['totalPengeluaran']);
          _saldoKas = _parseDouble(summaryData['saldoKas']);
          _iuranList = json.decode(iuranRes.body);
          _pengeluaranList = json.decode(pengeluaranRes.body);
          _isFinancialLoading = false;
        });
      } else {
        _showError('Gagal mengambil data laporan keuangan');
      }
    } catch (e) {
      _showError('Tidak dapat terhubung ke server untuk memuat laporan keuangan');
    }
  }

  Future<void> _loadUserDataAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    setState(() {
      _username = username;
    });

    if (username.isNotEmpty) {
      _fetchTagihanData(username);
      _fetchFinancialData();
    } else {
      _showError('Gagal memuat informasi login. Silakan login kembali.');
      _logout();
    }
  }

  Future<void> _fetchTagihanData(String username) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}/api/warga/tagihan?username=$username'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _tagihanList = data;
          if (data.isNotEmpty) {
            _namaWarga = data[0]['nama'] ?? '';
          } else {
            _namaWarga = username;
          }
          _isLoading = false;
        });
      } else {
        _showError('Gagal mengambil data tagihan warga');
      }
    } catch (e) {
      _showError('Tidak dapat terhubung ke server');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
    await prefs.remove('username');
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusAlert(bool hasUnpaid, bool hasOverdue, double overdueDenda) {
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
    
    if (!hasUnpaid) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.green.shade300, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seluruh Tagihan Lunas',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Terima kasih! Kewajiban iuran berkala Anda telah terpenuhi untuk seluruh periode.',
                    style: TextStyle(color: Colors.green.shade800, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (hasOverdue) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.red.shade300, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tagihan Terlambat & Denda Berjalan!',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB71C1C), fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Anda memiliki tagihan iuran berkala yang telah melewati jatuh tempo (tanggal 3). Total denda saat ini: ${currencyFormat.format(overdueDenda)} (akumulasi Rp 2.000/hari).',
                    style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade300, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.blue.shade800, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tagihan Bulan Ini Belum Dibayar',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1), fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Silakan lakukan pembayaran sebelum tanggal 3 untuk menghindari denda keterlambatan.',
                  style: TextStyle(color: Colors.blue.shade800, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2CB5B3)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagihanTabContent() {
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);

    // Calculate Summary Stats
    double totalBelumLunas = 0;
    double totalTerbayar = 0;
    double totalDenda = 0;

    bool hasOverdue = false;
    bool hasUnpaid = false;
    double overdueDenda = 0;

    for (var t in _tagihanList) {
      final amount = double.tryParse(t['jumlah'].toString()) ?? 0;
      final denda = double.tryParse(t['denda'].toString()) ?? 0;
      totalDenda += denda;
      if (t['status'] == 'lunas') {
        totalTerbayar += amount;
      } else {
        totalBelumLunas += amount;
        hasUnpaid = true;
        if (denda > 0) {
          hasOverdue = true;
          overdueDenda += denda;
        } else {
          // Backup due date check (due date: 3rd of billing month)
          try {
            final parts = t['bulan'].split('-');
            final year = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final now = DateTime.now();
            final dueDate = DateTime(year, month, 3);
            if (DateTime(now.year, now.month, now.day).isAfter(dueDate)) {
              hasOverdue = true;
            }
          } catch (_) {}
        }
      }
    }

    String formatBulan(String bul) {
      try {
        final parts = bul.split('-');
        final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        return DateFormat('MMMM yyyy', 'id_ID').format(date);
      } catch (e) {
        return bul;
      }
    }

    String formatTanggal(String? tgl) {
      if (tgl == null) return '-';
      try {
        final date = DateTime.parse(tgl);
        return DateFormat('dd MMM yyyy', 'id_ID').format(date);
      } catch (e) {
        return tgl;
      }
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1A6B32)));
    }

    return RefreshIndicator(
      color: const Color(0xFF1A6B32),
      onRefresh: () => _fetchTagihanData(_username),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0C2A15), Color(0xFF1A6B32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selamat Datang,',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _namaWarga.isNotEmpty ? _namaWarga : _username,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Pantau kewajiban iuran berkala bulanan Anda di bawah ini.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Status Alert Card
            _buildStatusAlert(hasUnpaid, hasOverdue, overdueDenda),
            const SizedBox(height: 24),

            // Stats Cards Row
            Row(
              children: [
                _buildSummaryCard(
                  'Belum Lunas',
                  currencyFormat.format(totalBelumLunas),
                  Icons.pending_actions,
                  Colors.white,
                  const Color(0xFFF96D6D),
                ),
                const SizedBox(width: 12),
                _buildSummaryCard(
                  'Total Terbayar',
                  currencyFormat.format(totalTerbayar),
                  Icons.check_circle_outline,
                  Colors.white,
                  const Color(0xFF2CB5B3),
                ),
                const SizedBox(width: 12),
                _buildSummaryCard(
                  'Total Denda',
                  currencyFormat.format(totalDenda),
                  Icons.warning_amber_rounded,
                  Colors.white,
                  const Color(0xFF9B51E0),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Title
            Text(
              'Tagihan Iuran Berkala',
              style: GoogleFonts.almendra(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0C2A15)),
            ),
            const SizedBox(height: 12),

            // Bills List
            if (_tagihanList.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Belum ada data tagihan terdaftar.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tagihanList.length,
                itemBuilder: (context, index) {
                  final t = _tagihanList[index];
                  final amount = double.tryParse(t['jumlah'].toString()) ?? 0;
                  final denda = double.tryParse(t['denda'].toString()) ?? 0;
                  final isLunas = t['status'] == 'lunas';
                  final bulanStr = formatBulan(t['bulan']);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isLunas ? Colors.green.shade50 : Colors.red.shade50,
                                    child: Icon(
                                      isLunas ? Icons.check : Icons.warning_amber_rounded,
                                      color: isLunas ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bulanStr,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Nominal: ${currencyFormat.format(amount)}',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isLunas ? Colors.green.shade50 : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isLunas ? 'Lunas' : 'Belum Lunas',
                                  style: TextStyle(
                                    color: isLunas ? Colors.green.shade800 : Colors.red.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            ],
                          ),
                          
                          // Fines Info Row
                          if (denda > 0) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.warning, color: Colors.redAccent, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                                      children: [
                                        const TextSpan(text: 'Denda keterlambatan: '),
                                        TextSpan(
                                          text: currencyFormat.format(denda),
                                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                          text: isLunas ? ' (Sudah Dibayar)' : ' (Akumulasi Rp 2.000/hari)',
                                          style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Date Paid / Instructions Info Row
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 4),
                          if (isLunas)
                            Row(
                              children: [
                                const Icon(Icons.event_available, color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Dibayar pada: ${formatTanggal(t['tanggal_bayar'])}',
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange.shade800, size: 16),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Jatuh tempo setiap tanggal 3. Silakan hubungi pengurus RT/RW untuk melakukan pembayaran.',
                                    style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            
            const SizedBox(height: 16),

            // Ketentuan Iuran & Panduan Pembayaran Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, color: Color(0xFF1A6B32)),
                      const SizedBox(width: 10),
                      Text(
                        'Ketentuan Iuran & Pembayaran',
                        style: GoogleFonts.almendra(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0C2A15),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Penarikan Bulanan',
                    'Iuran ditarik otomatis pada tanggal 1 awal bulan sebesar Rp 50.000.',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.alarm_on,
                    'Batas Jatuh Tempo',
                    'Pembayaran iuran paling lambat pada tanggal 3 setiap bulannya.',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.money_off,
                    'Denda Keterlambatan',
                    'Keterlambatan setelah tanggal 3 otomatis dikenakan denda Rp 2.000 / hari.',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.payment,
                    'Cara Melakukan Pembayaran',
                    'Hubungi Pengurus RT/RW (Admin) secara offline untuk menyetorkan iuran. Admin akan mencatat pembayaran Anda di sistem, dan status tagihan di portal ini akan otomatis terupdate menjadi Lunas.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaporanKeuanganTabContent() {
    if (_isFinancialLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1A6B32)));
    }

    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);

    final filteredIuran = _iuranList.where((i) {
      final query = _keuanganSearchQuery.toLowerCase();
      final nama = (i['nama'] ?? '').toString().toLowerCase();
      final nik = (i['nik'] ?? '').toString().toLowerCase();
      final keterangan = (i['keterangan'] ?? '').toString().toLowerCase();
      return nama.contains(query) || nik.contains(query) || keterangan.contains(query);
    }).toList();

    final filteredPengeluaran = _pengeluaranList.where((p) {
      final query = _keuanganSearchQuery.toLowerCase();
      final keterangan = (p['keterangan'] ?? '').toString().toLowerCase();
      final jumlahStr = _parseDouble(p['jumlah']).toStringAsFixed(0);
      return keterangan.contains(query) || jumlahStr.contains(query);
    }).toList();

    String formatTanggal(String? tgl) {
      if (tgl == null) return '-';
      try {
        final date = DateTime.parse(tgl);
        return DateFormat('dd MMM yyyy', 'id_ID').format(date);
      } catch (e) {
        return tgl;
      }
    }

    return RefreshIndicator(
      color: const Color(0xFF1A6B32),
      onRefresh: _fetchFinancialData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Laporan Transparansi Keuangan',
              style: GoogleFonts.almendra(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0C2A15)),
            ),
            const SizedBox(height: 6),
            Text(
              'Laporan kas pemasukan dan pengeluaran secara real-time demi keterbukaan publik.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Summary Cards Row
            Row(
              children: [
                _buildSummaryCard(
                  'Pemasukan (Iuran)',
                  currencyFormat.format(_totalPemasukan),
                  Icons.arrow_downward,
                  Colors.white,
                  const Color(0xFF2CB5B3),
                ),
                const SizedBox(width: 8),
                _buildSummaryCard(
                  'Pengeluaran Kas',
                  currencyFormat.format(_totalPengeluaran),
                  Icons.arrow_upward,
                  Colors.white,
                  const Color(0xFFF96D6D),
                ),
                const SizedBox(width: 8),
                _buildSummaryCard(
                  'Saldo Kas',
                  currencyFormat.format(_saldoKas),
                  Icons.account_balance,
                  Colors.white,
                  const Color(0xFF9B51E0),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Bar
            TextField(
              onChanged: (value) => setState(() => _keuanganSearchQuery = value),
              decoration: InputDecoration(
                hintText: 'Cari riwayat transaksi...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    indicatorColor: const Color(0xFF1A6B32),
                    labelColor: const Color(0xFF1A6B32),
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Pemasukan'),
                      Tab(text: 'Pengeluaran'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      children: [
                        _buildTransparentIuranTable(filteredIuran, currencyFormat, formatTanggal),
                        _buildTransparentPengeluaranTable(filteredPengeluaran, currencyFormat, formatTanggal),
                      ],
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

  Widget _buildTransparentIuranTable(List<dynamic> items, NumberFormat currencyFormat, String Function(String?) formatTanggal) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              const Text('Tidak ada pemasukan iuran terdaftar.', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF2CB5B3).withOpacity(0.08)),
              columns: const [
                DataColumn(label: Text('Nama Warga', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Keterangan', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: items.map<DataRow>((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item['nama']?.toString() ?? '-')),
                    DataCell(Text(formatTanggal(item['tanggal']))),
                    DataCell(Text(
                      currencyFormat.format(_parseDouble(item['jumlah'])),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    )),
                    DataCell(Text(item['keterangan']?.toString() ?? '-')),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransparentPengeluaranTable(List<dynamic> items, NumberFormat currencyFormat, String Function(String?) formatTanggal) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.money_off, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              const Text('Tidak ada pengeluaran kas terdaftar.', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF96D6D).withOpacity(0.08)),
              columns: const [
                DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Keterangan', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: items.map<DataRow>((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(formatTanggal(item['tanggal']))),
                    DataCell(Text(
                      currencyFormat.format(_parseDouble(item['jumlah'])),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                    )),
                    DataCell(Text(item['keterangan']?.toString() ?? '-')),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text(
          _currentIndex == 0 ? 'Portal Warga' : 'Laporan Keuangan',
          style: GoogleFonts.almendra(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A6B32),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _currentIndex == 0 
          ? _buildTagihanTabContent() 
          : _buildLaporanKeuanganTabContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF1A6B32),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Tagihan Saya',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Laporan Keuangan',
          ),
        ],
      ),
    );
  }
}


