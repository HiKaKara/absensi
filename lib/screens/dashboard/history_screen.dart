import 'package:flutter/material.dart';
import 'package:absensi/widgets/choice_card.dart'; // Pastikan path ini benar
import 'package:absensi/screens/dashboard/history/attendance_history_screen.dart';
import 'package:absensi/screens/dashboard/history/overtime_history_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChoiceCard(
              title: 'Riwayat Absensi',
              imagePath: 'assets/images/presensi.png', // Sediakan gambar ini
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AttendanceHistoryScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            ChoiceCard(
              title: 'Riwayat Lembur',
              imagePath: 'assets/images/lembur.png', // Sediakan gambar ini
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OvertimeHistoryScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}