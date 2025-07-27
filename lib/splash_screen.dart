import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absensi/selection_screen.dart';
import 'package:absensi/pegawai/screens/dashboard_screen.dart';
import 'package:absensi/admin/admin_dashboard_screen.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final role = prefs.getString('role');
    final loginTimestamp = prefs.getInt('login_timestamp');

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    if (userId != null && role != null) {
      if (role == 'admin' && loginTimestamp != null) {
        final lastLogin = DateTime.fromMillisecondsSinceEpoch(loginTimestamp);
        final now = DateTime.now();
        // Set timeout ke 30 menit
        if (now.difference(lastLogin).inMinutes > 30) {
          await prefs.clear();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SelectionScreen()));
          return;
        }
      }
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => role == 'admin' ? const AdminDashboardScreen() : const DashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SelectionScreen()));
    }
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
            Text('Memuat...'),
          ],
        ),
      ),
    );
  }
}
