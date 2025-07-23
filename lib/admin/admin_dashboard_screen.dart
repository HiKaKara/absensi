import 'package:flutter/material.dart';
// Import halaman-halaman admin lainnya di sini

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  // Daftar halaman untuk admin
  static const List<Widget> _adminPages = <Widget>[
    Text('Halaman Dashboard Admin'), // Ganti dengan widget dashboard admin
    Text('Halaman History Presensi Admin'), // Ganti dengan widget history admin
    Text('Halaman Data Pegawai'), // Ganti dengan widget data pegawai
    Text('Halaman Profil Admin'), // Ganti dengan widget profil admin
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
      ),
    );
  }
}