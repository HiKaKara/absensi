import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absensi/services/api_service.dart';
import 'package:absensi/screens/dashboard/history/detail/overtime_detail_screen.dart'; // Import halaman detail

class OvertimeHistoryScreen extends StatefulWidget {
  const OvertimeHistoryScreen({super.key});

  @override
  State<OvertimeHistoryScreen> createState() => _OvertimeHistoryScreenState();
}

class _OvertimeHistoryScreenState extends State<OvertimeHistoryScreen> {
  final ApiService _apiService = ApiService();
  Future<List<dynamic>>? _historyFuture;
  DateTimeRange? _selectedDateRange;
  String _filterText = 'Bulan Ini';

  @override
  void initState() {
    super.initState();
    _setFilterToThisMonth();
  }

  void _setFilterToThisMonth() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    setState(() {
      _selectedDateRange = DateTimeRange(start: firstDayOfMonth, end: lastDayOfMonth);
      _filterText = 'Bulan Ini: ${DateFormat('MMMM yyyy', 'id_ID').format(now)}';
      _historyFuture = _fetchOvertimeHistory();
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final now = DateTime.now();
    final lastDate = DateTime(now.year, now.month, now.day);
    final initialRange = _selectedDateRange != null && _selectedDateRange!.end.isAfter(lastDate)
        ? DateTimeRange(start: _selectedDateRange!.start, end: lastDate)
        : _selectedDateRange;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
      lastDate: lastDate,
      locale: const Locale('id', 'ID'),
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
        final startDate = DateFormat('dd/MM/yy', 'id_ID').format(picked.start);
        final endDate = DateFormat('dd/MM/yy', 'id_ID').format(picked.end);
        _filterText = 'Rentang: $startDate - $endDate';
        _historyFuture = _fetchOvertimeHistory();
      });
    }
  }

  Future<List<dynamic>> _fetchOvertimeHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) {
      throw Exception('User ID tidak ditemukan.');
    }
    return _apiService.fetchOvertimeHistory(
      userId,
      startDate: _selectedDateRange!.start,
      endDate: _selectedDateRange!.end,
    );
  }

  String _formatDate(String date) {
    try {
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.parse(date));
    } catch (e) {
      return date;
    }
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '-';
    try {
      return DateFormat('HH:mm').format(DateFormat('HH:mm:ss').parse(time));
    } catch (e) {
      return time;
    }
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
      appBar: AppBar(
        title: const Text('Riwayat Lembur'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(_filterText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)
                ),
                Row(
                  children: [
                    ElevatedButton(onPressed: _setFilterToThisMonth, child: const Text('Bulan Ini')),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: () => _selectDateRange(context), child: const Text('Pilih')),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error.toString().replaceAll("Exception: ", "")}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Tidak ada riwayat lembur untuk periode ini.'));
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
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OvertimeDetailScreen(overtimeData: history),
                            ),
                          );
                        },
                        child: ListTile(
                          leading: Icon(statusStyle['icon'], color: statusStyle['color'], size: 40),
                          title: Text(history['overtime_type'] ?? 'Jenis Lembur', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Tanggal: ${_formatDate(history['start_date'])}\nWaktu: ${_formatTime(history['start_time'])} - ${_formatTime(history['end_time'])}'),
                          trailing: Text(status.toUpperCase(), style: TextStyle(color: statusStyle['color'], fontWeight: FontWeight.bold)),
                          isThreeLine: true,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}