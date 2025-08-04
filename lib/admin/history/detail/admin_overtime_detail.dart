import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:absensi/services/api_service.dart'; // Pastikan path ini benar

class AdminOvertimeDetail extends StatefulWidget {
  final Map<String, dynamic> overtimeData;

  const AdminOvertimeDetail({super.key, required this.overtimeData});

  @override
  State<AdminOvertimeDetail> createState() => _AdminOvertimeDetailState();
}

class _AdminOvertimeDetailState extends State<AdminOvertimeDetail> {
  // State untuk menyimpan data yang bisa berubah
  late Map<String, dynamic> _overtimeData;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Salin data dari widget ke state lokal agar bisa diubah
    _overtimeData = Map.from(widget.overtimeData);
  }

  // --- LOGIKA ---

  /// Fungsi untuk memanggil API dan memperbarui status lembur
  Future<void> _updateStatus(String status) async {
    setState(() => _isLoading = true); // Tampilkan loading
    try {
      final overtimeId = _overtimeData['id'].toString();
      final result = await _apiService.updateOvertimeStatus(overtimeId, status);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Status berhasil diperbarui.'),
            backgroundColor: Colors.green,
          ),
        );
        // Perbarui data lokal agar UI langsung berubah
        setState(() {
          _overtimeData['status'] = status;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false); // Sembunyikan loading
    }
  }

  // --- TAMPILAN (UI) ---

  @override
  Widget build(BuildContext context) {
    const String imageUrlBase = 'http://10.0.2.2:8080/uploads/overtime_evidence/';
    final String evidencePhotoUrl = _overtimeData['evidence_photo'] != null ? imageUrlBase + _overtimeData['evidence_photo'] : '';
    final bool isPending = _overtimeData['status']?.toLowerCase() == 'pending';
    final LatLng location = LatLng(
      double.tryParse(_overtimeData['latitude']?.toString() ?? '0') ?? 0,
      double.tryParse(_overtimeData['longitude']?.toString() ?? '0') ?? 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Lembur ${_overtimeData['name'] ?? ''}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailCard(
              title: 'Informasi Lembur',
              icon: Icons.info_outline,
              children: [
                _buildInfoRow('Pegawai', _overtimeData['name'] ?? '-'),
                _buildInfoRow('Tipe Lembur', _overtimeData['overtime_type'] ?? '-'),
                _buildInfoRow('Tanggal', _formatDate(_overtimeData['start_date'])),
                _buildInfoRow('Waktu', '${_formatTime(_overtimeData['start_time'])} - ${_formatTime(_overtimeData['end_time'])}'),
                _buildInfoRow('Status', _overtimeData['status']?.toUpperCase() ?? 'MENUNGGU'),
              ],
            ),
            const SizedBox(height: 16),
            
            // 👇 CARD BARU UNTUK MENAMPILKAN KETERANGAN 👇
            _buildDetailCard(
              title: 'Keterangan',
              icon: Icons.description_outlined,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    _overtimeData['keterangan'] ?? 'Tidak ada keterangan.',
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
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
                Text(_overtimeData['location_address'] ?? 'Alamat tidak tercatat'),
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
            const SizedBox(height: 24),
            
            // 👇 BAGIAN BARU UNTUK TOMBOL AKSI 👇
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (isPending) // Tampilkan tombol hanya jika status masih 'pending'
              _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---

  /// Widget untuk membangun tombol Approve dan Reject
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showConfirmationDialog('rejected'),
            icon: const Icon(Icons.close),
            label: const Text('REJECT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showConfirmationDialog('approved'),
            icon: const Icon(Icons.check),
            label: const Text('APPROVE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  /// Menampilkan dialog konfirmasi sebelum mengubah status
  void _showConfirmationDialog(String status) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Tindakan'),
          content: Text('Anda yakin ingin me-${status == 'approved' ? 'approve' : 'reject'} pengajuan ini?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                _updateStatus(status);      // Jalankan aksi
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: status == 'approved' ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yakin'),
            ),
          ],
        );
      },
    );
  }
  
  // Helper yang sudah ada (tidak perlu diubah)
  String _formatDate(String? date) => date == null ? 'N/A' : DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.parse(date));
  String _formatTime(String? time) => time == null ? 'N/A' : DateFormat('HH:mm').format(DateFormat('HH:mm:ss').parse(time));

  Widget _buildDetailCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: Colors.indigo.shade700, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]), const Divider(height: 24), ...children])));
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey)), Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold)))]));
  }

  Widget _buildPhotoViewer(String title, String imageUrl) {
    return Column(children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), Container(width: double.infinity, height: 250, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: imageUrl.isNotEmpty ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, o, s) => const Center(child: Icon(Icons.broken_image, size: 40)), loadingBuilder: (c, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator())) : const Center(child: Icon(Icons.photo, size: 40))))]);
  }
}