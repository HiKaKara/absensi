import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:absensi/services/api_service.dart';
import 'package:absensi/admin/history/detail/admin_attendance_detail.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _apiService.fetchAllAttendanceHistory();
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.parse(date));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada riwayat presensi.'));
          }
          final historyList = snapshot.data!;
          return ListView.builder(
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final history = historyList[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(history['name']?[0] ?? 'N'),
                  ),
                  title: Text(history['name'] ?? 'Tanpa Nama'),
                  subtitle: Text(_formatDate(history['attendance_date'])),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminAttendanceDetail(historyData: history),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}