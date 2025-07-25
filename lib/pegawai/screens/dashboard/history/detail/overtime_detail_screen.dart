import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class OvertimeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> overtimeData;

  const OvertimeDetailScreen({super.key, required this.overtimeData});

  String _formatDate(String date) {
    try {
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.parse(date));
    } catch (e) {
      return date;
    }
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return 'Belum Absen';
    try {
      return DateFormat('HH:mm:ss', 'id_ID').format(DateFormat('HH:mm:ss').parse(time));
    } catch (e) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    const String imageUrlBase = 'http://192.168.1.5:8080/uploads/overtime_evidence/';
    final String photoUrl = imageUrlBase + (overtimeData['evidence_photo'] ?? '');

    final LatLng overtimeLocation = LatLng(
      double.tryParse(overtimeData['latitude']?.toString() ?? '0') ?? 0,
      double.tryParse(overtimeData['longitude']?.toString() ?? '0') ?? 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Lembur'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailCard(
              title: 'Informasi Presensi',
              icon: Icons.info_outline,
              children: [
                _buildInfoRow('Tanggal', _formatDate(overtimeData['attendance_date'])),
                _buildInfoRow('Shift', overtimeData['shift'] ?? '-'),
                _buildInfoRow('Tipe', overtimeData['work_location_type'] ?? '-'),
                _buildInfoRow('Jam Masuk', _formatTime(overtimeData['time_in'])),
                _buildInfoRow('Jam Pulang', _formatTime(overtimeData['time_out'])),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              title: 'Foto Presensi',
              icon: Icons.photo_camera,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPhotoViewer('Foto', photoUrl)
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              title: 'Lokasi Presensi',
              icon: Icons.location_on_outlined,
              children: [
                Text(overtimeData['address'] ?? 'Alamat tidak tercatat'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: overtimeLocation,
                      zoom: 16,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('attendanceLocation'),
                        position: overtimeLocation,
                      ),
                    },
                    scrollGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget Helper untuk UI ---
  Widget _buildDetailCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.indigo.shade700),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPhotoViewer(String title, String imageUrl) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              // Tampilkan icon jika gambar gagal dimuat
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40));
              },
              // Tampilkan loading indicator saat gambar sedang diunduh
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
      ],
    );
  }
}