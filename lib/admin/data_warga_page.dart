import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class DataWargaPage extends StatefulWidget {
  const DataWargaPage({super.key});

  @override
  State<DataWargaPage> createState() => _DataWargaPageState();
}

class _DataWargaPageState extends State<DataWargaPage> {
  List<dynamic> _wargaList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWargaData();
  }

  Future<void> _fetchWargaData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/api/admin/warga'));
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

  Future<void> _deleteWarga(String id) async {
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
        final response = await http.delete(Uri.parse('http://10.0.2.2:5000/api/admin/warga/$id'));
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
    final id = isEdit ? warga['id']?.toString() : '';
    
    final nameController = TextEditingController(text: isEdit ? warga['nama'] : '');
    final nikController = TextEditingController(text: isEdit ? warga['nik'] : '');
    final addrController = TextEditingController(text: isEdit ? warga['alamat'] : '');
    final phoneController = TextEditingController(text: isEdit ? warga['no_hp'] : '');

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
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                setState(() => _isLoading = true);

                final body = json.encode({
                  'nama': nameController.text,
                  'nik': nikController.text,
                  'alamat': addrController.text,
                  'no_hp': phoneController.text,
                });

                try {
                  http.Response response;
                  if (isEdit) {
                    response = await http.put(
                      Uri.parse('http://10.0.2.2:5000/api/admin/warga/$id'),
                      headers: {'Content-Type': 'application/json'},
                      body: body,
                    );
                  } else {
                    response = await http.post(
                      Uri.parse('http://10.0.2.2:5000/api/admin/warga'),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1A6B32)));
    }

    // We use a Column inside a scroll view on the page itself.
    // However, the table also needs an inner horizontal scroll.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          ),
          const SizedBox(height: 30),

          // Search Field Placeholder
          TextField(
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
          if (_wargaList.isEmpty)
             const Center(child: Text('Belum ada data warga terdaftar.', style: TextStyle(fontSize: 16)))
          else
            Container(
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
                      DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('NIK', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Alamat', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('No HP', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _wargaList.map<DataRow>((warga) {
                      return DataRow(
                        cells: [
                          DataCell(Text(warga['id']?.toString() ?? '-')),
                          DataCell(Text(warga['nama'] ?? '-')),
                          DataCell(Text(warga['nik'] ?? '-')),
                          DataCell(Text(warga['alamat'] ?? '-')),
                          DataCell(Text(warga['no_hp'] ?? '-')),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                onPressed: () => _showFormDialog(warga: warga),
                                tooltip: 'Edit Data',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _deleteWarga(warga['id'].toString()),
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
            ),
        ],
      ),
    );
  }
}
