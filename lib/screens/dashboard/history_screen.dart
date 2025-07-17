import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absensi/services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchHistory();
  }

  Future<List<dynamic>> _fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) {
      // Melempar error yang bisa ditangkap oleh FutureBuilder
      throw Exception('User ID tidak ditemukan. Silakan login kembali.');
    }
    return _apiService.fetchAttendanceHistory(userId);
  }

  // Helper untuk memformat tanggal menjadi format Indonesia
  String _formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(parsedDate);
    } catch (e) {
      return date; // Kembalikan tanggal asli jika format salah
    }
  }

  // Helper untuk memformat waktu
  String _formatTime(String? time) {
    if (time == null || time.isEmpty) {
      return '-';
    }
    try {
      final DateTime parsedTime = DateFormat('HH:mm:ss').parse(time);
      return DateFormat('HH:mm').format(parsedTime);
    } catch (e) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History Presensi'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Navbar Filter (UI saja untuk saat ini)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(onPressed: () {}, child: const Text('Bulan Ini')),
                ElevatedButton(onPressed: () {}, child: const Text('Pilih Tanggal')),
              ],
            ),
          ),
          const Divider(),
          // Daftar History menggunakan FutureBuilder
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                // Saat data sedang dimuat
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Jika terjadi error
                else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error.toString().replaceAll("Exception: ", "")}'));
                }
                // Jika data berhasil didapat tapi kosong
                else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Tidak ada riwayat presensi.'));
                }

                // Jika data berhasil didapat dan tidak kosong
                final historyList = snapshot.data!;

                return ListView.builder(
                  itemCount: historyList.length,
                  itemBuilder: (context, index) {
                    final history = historyList[index];
                    final status = history['status'] ?? 'N/A';
                    final IconData icon;
                    final Color color;

                    // Menentukan ikon dan warna berdasarkan status
                    switch (status) {
                      case 'Hadir':
                        icon = Icons.check_circle;
                        color = Colors.green;
                        break;
                      case 'Terlambat':
                        icon = Icons.warning;
                        color = Colors.orange;
                        break;
                      default:
                        icon = Icons.cancel;
                        color = Colors.red;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        leading: Icon(Icons.check_circle, color: Colors.green, size: 40),
                        title: Text(
                          _formatDate(history['attendance_date']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Masuk: ${_formatTime(history['time_in'])} - Pulang: ${_formatTime(history['time_out'])}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Navigasi ke halaman detail history jika diperlukan
                        },
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
