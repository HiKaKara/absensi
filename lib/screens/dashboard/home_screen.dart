import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:absensi/widgets/choice_card.dart';
import 'package:absensi/screens/check_in_screen.dart';
import 'package:absensi/screens/check_out_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _currentTime;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Inisialisasi waktu saat ini
    _currentTime = _formatDateTime(DateTime.now());
    // Atur timer untuk update waktu setiap detik
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
  }

  // Fungsi untuk mendapatkan dan memformat waktu
  void _getTime() {
    final DateTime now = DateTime.now();
    final String formattedDateTime = _formatDateTime(now);
    setState(() {
      _currentTime = formattedDateTime;
    });
  }

  // Fungsi untuk memformat tampilan waktu
  String _formatDateTime(DateTime dateTime) {
    // Anda bisa mengubah format sesuai keinginan, misal: 'HH:mm:ss'
    return DateFormat('EEEE, dd MMMM yyyy\nHH:mm:ss', 'id_ID').format(dateTime);
  }

  @override
  void dispose() {
    // Hentikan timer saat widget tidak lagi digunakan untuk mencegah memory leak
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Widget untuk menampilkan waktu realtime
            Text(
              _currentTime,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 40),
            
            // Tombol Check In menggunakan ChoiceCard
            Row(
            mainAxisAlignment: MainAxisAlignment.center, // Pusatkan tombol ke tengah
            children: [
              // Gunakan Flexible agar kartu tidak terlalu besar dan menyebabkan overflow
              Flexible(
                child: ChoiceCard(
                  title: 'Check In',
                  imagePath: 'assets/images/welcome.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CheckInScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 20), // Beri jarak antar tombol
              Flexible(
                child: ChoiceCard(
                  title: 'Check Out',
                  imagePath: 'assets/images/goodbye.png',
                  onTap: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CheckOutScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}