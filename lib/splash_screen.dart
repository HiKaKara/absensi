import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absensi/pegawai/screens/dashboard_screen.dart';
import 'package:absensi/admin/admin_dashboard_screen.dart';
import 'package:absensi/selection_screen.dart';

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
    const wfoDuration = Duration(hours: 8);
    const wfaDuration = Duration(hours: 24);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final loginTimestamp = prefs.getInt('login_timestamp');
    final loginType = prefs.getString('login_type');
    final userRole = prefs.getString('user_role');

    if (userId == null || loginTimestamp == null || loginType == null || userRole == null) {
      await prefs.clear();
      _navigateTo(const SelectionScreen());
      return;
    }

    final allowedDuration = (loginType == 'wfo') ? wfoDuration : wfaDuration;
    final loginTime = DateTime.fromMillisecondsSinceEpoch(loginTimestamp);
    final sessionDuration = DateTime.now().difference(loginTime);

    if (sessionDuration > allowedDuration) {
      await prefs.clear();
      _navigateTo(const SelectionScreen());
    } else {
      // Arahkan ke dashboard yang benar
      if (userRole.toLowerCase() == 'admin') {
        _navigateTo(const AdminDashboardScreen());
      } else {
        _navigateTo(const DashboardScreen());
      }
    }
  }

  void _navigateTo(Widget screen) {
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
