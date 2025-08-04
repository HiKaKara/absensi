import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class OvertimeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> overtimeData;

  const OvertimeDetailScreen({super.key, required this.overtimeData});

  // Helper untuk memformat tanggal dari YYYY-MM-DD
  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'Tanggal Tidak Ada';
    try {
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.parse(date));
    } catch (e) {
      return date;
    }
  }

  // Helper untuk memformat waktu dari HH:mm:ss
  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return 'Waktu Tidak Ada';
    try {
      // Parsing waktu dari format 24 jam (HH:mm:ss)
      final parsedTime = DateFormat('HH:mm:ss').parse(time);
      // Format kembali ke format yang diinginkan
      return DateFormat('HH:mm', 'id_ID').format(parsedTime);
    } catch (e) {
      return time;
    }
  }

  // Helper untuk mendapatkan warna status
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // Helper untuk mendapatkan teks status
  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu Persetujuan';
    }
  }


  @override
  Widget build(BuildContext context) {
    // Ganti URL dasar jika diperlukan
    const String imageUrlBase = 'http://10.0.2.2:8080/uploads/overtime_evidence/';
    final String photoUrl = overtimeData['evidence_photo'] != null ? imageUrlBase + overtimeData['evidence_photo'] : '';

    // Ambil koordinat dengan aman
    final LatLng overtimeLocation = LatLng(
      double.tryParse(overtimeData['latitude']?.toString() ?? '0') ?? 0,
      double.tryParse(overtimeData['longitude']?.toString() ?? '0') ?? 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengajuan Lembur'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailCard(
              title: 'Informasi Lembur',
              icon: Icons.info_outline,
              children: [
                // --- PERBAIKAN: Menampilkan data lembur yang benar ---
                _buildInfoRow('Nama Pegawai', overtimeData['name'] ?? '-'),
                _buildInfoRow('Tanggal Mulai', _formatDate(overtimeData['start_date'])),
                _buildInfoRow('Tanggal Selesai', _formatDate(overtimeData['end_date'])),
                _buildInfoRow('Jam Mulai', _formatTime(overtimeData['start_time'])),
                _buildInfoRow('Jam Selesai', _formatTime(overtimeData['end_time'])),
                _buildInfoRow('Tipe Lembur', overtimeData['overtime_type'] ?? '-'),
                _buildInfoRow(
                  'Status', 
                  _getStatusText(overtimeData['status']),
                  valueStyle: TextStyle(color: _getStatusColor(overtimeData['status']), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              title: 'Keterangan',
              icon: Icons.notes,
              children: [
                Text(overtimeData['keterangan'] ?? 'Tidak ada keterangan.', style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              title: 'Bukti Foto',
              icon: Icons.photo_camera,
              children: [
                Center(child: _buildPhotoViewer('Foto Bukti', photoUrl)),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              title: 'Lokasi Lembur',
              icon: Icons.location_on_outlined,
              children: [
                Text(overtimeData['location_address'] ?? 'Alamat tidak tercatat'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: (overtimeLocation.latitude == 0 && overtimeLocation.longitude == 0)
                      ? const Center(child: Text("Data lokasi tidak tersedia."))
                      : GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: overtimeLocation,
                            zoom: 16,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('overtimeLocation'),
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

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: valueStyle ?? const TextStyle(fontWeight: FontWeight.bold)),
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