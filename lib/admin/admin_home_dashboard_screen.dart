import 'package:flutter/material.dart';
import 'package:absensi/services/api_service.dart';

class AdminHomeDashboardScreen extends StatefulWidget {
  const AdminHomeDashboardScreen({super.key});

  @override
  State<AdminHomeDashboardScreen> createState() => _AdminHomeDashboardScreenState();
}

class _AdminHomeDashboardScreenState extends State<AdminHomeDashboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();
    _dashboardData = _apiService.getAdminDashboardSummary();
  }

  void _refreshData() {
    setState(() {
      _dashboardData = _apiService.getAdminDashboardSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat data: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Tidak ada data.'));
          }

          final data = snapshot.data!;
          final List attendanceCounts = data['attendance_counts'] ?? [];
          final List todayChecklists = data['today_checklists'] ?? [];

          return RefreshIndicator(
            onRefresh: () async => _refreshData(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildTotalAttendanceCard(attendanceCounts),
                const SizedBox(height: 24),
                _buildTodayChecklistCard(todayChecklists),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalAttendanceCard(List counts) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Presensi per Pegawai', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (counts.isEmpty)
              const Text('Belum ada data presensi.'),
            if (counts.isNotEmpty)
              DataTable(
                columns: const [
                  DataColumn(label: Text('Nama')),
                  DataColumn(label: Text('Total Hadir'), numeric: true),
                ],
                rows: counts.map((item) {
                  return DataRow(cells: [
                    DataCell(Text(item['name'] ?? 'N/A')),
                    DataCell(Text(item['total_attendance']?.toString() ?? '0')),
                  ]);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayChecklistCard(List checklists) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Checklist Checkout Hari Ini', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (checklists.isEmpty)
              const Text('Belum ada pegawai yang melakukan checkout hari ini.'),
            if (checklists.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: checklists.length,
                itemBuilder: (context, index) {
                  final item = checklists[index];
                  return ListTile(
                    title: Text(item['name'] ?? 'N/A'),
                    subtitle: Text(item['checkout_checklist'] ?? 'Tidak ada catatan.'),
                    trailing: Text(item['time_out'] ?? ''),
                  );
                },
                separatorBuilder: (context, index) => const Divider(),
              ),
          ],
        ),
      ),
    );
  }
}
