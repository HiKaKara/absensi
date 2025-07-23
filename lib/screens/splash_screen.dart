import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absensi/screens/dashboard_screen.dart';
import 'package:absensi/screens/selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Tentukan durasi sesi di sini
    const wfoDuration = Duration(hours: 8);
    const wfaDuration = Duration(hours: 24);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final loginTimestamp = prefs.getInt('login_timestamp');
    final loginType = prefs.getString('login_type');

    // Jika salah satu data sesi tidak ada, anggap belum login
    if (userId == null || loginTimestamp == null || loginType == null) {
      _navigateTo(const SelectionScreen());
      return;
    }

    // Tentukan durasi yang berlaku berdasarkan tipe login
    final allowedDuration = (loginType == 'wfo') ? wfoDuration : wfaDuration;
    
    final loginTime = DateTime.fromMillisecondsSinceEpoch(loginTimestamp);
    final currentTime = DateTime.now();
    final sessionDuration = currentTime.difference(loginTime);

    // Periksa apakah sesi sudah kedaluwarsa
    if (sessionDuration > allowedDuration) {
      // Sesi kedaluwarsa, lakukan logout
      await prefs.clear(); // Hapus semua data sesi
      _navigateTo(const SelectionScreen());
    } else {
      // Sesi masih valid, lanjutkan ke Dashboard
      _navigateTo(const DashboardScreen());
    }
  }

  void _navigateTo(Widget screen) {
    // Menunggu sebentar untuk efek splash screen
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => screen),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Memuat sesi..."),
          ],
        ),
      ),
    );
  }
}