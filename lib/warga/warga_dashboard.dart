import 'package:flutter/material.dart';

class WargaDashboard extends StatelessWidget {
  const WargaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warga Dashboard'),
        backgroundColor: const Color(0xFF2CB5B3),
      ),
      body: const Center(
        child: Text(
          'Welcome to Warga Dashboard!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
