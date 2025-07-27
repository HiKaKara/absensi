import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class AdminOvertimeDetail extends StatelessWidget {
  final Map<String, dynamic> overtimeData;

  const AdminOvertimeDetail({super.key, required this.overtimeData});

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.parse(date));
  }

  String _formatTime(String? time) {
    if (time == null) return 'N/A';
    return DateFormat('HH:mm').format(DateFormat('HH:mm:ss').parse(time));
  }

  @override
  Widget build(BuildContext context) {
    const String imageUrlBase = 'http://10.14.72.31:8080/uploads/overtime_evidence/';
    final String evidencePhotoUrl = overtimeData['evidence_photo'] != null ? imageUrlBase + overtimeData['evidence_photo'] : '';

    final LatLng location = LatLng(
      double.tryParse(overtimeData['latitude']?.toString() ?? '0') ?? 0,
      double.tryParse(overtimeData['longitude']?.toString() ?? '0') ?? 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Lembur ${overtimeData['name'] ?? ''}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailCard(
              title: 'Informasi Lembur',
              icon: Icons.info_outline,
              children: [
                _buildInfoRow('Pegawai', overtimeData['name'] ?? '-'),
                _buildInfoRow('Tipe Lembur', overtimeData['overtime_type'] ?? '-'),
                _buildInfoRow('Tanggal Mulai', _formatDate(overtimeData['start_date'])),
                _buildInfoRow('Tanggal Selesai', _formatDate(overtimeData['end_date'])),
                _buildInfoRow('Jam Mulai', _formatTime(overtimeData['start_time'])),
                _buildInfoRow('Jam Selesai', _formatTime(overtimeData['end_time'])),
                _buildInfoRow('Status', overtimeData['status'] ?? 'Menunggu'),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              title: 'Foto Bukti',
              icon: Icons.photo_camera,
              children: [_buildPhotoViewer('Foto Bukti', evidencePhotoUrl)],
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
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: location, zoom: 16),
                    markers: {Marker(markerId: const MarkerId('overtimeLocation'), position: location)},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
                    loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : const Center(child: CircularProgressIndicator()),
                  )
                : const Center(child: Icon(Icons.photo, color: Colors.grey, size: 40)),
          ),
        ),
      ],
    );
  }
}
