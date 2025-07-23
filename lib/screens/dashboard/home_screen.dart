import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absensi/widgets/choice_card.dart';

// --- IMPORT YANG DIPERBAIKI SESUAI STRUKTUR FOLDER BARU ---
import 'package:absensi/screens/dashboard/wfo/wfo_check_in_screen.dart';
import 'package:absensi/screens/dashboard/wfo/wfo_check_out_screen.dart';
import 'package:absensi/screens/dashboard/wfa/wfa_check_in_screen.dart';
import 'package:absensi/screens/dashboard/wfa/wfa_check_out_screen.dart';
// ---------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _currentTime;
  late Timer _timer;
  String _dashboardTitle = 'Dashboard';
  String _loginType = '';

  @override
  void initState() {
    super.initState();
    _currentTime = _formatDateTime(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
    _loadLoginType();
  }

  Future<void> _loadLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    final loginType = prefs.getString('login_type')?.toUpperCase();

    if (mounted) {
      setState(() {
        if (loginType == 'WFA') {
          _dashboardTitle = 'WFA Dashboard';
          _loginType = 'wfa';
        } else if (loginType == 'WFO') {
          _dashboardTitle = 'WFO Dashboard';
          _loginType = 'wfo';
        } else {
          _dashboardTitle = 'Home';
        }
      });
    }
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    final String formattedDateTime = _formatDateTime(now);
    if (mounted) {
      setState(() {
        _currentTime = formattedDateTime;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('EEEE, dd MMMM yyyy\nHH:mm:ss', 'id_ID').format(dateTime);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_dashboardTitle),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: ChoiceCard(
                    title: 'Check In',
                    imagePath: 'assets/images/welcome.png',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => _loginType == 'wfo'
                              ? const WfoCheckInScreen()
                              : const WfaCheckInScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Flexible(
                  child: ChoiceCard(
                    title: 'Check Out',
                    imagePath: 'assets/images/goodbye.png',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => _loginType == 'wfo'
                              ? const WfoCheckOutScreen()
                              : const WfaCheckOutScreen(),
                        ),
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