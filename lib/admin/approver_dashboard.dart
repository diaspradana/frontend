import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../login_page.dart';

class ApproverDashboard extends StatefulWidget {
  const ApproverDashboard({super.key});

  @override
  State<ApproverDashboard> createState() => _ApproverDashboardState();
}

class _ApproverDashboardState extends State<ApproverDashboard> {
  // User credentials
  String _username = '';
  String _userRole = ''; // 'rt' or 'rw'

  // Data for summary
  double totalIuran = 0.0;
  double totalPengeluaran = 0.0;
  double saldoKas = 0.0;

  // Lists
  List<dynamic> _pendingList = [];
  List<dynamic> _historyList = [];

  bool _isLoading = true;
  int _selectedIndex = 0; // 0: Dashboard, 1: Riwayat Persetujuan
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo().then((_) {
      _fetchDashboardData();
    });
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Pengurus';
      _userRole = prefs.getString('user_role') ?? 'rt';
    });
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. Fetch Finance Summary
      final summaryRes = await http.get(Uri.parse('${AppConfig.baseUrl}/api/admin/dashboard-summary')).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Request timeout'),
      );

      // 2. Fetch Pending Approvals based on role
      final pendingRes = await http.get(Uri.parse('${AppConfig.baseUrl}/api/admin/pengajuan-dana/pending?role=$_userRole')).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Request timeout'),
      );

      // 3. Fetch All History
      final historyRes = await http.get(Uri.parse('${AppConfig.baseUrl}/api/admin/pengeluaran')).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Request timeout'),
      );

      if (!mounted) return;

      if (summaryRes.statusCode == 200 && pendingRes.statusCode == 200 && historyRes.statusCode == 200) {
        final summaryData = json.decode(summaryRes.body);
        setState(() {
          totalIuran = double.parse((summaryData['totalIuran'] ?? 0.0).toString());
          totalPengeluaran = double.parse((summaryData['totalPengeluaran'] ?? 0.0).toString());
          saldoKas = double.parse((summaryData['saldoKas'] ?? 0.0).toString());

          _pendingList = json.decode(pendingRes.body);
          _historyList = json.decode(historyRes.body);
          _isLoading = false;
        });
      } else {
        _showError('Gagal memuat data dari server');
      }
    } on TimeoutException {
      _showError('Koneksi timeout');
    } on SocketException {
      _showError('Tidak ada koneksi internet');
    } catch (e) {
      if (mounted) {
        _showError('Error: ${e.toString().split('\n').first}');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
    await prefs.remove('username');
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  Future<void> _processApproval(int id, bool approve) async {
    setState(() => _isLoading = true);
    final endpoint = approve ? 'approve' : 'reject';
    final actionName = approve ? 'disetujui' : 'ditolak';

    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/api/admin/pengajuan-dana/$id/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'role': _userRole}),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSuccess('Pengajuan dana berhasil $actionName');
        _fetchDashboardData();
      } else {
        final data = json.decode(response.body);
        _showError(data['message'] ?? 'Gagal memproses persetujuan');
      }
    } catch (e) {
      _showError('Error: $e');
    }
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

  String _formatTanggal(String? tgl) {
    if (tgl == null) return '-';
    try {
      final date = DateTime.parse(tgl);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return tgl;
    }
  }

  String get _roleTitle {
    return _userRole == 'rt' ? 'Ketua RT' : 'Ketua RW';
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF2CB5B3) : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF1A6B32) : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: isSelected ? const Color(0xFF2CB5B3).withOpacity(0.1) : Colors.transparent,
      onTap: () {
        setState(() => _selectedIndex = index);
        if (MediaQuery.of(context).size.width < 800) {
          Navigator.pop(context);
        }
      },
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, color: const Color(0xFF1A6B32), size: 32),
              const SizedBox(width: 8),
              Text(
                _roleTitle,
                style: GoogleFonts.almendra(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold, 
                  color: const Color(0xFF0C2A15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Menu Utama', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildSidebarItem(0, Icons.dashboard_outlined, 'Persetujuan Dana'),
                _buildSidebarItem(1, Icons.history, 'Riwayat Pengajuan'),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onTap: _logout,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'menunggu_rt':
        bgColor = Colors.amber.shade50;
        textColor = Colors.amber.shade900;
        label = 'Menunggu RT';
        break;
      case 'menunggu_rw':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade900;
        label = 'Menunggu RW';
        break;
      case 'disetujui':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade900;
        label = 'Disetujui';
        break;
      case 'ditolak_rt':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade900;
        label = 'Ditolak RT';
        break;
      case 'ditolak_rw':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade900;
        label = 'Ditolak RW';
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = 'Menunggu RT';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildPendingApprovalsTab(NumberFormat currencyFormat) {
    if (_pendingList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade200),
              const SizedBox(height: 16),
              const Text(
                'Semua pengajuan telah diproses!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tidak ada pengajuan dana yang tertunda saat ini.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _pendingList.length,
      itemBuilder: (context, index) {
        final item = _pendingList[index];
        final id = item['id'] is int ? item['id'] : int.tryParse(item['id'].toString()) ?? 0;
        final amount = _parseDouble(item['jumlah']);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF1A6B32).withOpacity(0.1),
                          child: const Icon(Icons.monetization_on, color: Color(0xFF1A6B32)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currencyFormat.format(amount),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.redAccent),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Diajukan pada: ${_formatTanggal(item['tanggal'])}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        )
                      ],
                    ),
                    _buildStatusChip(item['status']),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Keterangan Keperluan:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  item['keterangan']?.toString() ?? 'Tanpa keterangan.',
                  style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _processApproval(id, false),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Tolak Pengajuan', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A6B32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _processApproval(id, true),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Setujui Pengajuan', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllHistoryTab(NumberFormat currencyFormat) {
    final filteredHistory = _historyList.where((p) {
      final query = _searchQuery.toLowerCase();
      final ket = (p['keterangan'] ?? '').toString().toLowerCase();
      final tgl = _formatTanggal(p['tanggal']).toLowerCase();
      final statusName = (p['status'] ?? '').toString().toLowerCase();
      return ket.contains(query) || tgl.contains(query) || statusName.contains(query);
    }).toList();

    if (filteredHistory.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: Text('Tidak ada riwayat pengajuan dana ditemukan.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 25,
              headingRowColor: WidgetStateProperty.all(const Color(0xFF1A6B32).withOpacity(0.08)),
              columns: const [
                DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Keterangan', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: filteredHistory.map<DataRow>((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(_formatTanggal(item['tanggal']))),
                    DataCell(Text(
                      currencyFormat.format(_parseDouble(item['jumlah'])),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                    )),
                    DataCell(Text(item['keterangan']?.toString() ?? '-')),
                    DataCell(_buildStatusChip(item['status'])),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1A6B32)));
    }

    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);
    final isMobile = MediaQuery.of(context).size.width < 800;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
                Text(
                  'Selamat Datang, $_roleTitle!',
                  style: GoogleFonts.almendra(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_username - Sistem Persetujuan Bertingkat Pengajuan Dana.',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Financial Summary Cards
          if (isMobile)
            Column(
              children: [
                Row(
                  children: [
                    _buildSummaryCard('Pemasukan', currencyFormat.format(totalIuran), Icons.arrow_downward, Colors.white, const Color(0xFF2CB5B3)),
                    const SizedBox(width: 12),
                    _buildSummaryCard('Pengeluaran', currencyFormat.format(totalPengeluaran), Icons.arrow_upward, Colors.white, const Color(0xFFF96D6D)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildSummaryCard('Saldo Kas', currencyFormat.format(saldoKas), Icons.account_balance, Colors.white, const Color(0xFF9B51E0)),
                  ],
                )
              ],
            )
          else
            Row(
              children: [
                _buildSummaryCard('Total Pemasukan (Iuran)', currencyFormat.format(totalIuran), Icons.arrow_downward, Colors.white, const Color(0xFF2CB5B3)),
                const SizedBox(width: 16),
                _buildSummaryCard('Total Pengeluaran Kas', currencyFormat.format(totalPengeluaran), Icons.arrow_upward, Colors.white, const Color(0xFFF96D6D)),
                const SizedBox(width: 16),
                _buildSummaryCard('Saldo Kas Saat Ini', currencyFormat.format(saldoKas), Icons.account_balance, Colors.white, const Color(0xFF9B51E0)),
              ],
            ),
          const SizedBox(height: 30),

          // Main Interactive Panels
          if (_selectedIndex == 0) ...[
            Text(
              'Persetujuan Tertunda (${_pendingList.length})',
              style: GoogleFonts.almendra(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0C2A15)),
            ),
            const SizedBox(height: 12),
            _buildPendingApprovalsTab(currencyFormat),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Riwayat Pengajuan Dana',
                    style: GoogleFonts.almendra(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0C2A15)),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 250,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari riwayat...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            _buildAllHistoryTab(currencyFormat),
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7F7F7),
            body: Row(
              children: [
                _buildSidebar(),
                Expanded(
                  child: _buildDashboardContent(),
                )
              ],
            ),
          );
        } else {
          return Scaffold(
            backgroundColor: const Color(0xFFF7F7F7),
            appBar: AppBar(
              backgroundColor: const Color(0xFF1A6B32),
              title: Text('$_roleTitle Portal', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            drawer: Drawer(child: _buildSidebar()),
            body: _buildDashboardContent(),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              selectedItemColor: const Color(0xFF1A6B32),
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.white,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.pending_actions),
                  label: 'Persetujuan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'Riwayat',
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
