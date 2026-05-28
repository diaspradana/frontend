import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config.dart';

class LaporanKeuanganPage extends StatefulWidget {
  const LaporanKeuanganPage({super.key});

  @override
  State<LaporanKeuanganPage> createState() => _LaporanKeuanganPageState();
}

class _LaporanKeuanganPageState extends State<LaporanKeuanganPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _iuranList = [];
  List<dynamic> _pengeluaranList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFinancialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFinancialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final iuranRes = await http.get(Uri.parse('${AppConfig.baseUrl}/api/admin/iuran')).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Request timeout'),
      );
      final pengeluaranRes = await http.get(Uri.parse('${AppConfig.baseUrl}/api/admin/pengeluaran')).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Request timeout'),
      );

      if (!mounted) return;

      if (iuranRes.statusCode == 200 && pengeluaranRes.statusCode == 200) {
        setState(() {
          _iuranList = json.decode(iuranRes.body);
          _pengeluaranList = json.decode(pengeluaranRes.body);
          _isLoading = false;
        });
      } else {
        _showError('Gagal memuat data dari server (${iuranRes.statusCode} / ${pengeluaranRes.statusCode})');
      }
    } on TimeoutException {
      _showError('Connection timeout');
    } on SocketException {
      _showError('No internet connection');
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

  Future<void> _deletePengeluaran(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus pengajuan dana ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/api/admin/pengeluaran/$id'),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSuccess('Pengajuan dana berhasil dihapus');
        _fetchFinancialData();
      } else {
        _showError('Gagal menghapus pengajuan dana (${response.statusCode})');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _deleteIuran(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus pemasukan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/api/admin/iuran/$id'),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSuccess('Pemasukan berhasil dihapus');
        _fetchFinancialData();
      } else {
        final body = json.decode(response.body);
        _showError(body['message'] ?? 'Gagal menghapus pemasukan (${response.statusCode})');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showPemasukanDialog({dynamic iuran}) {
    final isEdit = iuran != null;
    final formKey = GlobalKey<FormState>();
    final nominalController = TextEditingController(
      text: isEdit ? _parseDouble(iuran['jumlah']).toStringAsFixed(0) : '',
    );
    final keteranganController = TextEditingController(
      text: isEdit ? iuran['keterangan'] ?? '' : '',
    );

    DateTime selectedDate = isEdit
        ? DateTime.tryParse(iuran['tanggal'] ?? '') ?? DateTime.now()
        : DateTime.now();

    final dateTextController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(selectedDate),
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: Text(
                isEdit ? 'Ubah Pemasukan' : 'Tambah Pemasukan',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nominal Field
                      TextFormField(
                        controller: nominalController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nominal (Rp)',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Nominal wajib diisi';
                          if (double.tryParse(value) == null || double.parse(value) <= 0) {
                            return 'Nominal harus angka positif';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date Selector
                      TextFormField(
                        controller: dateTextController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Tanggal',
                          suffixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = picked;
                              dateTextController.text = DateFormat('yyyy-MM-dd').format(picked);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Keterangan Field
                      TextFormField(
                        controller: keteranganController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Keterangan / Deskripsi',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Keterangan wajib diisi';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6B32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      setState(() => _isLoading = true);

                      final bodyData = json.encode({
                        'id_warga': null,
                        'jumlah': double.parse(nominalController.text),
                        'tanggal': dateTextController.text,
                        'keterangan': keteranganController.text.trim(),
                      });

                      try {
                        http.Response response;
                        if (isEdit) {
                          response = await http.put(
                            Uri.parse('${AppConfig.baseUrl}/api/admin/iuran/${iuran['id']}'),
                            headers: {'Content-Type': 'application/json'},
                            body: bodyData,
                          ).timeout(const Duration(seconds: 15));
                        } else {
                          response = await http.post(
                            Uri.parse('${AppConfig.baseUrl}/api/admin/iuran'),
                            headers: {'Content-Type': 'application/json'},
                            body: bodyData,
                          ).timeout(const Duration(seconds: 15));
                        }

                        if (!mounted) return;

                        if (response.statusCode == 200 || response.statusCode == 201) {
                          _showSuccess(isEdit ? 'Pemasukan berhasil diperbarui' : 'Pemasukan berhasil ditambahkan');
                          _fetchFinancialData();
                        } else {
                          final body = json.decode(response.body);
                          _showError(body['message'] ?? 'Gagal menyimpan data (${response.statusCode})');
                          setState(() => _isLoading = false);
                        }
                      } catch (e) {
                        _showError('Error: $e');
                      }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFormDialog({dynamic pengeluaran}) {
    final isEdit = pengeluaran != null;
    final formKey = GlobalKey<FormState>();
    final nominalController = TextEditingController(
      text: isEdit ? _parseDouble(pengeluaran['jumlah']).toStringAsFixed(0) : '',
    );
    final keteranganController = TextEditingController(
      text: isEdit ? pengeluaran['keterangan'] ?? '' : '',
    );
    
    DateTime selectedDate = isEdit 
        ? DateTime.tryParse(pengeluaran['tanggal']) ?? DateTime.now() 
        : DateTime.now();

    final dateTextController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(selectedDate),
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: Text(
                isEdit ? 'Ubah Pengajuan Dana' : 'Ajukan Dana Baru',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nominal Field
                      TextFormField(
                        controller: nominalController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nominal (Rp)',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nominal wajib diisi';
                          }
                          if (double.tryParse(value) == null || double.parse(value) <= 0) {
                            return 'Nominal harus angka positif';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Date Selector Field
                      TextFormField(
                        controller: dateTextController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Tanggal',
                          suffixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = picked;
                              dateTextController.text = DateFormat('yyyy-MM-dd').format(picked);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Keterangan Field
                      TextFormField(
                        controller: keteranganController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Keterangan / Deskripsi',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Keterangan wajib diisi';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6B32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      setState(() => _isLoading = true);

                      final bodyData = json.encode({
                        'jumlah': double.parse(nominalController.text),
                        'tanggal': dateTextController.text,
                        'keterangan': keteranganController.text.trim(),
                      });

                      try {
                        http.Response response;
                        if (isEdit) {
                          response = await http.put(
                            Uri.parse('${AppConfig.baseUrl}/api/admin/pengeluaran/${pengeluaran['id']}'),
                            headers: {'Content-Type': 'application/json'},
                            body: bodyData,
                          ).timeout(const Duration(seconds: 15));
                        } else {
                          response = await http.post(
                            Uri.parse('${AppConfig.baseUrl}/api/admin/pengeluaran'),
                            headers: {'Content-Type': 'application/json'},
                            body: bodyData,
                          ).timeout(const Duration(seconds: 15));
                        }

                        if (!mounted) return;

                        if (response.statusCode == 200 || response.statusCode == 201) {
                          _showSuccess(isEdit ? 'Pengajuan dana diperbarui' : 'Pengajuan dana berhasil dikirim');
                          _fetchFinancialData();
                        } else {
                          _showError('Gagal menyimpan data (${response.statusCode})');
                        }
                      } catch (e) {
                        _showError('Error: $e');
                      }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1A6B32)));
    }

    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);

    // Calculate Summary Stats
    double totalPemasukan = 0;
    double totalPengeluaran = 0;

    for (var i in _iuranList) {
      totalPemasukan += _parseDouble(i['jumlah']);
    }

    for (var p in _pengeluaranList) {
      if (p['status'] == 'disetujui') {
        totalPengeluaran += _parseDouble(p['jumlah']);
      }
    }

    double saldoKas = totalPemasukan - totalPengeluaran;

    // Filters based on query
    final filteredIuran = _iuranList.where((i) {
      final query = _searchQuery.toLowerCase();
      final nama = (i['nama'] ?? '').toString().toLowerCase();
      final nik = (i['nik'] ?? '').toString().toLowerCase();
      final keterangan = (i['keterangan'] ?? '').toString().toLowerCase();
      return nama.contains(query) || nik.contains(query) || keterangan.contains(query);
    }).toList();

    final filteredPengeluaran = _pengeluaranList.where((p) {
      final query = _searchQuery.toLowerCase();
      final keterangan = (p['keterangan'] ?? '').toString().toLowerCase();
      final jumlahStr = _parseDouble(p['jumlah']).toStringAsFixed(0);
      return keterangan.contains(query) || jumlahStr.contains(query);
    }).toList();

    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: RefreshIndicator(
        color: const Color(0xFF1A6B32),
        onRefresh: _fetchFinancialData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Laporan Keuangan',
                style: GoogleFonts.almendra(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0C2A15),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Transparansi total pemasukan iuran dan pengeluaran kas warga.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // Summary Cards
              if (isMobile)
                Column(
                  children: [
                    Row(
                      children: [
                        _buildSummaryCard('Pemasukan', currencyFormat.format(totalPemasukan), Icons.arrow_downward, Colors.white, const Color(0xFF2CB5B3)),
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
                    _buildSummaryCard('Total Pemasukan (Iuran)', currencyFormat.format(totalPemasukan), Icons.arrow_downward, Colors.white, const Color(0xFF2CB5B3)),
                    const SizedBox(width: 16),
                    _buildSummaryCard('Total Pengeluaran Kas', currencyFormat.format(totalPengeluaran), Icons.arrow_upward, Colors.white, const Color(0xFFF96D6D)),
                    const SizedBox(width: 16),
                    _buildSummaryCard('Saldo Kas Saat Ini', currencyFormat.format(saldoKas), Icons.account_balance, Colors.white, const Color(0xFF9B51E0)),
                  ],
                ),

              const SizedBox(height: 30),

              // Controls Bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Cari laporan keuangan...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2CB5B3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showPemasukanDialog(),
                    icon: const Icon(Icons.add_card),
                    label: const Text('Tambah Pemasukan'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A6B32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showFormDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajukan Dana'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // TabBar and TabView
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF1A6B32),
                      labelColor: const Color(0xFF1A6B32),
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(text: 'Pemasukan'),
                        Tab(text: 'Pengajuan Dana'),
                      ],
                    ),
                    SizedBox(
                      height: 500,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Pemasukan
                          _buildIuranTable(filteredIuran, currencyFormat),
                          // Tab 2: Pengeluaran
                          _buildPengeluaranTable(filteredPengeluaran, currencyFormat),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIuranTable(List<dynamic> items, NumberFormat currencyFormat) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Tidak ada data pemasukan ditemukan.'),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 24,
            headingRowColor: WidgetStateProperty.all(const Color(0xFF2CB5B3).withOpacity(0.1)),
            columns: const [
              DataColumn(label: Text('Tipe', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Nama Warga', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('NIK', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Keterangan', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: items.map<DataRow>((item) {
              final id = item['id'] is int ? item['id'] : int.tryParse(item['id'].toString()) ?? 0;
              final isSystemEntry = (item['keterangan']?.toString() ?? '').contains('Iuran Berkala Bulan');
              final isUmum = item['id_warga'] == null;

              return DataRow(
                cells: [
                  // Tipe badge
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUmum
                            ? const Color(0xFF2CB5B3).withOpacity(0.12)
                            : const Color(0xFF1A6B32).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isUmum ? 'Umum' : 'Iuran Warga',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isUmum ? const Color(0xFF2CB5B3) : const Color(0xFF1A6B32),
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(item['nama']?.toString() ?? '-')),
                  DataCell(Text(item['nik']?.toString() ?? '-')),
                  DataCell(Text(_formatTanggal(item['tanggal']))),
                  DataCell(Text(
                    currencyFormat.format(_parseDouble(item['jumlah'])),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  )),
                  DataCell(SizedBox(
                    width: 160,
                    child: Text(
                      item['keterangan']?.toString() ?? '-',
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                  // Aksi
                  DataCell(
                    isSystemEntry
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.lock, color: Colors.grey, size: 16),
                              SizedBox(width: 4),
                              Text('Otomatis', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                tooltip: 'Edit',
                                onPressed: () => _showPemasukanDialog(iuran: item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                tooltip: 'Hapus',
                                onPressed: () => _deleteIuran(id),
                              ),
                            ],
                          ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
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

  Widget _buildPengeluaranTable(List<dynamic> items, NumberFormat currencyFormat) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.money_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Tidak ada data pengajuan dana ditemukan.'),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 25,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF96D6D).withOpacity(0.1)),
            columns: const [
              DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Keterangan', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: items.map<DataRow>((item) {
              final id = item['id'] is int ? item['id'] : int.tryParse(item['id'].toString()) ?? 0;
              final isApproved = item['status'] == 'disetujui';
              
              return DataRow(
                cells: [
                  DataCell(Text(_formatTanggal(item['tanggal']))),
                  DataCell(Text(
                    currencyFormat.format(_parseDouble(item['jumlah'])),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                  )),
                  DataCell(Text(item['keterangan']?.toString() ?? '-')),
                  DataCell(_buildStatusChip(item['status'])),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isApproved) ...[
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                            tooltip: 'Edit',
                            onPressed: () => _showFormDialog(pengeluaran: item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                            tooltip: 'Delete',
                            onPressed: () => _deletePengeluaran(id),
                          ),
                        ] else ...[
                          const Icon(Icons.lock, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          const Text('Terkunci', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ]
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
