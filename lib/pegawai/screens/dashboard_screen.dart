import 'package:flutter/material.dart';
import 'package:absensi/pegawai/screens/dashboard/history_screen.dart';
import 'package:absensi/pegawai/screens/dashboard/home_screen.dart';
import 'package:absensi/pegawai/screens/dashboard/over_time_screen.dart';
import 'package:absensi/pegawai/screens/dashboard/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; // Indeks untuk item navigasi yang aktif

  // Daftar halaman yang akan ditampilkan sesuai dengan item navigasi
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    OverTimeScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body akan menampilkan halaman yang dipilih dari _widgetOptions
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_time),
            label: 'Over Time',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo, // Warna item yang aktif
        unselectedItemColor: Colors.grey, // Warna item yang tidak aktif
        showUnselectedLabels: true, // Selalu tampilkan label
        onTap: _onItemTapped,
      ),
    );
  }
}