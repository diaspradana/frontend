import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import '../login_page.dart';
import 'data_warga_page.dart';
import 'laporan_keuangan_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Data for summary
  int totalWarga = 0;
  double totalIuran = 0.0;
  double totalPengeluaran = 0.0;
  double saldoKas = 0.0;

  // Data for chart
  List<dynamic> iuranChartData = [];
  List<dynamic> pengeluaranChartData = [];

  bool isLoading = true;
  String selectedPeriod = 'monthly'; // weekly, monthly, yearly
  int _selectedIndex = 0; // 0: Dashboard, 1: Warga, 2: Laporan

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => isLoading = true);
    try {
      final summaryRes = await http.get(Uri.parse('http://10.0.2.2:5000/api/admin/dashboard-summary'));
      final chartRes = await http.get(Uri.parse('http://10.0.2.2:5000/api/admin/dashboard-chart-data?period=$selectedPeriod'));

      if (summaryRes.statusCode == 200 && chartRes.statusCode == 200) {
        final summaryData = json.decode(summaryRes.body);
        final chartData = json.decode(chartRes.body);

        setState(() {
          totalWarga = summaryData['totalWarga'] ?? 0;
          totalIuran = double.parse((summaryData['totalIuran'] ?? 0.0).toString());
          totalPengeluaran = double.parse((summaryData['totalPengeluaran'] ?? 0.0).toString());
          saldoKas = double.parse((summaryData['saldoKas'] ?? 0.0).toString());

          iuranChartData = chartData['iuran'] ?? [];
          pengeluaranChartData = chartData['pengeluaran'] ?? [];
          isLoading = false;
        });
      } else {
        _showError('Gagal mengambil data dari server');
      }
    } catch (e) {
      _showError('Tidak dapat terhubung ke server');
    }
  }

  void _showError(String message) {
    if(!mounted) return;
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  Widget _getContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const DataWargaPage();
      case 2:
        return const LaporanKeuanganPage();
      default:
        return _buildDashboardContent();
    }
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
        // If mobile, close drawer automatically
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
          // Logo/Brand
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.admin_panel_settings, color: Color(0xFF1A6B32), size: 32),
              const SizedBox(width: 8),
              Text('RT/RW Admin', style: GoogleFonts.almendra(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0C2A15))),
            ],
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Main Menu', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildSidebarItem(0, Icons.dashboard, 'Dashboard'),
                _buildSidebarItem(1, Icons.people, 'Data Warga'),
                _buildSidebarItem(2, Icons.account_balance_wallet, 'Laporan Keuangan'),
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

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
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
                  Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1A6B32)));
    }

    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome Admin!', style: GoogleFonts.almendra(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF0C2A15))),
                  Text('Sistem Informasi RT/RW', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    _logout();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFF1A6B32),
                  child: Icon(Icons.person, color: Colors.white),
                ),
              )
            ],
          ),
          const SizedBox(height: 30),

          // Summary Cards Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;
              String formatTotal(double val) => currencyFormat.format(val);

              final cards = [
                _buildSummaryCard('Total Warga', '$totalWarga', Icons.group, Colors.white, const Color(0xFFF96D6D)),
                if (isDesktop) const SizedBox(width: 20) else const SizedBox(height: 10),
                _buildSummaryCard('Total Iuran', formatTotal(totalIuran), Icons.arrow_downward, Colors.white, const Color(0xFF2CB5B3)),
                if (isDesktop) const SizedBox(width: 20) else const SizedBox(height: 10),
                _buildSummaryCard('Total Pengeluaran', formatTotal(totalPengeluaran), Icons.arrow_upward, Colors.white, const Color(0xFF1A6B32)),
                if (isDesktop) const SizedBox(width: 20) else const SizedBox(height: 10),
                _buildSummaryCard('Saldo Kas', formatTotal(saldoKas), Icons.account_balance, Colors.white, const Color(0xFF9B51E0)),
              ];

              if (isDesktop) {
                return Row(children: cards);
              } else {
                return Column(children: [
                  Row(children: [cards[0], const SizedBox(width: 10) ,cards[2]]),
                  const SizedBox(height: 10),
                  Row(children: [cards[4], const SizedBox(width: 10) ,cards[6]]),
                ]);
              }
            },
          ),

          const SizedBox(height: 40),

          // Chart Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Statistik Keuangan', style: GoogleFonts.almendra(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0C2A15))),
                    DropdownButton<String>(
                      value: selectedPeriod,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1A6B32)),
                      items: const [
                        DropdownMenuItem(value: 'weekly', child: Text('Mingguan')),
                        DropdownMenuItem(value: 'monthly', child: Text('Bulanan')),
                        DropdownMenuItem(value: 'yearly', child: Text('Tahunan')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => selectedPeriod = val);
                          _fetchDashboardData();
                        }
                      },
                    )
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 300,
                  child: _buildBarChart(),
                ),
                const SizedBox(height: 20),
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 12, height: 12, color: const Color(0xFF2CB5B3)),
                    const SizedBox(width: 8),
                    const Text('Iuran'),
                    const SizedBox(width: 20),
                    Container(width: 12, height: 12, color: const Color(0xFFF96D6D)),
                    const SizedBox(width: 8),
                    const Text('Pengeluaran'),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    // Generate data maps matching label directly
    Map<String, double> mapIuran = {};
    for (var item in iuranChartData) {
      mapIuran[item['label'].toString()] = double.parse(item['total'].toString());
    }

    Map<String, double> mapPengeluaran = {};
    for (var item in pengeluaranChartData) {
      mapPengeluaran[item['label'].toString()] = double.parse(item['total'].toString());
    }

    // Get all unique labels
    Set<dynamic> allLabels = {};
    allLabels.addAll(mapIuran.keys);
    allLabels.addAll(mapPengeluaran.keys);
    List<dynamic> sortedLabels = allLabels.toSet().toList();
    sortedLabels.sort(); // Very basic sort, might need period-specific sorting

    List<BarChartGroupData> barGroups = [];
    double maxValue = 0;

    for (int i = 0; i < sortedLabels.length; i++) {
        String label = sortedLabels[i];
        double iuran = mapIuran[label] ?? 0;
        double pengeluaran = mapPengeluaran[label] ?? 0;

        if (iuran > maxValue) maxValue = iuran;
        if (pengeluaran > maxValue) maxValue = pengeluaran;

        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(toY: iuran, color: const Color(0xFF2CB5B3), width: 12, borderRadius: BorderRadius.circular(2)),
              BarChartRodData(toY: pengeluaran, color: const Color(0xFFF96D6D), width: 12, borderRadius: BorderRadius.circular(2)),
            ],
          )
        );
    }

    // Ensure chart has something to draw even if empty
    if(barGroups.isEmpty) {
        return const Center(child: Text("Tidak ada data untuk periode ini", style: TextStyle(color: Colors.grey)));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue > 0 ? maxValue * 1.2 : 100000,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < sortedLabels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(sortedLabels[value.toInt()], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    );
                  }
                  return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if(value == 0) return const Text('0', style: TextStyle(fontSize: 10));
                return Text('${(value/1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 10, color: Colors.grey));
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue > 0 ? maxValue / 4 : 25000,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        
        if (isDesktop) {
          // Desktop Layout
          return Scaffold(
            backgroundColor: const Color(0xFFF7F7F7),
            body: Row(
              children: [
                _buildSidebar(),
                Expanded(
                  child: _getContent(),
                )
              ],
            ),
          );
        } else {
          // Mobile Layout
          return Scaffold(
            backgroundColor: const Color(0xFFF7F7F7),
            appBar: AppBar(
              backgroundColor: const Color(0xFF1A6B32),
              title: const Text('RT/RW Admin', style: TextStyle(color: Colors.white)),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            drawer: Drawer(child: _buildSidebar()),
            body: _getContent(),
          );
        }
      },
    );
  }
}
