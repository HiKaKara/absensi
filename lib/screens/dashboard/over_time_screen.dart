import 'package:flutter/material.dart';

class OverTimeScreen extends StatelessWidget {
  const OverTimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Over Time'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add_alarm),
          label: const Text('Ajukan Lembur'),
          onPressed: () {
            // TODO: Tambahkan logika untuk pengajuan lembur
            print('Tombol Lembur ditekan');
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}