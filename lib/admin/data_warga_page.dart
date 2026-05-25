import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../config.dart';

class DataWargaPage extends StatefulWidget {
  const DataWargaPage({super.key});

  @override
  State<DataWargaPage> createState() => _DataWargaPageState();
}

class _DataWargaPageState extends State<DataWargaPage> {
  List<dynamic> _wargaList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchWargaData();
  }

  Future<void> _fetchWargaData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}/api/admin/warga'));
      if (response.statusCode == 200) {
        setState(() {
          _wargaList = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        _showError('Gagal mengambil data warga');
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

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  Future<void> _deleteWarga(String nik) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text('Yakin ingin menghapus data warga ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final response = await http.delete(Uri.parse('${AppConfig.baseUrl}/api/admin/warga/$nik'));
        if (response.statusCode == 200) {
          _showSuccess('Data berhasil dihapus');
          _fetchWargaData();
        } else {
          _showError('Gagal menghapus data');
        }
      } catch (e) {
        _showError('Gagal terhubung ke server');
      }
    }
  }

  void _showFormDialog({Map<String, dynamic>? warga}) {
    final isEdit = warga != null;
    final primaryKey = isEdit ? warga['nik']?.toString() : '';
    
    final nameController = TextEditingController(text: isEdit ? warga['nama'] : '');
    final nikController = TextEditingController(text: isEdit ? warga['nik'] : '');
    final addrController = TextEditingController(text: isEdit ? warga['alamat'] : '');
    final phoneController = TextEditingController(text: isEdit ? warga['no_hp'] : '');
    final usernameController = TextEditingController(text: isEdit ? warga['username'] : '');
    final passwordController = TextEditingController(); // Don't show existing password

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Data Warga' : 'Tambah Warga Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
                TextField(controller: nikController, decoration: const InputDecoration(labelText: 'NIK'), keyboardType: TextInputType.number),
                TextField(controller: addrController, decoration: const InputDecoration(labelText: 'Alamat')),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'No HP'), keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                const Divider(),
                const Text('Data Login User', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
                TextField(controller: passwordController, decoration: InputDecoration(labelText: isEdit ? 'Password Baru (opsional)' : 'Password'), obscureText: true),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                setState(() => _isLoading = true);

                final bodyData = {
                  'nama': nameController.text,
                  'nik': nikController.text,
                  'alamat': addrController.text,
                  'no_hp': phoneController.text,
                };

                if (usernameController.text.isNotEmpty) {
                  bodyData['username'] = usernameController.text;
                }
                if (passwordController.text.isNotEmpty) {
                  bodyData['password'] = passwordController.text;
                }

                final body = json.encode(bodyData);

                try {
                  http.Response response;
                  if (isEdit) {
                    response = await http.put(
                      Uri.parse('${AppConfig.baseUrl}/api/admin/warga/$primaryKey'),
                      headers: {'Content-Type': 'application/json'},
                      body: body,
                    );
                  } else {
                    response = await http.post(
                      Uri.parse('${AppConfig.baseUrl}/api/admin/warga'),
                      headers: {'Content-Type': 'application/json'},
                      body: body,
                    );
                  }

                  if (response.statusCode == 200 || response.statusCode == 201) {
                    _showSuccess(isEdit ? 'Data diperbarui' : 'Warga ditambahkan');
                    _fetchWargaData();
                  } else {
                    _showError('Gagal menyimpan data');
                  }
                } catch (e) {
                  _showError('Error sambungan ke server');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A6B32)),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDetailDialog(Map<String, dynamic> warga) {
    bool obscurePassword = true;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Detail Data Warga'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailRow('Nama Lengkap', warga['nama']),
                    _buildDetailRow('NIK', warga['nik']),
                    _buildDetailRow('Alamat', warga['alamat']),
                    _buildDetailRow('No HP', warga['no_hp']),
                    const Divider(height: 30),
                    const Text('Data Login User', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildDetailRow('Username', warga['username'] ?? 'Belum ada'),
                    if (warga['username'] != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 120,
                              child: Text(
                                'Password',
                                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                              ),
                            ),
                            const Text(': ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      warga['password_plain'] != null
                                          ? (obscurePassword ? '••••••••' : warga['password_plain'])
                                          : '(Tidak tersimpan/Terbaca)',
                                      style: const TextStyle(color: Colors.black87),
                                    ),
                                  ),
                                  if (warga['password_plain'] != null)
                                    IconButton(
                                      icon: Icon(
                                        obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setStateDialog(() {
                                          obscurePassword = !obscurePassword;
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
          const Text(': ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? '-', style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1A6B32)));
    }

    // We use a Column inside a scroll view on the page itself.
    // However, the table also needs an inner horizontal scroll.
    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return isMobile 
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Warga',
                        style: GoogleFonts.almendra(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF0C2A15)),
                      ),
                      const SizedBox(height: 8),
                      Text('Kelola informasi warga secara lengkap.', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showFormDialog(),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Tambah Warga', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2CB5B3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data Warga',
                              style: GoogleFonts.almendra(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF0C2A15)),
                            ),
                            const SizedBox(height: 8),
                            Text('Kelola informasi warga secara lengkap.', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showFormDialog(),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Tambah Warga', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2CB5B3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      )
                    ],
                  );
            },
          ),
          const SizedBox(height: 30),

          // Search Field Placeholder
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
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
          ),
          const SizedBox(height: 30),

          // Warga List / Table
          Builder(
            builder: (context) {
              final filteredWargaList = _wargaList.where((warga) {
                final nama = warga['nama']?.toString().toLowerCase() ?? '';
                final nik = warga['nik']?.toString().toLowerCase() ?? '';
                final query = _searchQuery.toLowerCase();
                return nama.contains(query) || nik.contains(query);
              }).toList();

              if (_wargaList.isEmpty) {
                return const Center(child: Text('Belum ada data warga terdaftar.', style: TextStyle(fontSize: 16)));
              } else if (filteredWargaList.isEmpty) {
                return const Center(child: Text('Data warga tidak ditemukan.', style: TextStyle(fontSize: 16)));
              }

              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  // Horizontal scrolling wrapper for smaller screens like HP
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: DataTable(
                      columnSpacing: 30, // Give some breathing room
                      headingRowColor: WidgetStateProperty.all(const Color(0xFF2CB5B3).withOpacity(0.1)),
                      dataRowColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                        if (states.contains(WidgetState.hovered)) return Colors.grey.shade100;
                        return Colors.white;
                      }),
                      columns: const [
                        DataColumn(label: Text('NIK', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Alamat', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('No HP', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: filteredWargaList.map<DataRow>((warga) {
                        return DataRow(
                          cells: [
                            DataCell(Text(warga['nik']?.toString() ?? '-')),
                            DataCell(Text(warga['nama'] ?? '-')),
                            DataCell(Text(warga['alamat'] ?? '-')),
                            DataCell(Text(warga['no_hp'] ?? '-')),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.info_outline, color: Colors.green),
                                  onPressed: () => _showDetailDialog(warga),
                                  tooltip: 'Detail Data',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                  onPressed: () => _showFormDialog(warga: warga),
                                  tooltip: 'Edit Data',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _deleteWarga(warga['nik'].toString()),
                                  tooltip: 'Hapus Data',
                                ),
                              ],
                            )),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
