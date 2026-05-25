import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config.dart';

class PenarikanIuranPage extends StatefulWidget {
  const PenarikanIuranPage({super.key});

  @override
  State<PenarikanIuranPage> createState() => _PenarikanIuranPageState();
}

class _PenarikanIuranPageState extends State<PenarikanIuranPage> {
  List<dynamic> _tagihanList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'semua';

  @override
  void initState() {
    super.initState();
    _fetchTagihanData();
  }

  Future<void> _fetchTagihanData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await http
          .get(Uri.parse('${AppConfig.baseUrl}/api/admin/tagihan'))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      if (!mounted) return;

      if (response.statusCode == 200) {
        try {
          final decodedData = json.decode(response.body);
          if (!mounted) return;

          if (decodedData is List && decodedData.isNotEmpty) {
            setState(() {
              _tagihanList = decodedData;
              _isLoading = false;
            });
          } else if (decodedData is List && decodedData.isEmpty) {
            setState(() {
              _tagihanList = [];
              _isLoading = false;
            });
          } else if (decodedData is Map && decodedData['data'] is List) {
            setState(() {
              _tagihanList = decodedData['data'] ?? [];
              _isLoading = false;
            });
          } else {
            _showError('Format data tidak valid');
          }
        } catch (parseError) {
          if (mounted) {
            _showError('Error parsing data: $parseError');
          }
        }
      } else if (response.statusCode == 401) {
        _showError('Session expired, silakan login kembali');
      } else if (response.statusCode == 500) {
        _showError('Server error, silakan coba lagi nanti');
      } else {
        _showError('Gagal (${response.statusCode})');
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

  Future<void> _bayarTagihan(int id, String nama, String bulan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran'),
        content: Text(
          'Catat pembayaran iuran berkala untuk $nama (Bulan: $bulan)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Konfirmasi',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await http
          .put(Uri.parse('${AppConfig.baseUrl}/api/admin/tagihan/$id/bayar'))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      if (!mounted) return;

      if (response.statusCode == 200) {
        try {
          final resData = json.decode(response.body);
          final denda = _parseDouble(resData['denda']);
          final totalAmount = _parseDouble(resData['totalAmount']);

          final dendaFormat = NumberFormat.currency(
            locale: 'id',
            symbol: 'Rp',
            decimalDigits: 0,
          ).format(denda);
          final totalFormat = NumberFormat.currency(
            locale: 'id',
            symbol: 'Rp',
            decimalDigits: 0,
          ).format(totalAmount);

          _showSuccess(
            'Pembayaran berhasil! Total: $totalFormat (Denda: $dendaFormat)',
          );
          _fetchTagihanData();
        } catch (e) {
          if (mounted) {
            _showSuccess('Pembayaran berhasil!');
            _fetchTagihanData();
          }
        }
      } else {
        _showError('Gagal memproses pembayaran (${response.statusCode})');
      }
    } on TimeoutException {
      _showError('Connection timeout');
    } catch (e) {
      if (mounted) {
        _showError('Error: ${e.toString().split('\n').first}');
      }
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleBadge(IconData icon, String title, String value, double width) {
    return SizedBox(
      width: width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1A6B32)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0C2A15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBulan(String bul) {
    try {
      final parts = bul.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return bul;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF1A6B32)),
            const SizedBox(height: 16),
            const Text('Loading data...'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _fetchTagihanData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_tagihanList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Tidak ada data tagihan'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _fetchTagihanData(),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    // Calculate Summary Stats dengan timeout protection
    double totalTagihan = 0;
    double totalLunas = 0;
    double sisaPiutang = 0;
    double totalDenda = 0;

    try {
      for (var t in _tagihanList) {
        try {
          final amount = _parseDouble(t['jumlah']);
          final denda = _parseDouble(t['denda']);
          final status =
              (t['status'] ?? 'belum_lunas').toString().toLowerCase();

          totalTagihan += amount;
          totalDenda += denda;
          if (status == 'lunas') {
            totalLunas += amount;
          } else {
            sisaPiutang += amount;
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      // If calculation fails, use defaults
      totalTagihan = 0;
      totalLunas = 0;
      sisaPiutang = 0;
      totalDenda = 0;
    }

    final filteredList = _tagihanList.where((t) {
      final nama = t['nama']?.toString().toLowerCase() ?? '';
      final nik = t['nik']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      final matchesQuery = nama.contains(query) || nik.contains(query);
      final status = t['status']?.toString().toLowerCase() ?? 'belum_lunas';

      if (_statusFilter == 'semua') return matchesQuery;
      if (_statusFilter == 'lunas') return matchesQuery && status == 'lunas';
      return matchesQuery && status == 'belum_lunas';
    }).toList();

    // Compliance rate calculation
    final now = DateTime.now();
    final currentMonthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    int totalWargaBulanIni = 0;
    int wargaLunasBulanIni = 0;
    for (var t in _tagihanList) {
      if (t['bulan'] == currentMonthStr) {
        totalWargaBulanIni++;
        if (t['status']?.toString().toLowerCase() == 'lunas') {
          wargaLunasBulanIni++;
        }
      }
    }
    final complianceRate = totalWargaBulanIni > 0
        ? (wargaLunasBulanIni / totalWargaBulanIni) * 100
        : 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width < 600 ? 16.0 : 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Penarikan Iuran',
            style: GoogleFonts.almendra(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0C2A15),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kelola penagihan iuran bulanan berkala dan denda keterlambatan.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Banner Aturan Iuran
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1A6B32).withOpacity(0.05), const Color(0xFF2CB5B3).withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF1A6B32).withOpacity(0.2), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF1A6B32),
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aturan Sistem Iuran Berkala',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0C2A15),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sistem ini otomatis menarik iuran bulanan dari seluruh warga pada setiap tanggal 1 awal bulan.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          _buildRuleBadge(
                            Icons.monetization_on_outlined,
                            'Nominal Iuran',
                            'Rp 50.000 / Bulan',
                            130,
                          ),
                          _buildRuleBadge(
                            Icons.calendar_today_outlined,
                            'Jatuh Tempo',
                            'Setiap Tanggal 3',
                            130,
                          ),
                          _buildRuleBadge(
                            Icons.warning_amber_rounded,
                            'Denda Keterlambatan',
                            'Rp 2.000 / Hari',
                            150,
                          ),
                          _buildRuleBadge(
                            Icons.percent_rounded,
                            'Kepatuhan Bulan Ini',
                            '${complianceRate.toStringAsFixed(1)}%',
                            150,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatCard(
                      'Total Tagihan',
                      currencyFormat.format(totalTagihan),
                      Icons.receipt,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      'Total Lunas',
                      currencyFormat.format(totalLunas),
                      Icons.check_circle,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      'Sisa Piutang',
                      currencyFormat.format(sisaPiutang),
                      Icons.pending,
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      'Total Denda',
                      currencyFormat.format(totalDenda),
                      Icons.warning,
                      Colors.red,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Tagihan',
                      currencyFormat.format(totalTagihan),
                      Icons.receipt,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Total Lunas',
                      currencyFormat.format(totalLunas),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Sisa Piutang',
                      currencyFormat.format(sisaPiutang),
                      Icons.pending,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Total Denda',
                      currencyFormat.format(totalDenda),
                      Icons.warning,
                      Colors.red,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 30),

          // Filters and Search Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              final textField = TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Cari nama atau NIK warga...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              );

              final dropdownFilter = Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _statusFilter,
                    items: const [
                      DropdownMenuItem(
                        value: 'semua',
                        child: Text('Semua Status'),
                      ),
                      DropdownMenuItem(value: 'lunas', child: Text('Lunas')),
                      DropdownMenuItem(
                        value: 'belum_lunas',
                        child: Text('Belum Lunas'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _statusFilter = value);
                      }
                    },
                  ),
                ),
              );

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    textField,
                    const SizedBox(height: 12),
                    dropdownFilter,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 2, child: textField),
                  const SizedBox(width: 16),
                  Expanded(child: dropdownFilter),
                ],
              );
            },
          ),
          const SizedBox(height: 30),

          // Data Table
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: DataTable(
                  columnSpacing: 25,
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFF2CB5B3).withOpacity(0.1),
                  ),
                  dataRowColor: WidgetStateProperty.resolveWith<Color?>((
                    states,
                  ) {
                    if (states.contains(WidgetState.hovered)) {
                      return Colors.grey.shade100;
                    }
                    return Colors.white;
                  }),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'NIK',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Nama Warga',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Bulan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Nominal',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Denda',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Status',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Tanggal Bayar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Aksi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: filteredList.map<DataRow>((t) {
                    try {
                      final amount = _parseDouble(t['jumlah']);
                      final denda = _parseDouble(t['denda']);
                      final id = t['id'] is int
                          ? t['id']
                          : int.tryParse(t['id'].toString()) ?? 0;
                      final nik = t['nik']?.toString() ?? '-';
                      final nama = t['nama']?.toString() ?? '-';
                      final bulan = t['bulan']?.toString() ?? '';
                      final tanggalBayar = t['tanggal_bayar'];
                      final isLunas =
                          (t['status']?.toString().toLowerCase() ??
                              'belum_lunas') ==
                          'lunas';

                      return DataRow(
                        cells: [
                          DataCell(Text(nik)),
                          DataCell(Text(nama)),
                          DataCell(Text(_formatBulan(bulan))),
                          DataCell(Text(currencyFormat.format(amount))),
                          DataCell(
                            Text(
                              denda > 0 ? currencyFormat.format(denda) : '-',
                              style: TextStyle(
                                color: denda > 0 ? Colors.red : Colors.black87,
                                fontWeight: denda > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isLunas
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isLunas
                                      ? Colors.green.shade200
                                      : Colors.red.shade200,
                                ),
                              ),
                              child: Text(
                                isLunas ? 'Lunas' : 'Belum Lunas',
                                style: TextStyle(
                                  color: isLunas
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(_formatTanggal(tanggalBayar))),
                          DataCell(
                            isLunas
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : id > 0
                                ? ElevatedButton.icon(
                                    onPressed: () => _bayarTagihan(
                                      id,
                                      nama,
                                      _formatBulan(bulan),
                                    ),
                                    icon: const Icon(
                                      Icons.payment,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Bayar',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      );
                    } catch (e) {
                      // Return empty row if data is invalid
                      return DataRow(
                        cells: [
                          for (int i = 0; i < 8; i++)
                            const DataCell(Text('Error')),
                        ],
                      );
                    }
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
