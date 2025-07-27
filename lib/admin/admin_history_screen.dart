import 'package:flutter/material.dart';
import 'package:absensi/admin/history/admin_attendance_screen.dart';
import 'package:absensi/admin/history/admin_overtime_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Riwayat Pegawai'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Presensi', icon: Icon(Icons.calendar_today)),
              Tab(text: 'Lembur', icon: Icon(Icons.access_time_filled)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminAttendanceScreen(),
            AdminOvertimeScreen(),
          ],
        ),
      ),
    );
  }
}
