import 'package:flutter/material.dart';
import 'package:absensi/admin/admin_home_dashboard_screen.dart'; // Import halaman baru
import 'package:absensi/admin/employee_data_screen.dart';
import 'package:absensi/pegawai/screens/dashboard/profile_screen.dart';
import 'package:absensi/pegawai/screens/dashboard/history_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  // PERBAIKAN: Ganti halaman pertama dengan dashboard baru
  static const List<Widget> _adminPages = <Widget>[
    AdminHomeDashboardScreen(), // <-- Halaman Dashboard
    HistoryScreen(),            // <-- Bisa menggunakan HistoryScreen yang sama
    EmployeeDataScreen(),       // <-- Halaman Data Pegawai
    ProfileScreen(),            // <-- Bisa menggunakan ProfileScreen yang sama
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _adminPages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Pegawai'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Agar label selalu terlihat
      ),
    );
  }
}
