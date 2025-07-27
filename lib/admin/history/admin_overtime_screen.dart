import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:absensi/services/api_service.dart';
import 'package:absensi/admin/history/detail/admin_overtime_detail.dart';

class AdminOvertimeScreen extends StatefulWidget {
  const AdminOvertimeScreen({super.key});

  @override
  State<AdminOvertimeScreen> createState() => _AdminOvertimeScreenState();
}

class _AdminOvertimeScreenState extends State<AdminOvertimeScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _apiService.fetchAllOvertimeHistory();
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(date));
  }

  Map<String, dynamic> _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return {'color': Colors.green, 'icon': Icons.check_circle};
      case 'rejected':
        return {'color': Colors.red, 'icon': Icons.cancel};
      case 'pending':
      default:
        return {'color': Colors.orange, 'icon': Icons.hourglass_top};
    }
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
            return const Center(child: Text('Tidak ada riwayat lembur.'));
          }
          final historyList = snapshot.data!;
          return ListView.builder(
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final history = historyList[index];
               final status = history['status'] ?? 'pending';
              final statusStyle = _getStatusStyle(status);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(statusStyle['icon'], color: statusStyle['color'], size: 40),
                  title: Text(history['name'] ?? 'Tanpa Nama'),
                  subtitle: Text('${history['overtime_type']} - ${_formatDate(history['start_date'])}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminOvertimeDetail(overtimeData: history),
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