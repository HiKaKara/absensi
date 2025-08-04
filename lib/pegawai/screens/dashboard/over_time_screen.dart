import 'dart:async';
import 'dart:io';
import 'package:absensi/pegawai/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:absensi/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OverTimeScreen extends StatefulWidget {
  const OverTimeScreen({super.key});

  @override
  State<OverTimeScreen> createState() => _OverTimeScreenState();
}

class _OverTimeScreenState extends State<OverTimeScreen> {
  // BARU: Satu Future untuk mengelola semua proses inisialisasi
  late Future<void> _initializationFuture;

  // State lainnya tetap sama
  CameraController? _cameraController;
  XFile? _capturedImage;
  Position? _currentPosition;
  String _currentAddress = "Memuat alamat...";
  final Completer<GoogleMapController> _mapController = Completer();
  final _formKey = GlobalKey<FormState>();
  String? _selectedOvertimeType;
  bool _isSubmitting = false;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final ApiService _apiService = ApiService();
  List<dynamic> _userList = [];
  Map<String, dynamic>? _selectedCoworker;
  bool _showRekanKerjaField = false;
  final _keteranganController = TextEditingController();


  final List<String> _overtimeTypes = [
    'Hari Kerja', 'Hari Libur', 'Hari Libur Nasional', 'Backup Teman Kerja'
  ];

  @override
  void initState() {
    super.initState();
    // Panggil satu fungsi utama untuk memulai semua proses async
    _initializationFuture = _initializePage();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  // --- LOGIKA UTAMA ---

  // BARU: Fungsi ini menggabungkan semua tugas berat
  Future<void> _initializePage() async {
    try {
      // Jalankan semua proses secara bersamaan untuk efisiensi
      await Future.wait([
        _initializeCamera(),
        _initializeLocation(),
        _fetchUsers(),
      ]);
    } catch (e) {
      // Jika salah satu gagal, seluruh Future akan gagal dan ditangkap oleh FutureBuilder
      throw Exception('Gagal memuat halaman: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await _apiService.fetchUsers();
      if (mounted) {
        setState(() => _userList = users);
      }
    } catch (e) {
      print("Gagal memuat pengguna: $e");
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first);
      _cameraController = CameraController(firstCamera, ResolutionPreset.medium);
      await _cameraController!.initialize();
    } catch (e) {
      print("Error inisialisasi kamera: $e");
      throw Exception('Gagal memuat kamera');
    }
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Layanan lokasi (GPS) tidak aktif.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen. Mohon aktifkan dari pengaturan aplikasi.');
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _currentAddress = "${placemarks[0].street}, ${placemarks[0].subLocality}, ${placemarks[0].locality}";
        });
      }
    } catch (e) {
      if(mounted) {
        setState(() => _currentAddress = "Gagal mendapatkan lokasi");
      }
      throw Exception(e.toString());
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final image = await _cameraController!.takePicture();
      if (mounted) setState(() => _capturedImage = image);
    } catch (e) {
      print("Error mengambil gambar: $e");
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() => isStartDate ? _startDate = picked : _endDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context, initialTime: TimeOfDay.now(),
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (picked != null && mounted) {
      setState(() => isStartTime ? _startTime = picked : _endTime = picked);
    }
  }

  Future<void> _submitOvertime() async {
  // 1. Validasi form
  if (!_formKey.currentState!.validate()) return;
  if (_capturedImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bukti lembur (foto) wajib diisi.'), backgroundColor: Colors.red));
    return;
  }
  // Validasi tambahan untuk tanggal dan waktu
  if (_startDate == null || _endDate == null || _startTime == null || _endTime == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua tanggal dan waktu wajib diisi.'), backgroundColor: Colors.red));
    return;
  }

  if (mounted) setState(() => _isSubmitting = true);

  try {
    // 2. Ambil User ID
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) {
      throw Exception("Sesi berakhir. Mohon login kembali.");
    }
    
    // Ambil ID rekan kerja jika ada
    final coworkerId = _selectedCoworker?['id'];

    // 3. Kirim data ke API
    await _apiService.submitOvertime(
        userId: userId,
        overtimeType: _selectedOvertimeType!,
        startDate: _startDate!,
        endDate: _endDate!,
        startTime: _startTime!,
        endTime: _endTime!,
        keterangan: _keteranganController.text,
        imageFile: File(_capturedImage!.path),
        position: _currentPosition!,
        address: _currentAddress,
        coworkerId: coworkerId != null ? int.parse(coworkerId.toString()) : null,
    );

    // 4. Handle respons jika berhasil

    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan lembur berhasil dikirim!'), backgroundColor: Colors.green));
        
        // Navigasi kembali ke DashboardScreen dan hapus semua halaman di atasnya
        Navigator.of(context).pushAndRemoveUntil(
         MaterialPageRoute(builder: (context) => const DashboardScreen()),
         (Route<dynamic> route) => false,
       );
    }

  } catch (e) {
    // 5. Handle jika terjadi error
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red)
      );
    }
  } finally {
    // Pastikan loading indicator berhenti
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}

  // --- UI (Tampilan) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Lembur'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          // Saat inisialisasi sedang berjalan
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Mempersiapkan halaman..."),
                ],
              ),
            );
          }

          // Jika terjadi error saat inisialisasi
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Gagal memuat halaman:\n${snapshot.error.toString().replaceAll("Exception: ", "")}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            );
          }

          // Jika inisialisasi berhasil, tampilkan form
          return _buildOvertimeForm();
        },
      ),
    );
  }

  Widget _buildOvertimeForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionCard(
              title: 'Detail Lembur',
              icon: Icons.work_history_outlined,
              content: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedOvertimeType,
                    hint: const Text('Pilih jenis lembur'),
                    items: _overtimeTypes.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedOvertimeType = newValue;
                        _showRekanKerjaField = (newValue == 'Backup Teman Kerja');
                        _selectedCoworker = null;
                      });
                    },
                    validator: (value) => value == null ? 'Jenis lembur wajib dipilih' : null,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  ),
                  
                  if (_showRekanKerjaField)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: _userList.isEmpty
                          ? const Center(child: Text("Tidak ada data rekan kerja."))
                          : DropdownButtonFormField<Map<String, dynamic>>(
                              value: _selectedCoworker, isExpanded: true,
                              hint: const Text('Pilih Rekan Kerja'),
                              items: _userList.map((user) => DropdownMenuItem<Map<String, dynamic>>(
                                value: user,
                                child: Text(user['name'] ?? 'Nama Tidak Ada'),
                              )).toList(),
                              onChanged: (newValue) => setState(() => _selectedCoworker = newValue),
                              validator: (value) => (_showRekanKerjaField && value == null) ? 'Rekan kerja wajib dipilih' : null,
                              decoration: const InputDecoration(labelText: 'Nama Rekan Kerja', border: OutlineInputBorder()),
                            ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildDatePickerField(context, 'Tanggal Mulai', _startDate, true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDatePickerField(context, 'Tanggal Selesai', _endDate, false)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTimePickerField(context, 'Waktu Mulai', _startTime, true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTimePickerField(context, 'Waktu Selesai', _endTime, false)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // --- PENAMBAHAN FIELD KETERANGAN ---
                  TextFormField(
                    controller: _keteranganController,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan Lembur',
                      hintText: 'Contoh: Menyelesaikan laporan bulanan',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Keterangan wajib diisi';
                      }
                      return null;
                    },
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Bukti Lembur (Foto Wajah)',
              icon: Icons.camera_alt_outlined,
              content: Column(
                children: [
                  Container(
                    height: 300, width: double.infinity, clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: _capturedImage != null
                        ? Image.file(File(_capturedImage!.path), fit: BoxFit.cover)
                        : (_cameraController != null && _cameraController!.value.isInitialized)
                            ? CameraPreview(_cameraController!)
                            : const Center(child: Text("Kamera tidak tersedia", style: TextStyle(color: Colors.white))),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera),
                    label: Text(_capturedImage == null ? 'Ambil Gambar' : 'Ambil Ulang'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Lokasi Lembur',
              icon: Icons.location_on_outlined,
              content: Column(
                children: [
                  SizedBox(
                    height: 200, width: double.infinity,
                    child: _currentPosition == null
                        ? Center(child: Text(_currentAddress))
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: GoogleMap(
                              mapType: MapType.normal,
                              initialCameraPosition: CameraPosition(target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude), zoom: 17.0),
                              markers: {Marker(markerId: const MarkerId('currentLocation'), position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude))},
                              onMapCreated: (GoogleMapController controller) { if (!_mapController.isCompleted) _mapController.complete(controller); },
                              zoomGesturesEnabled: false, scrollGesturesEnabled: false,
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(_currentAddress, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitOvertime,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.indigo, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Text('AJUKAN LEMBUR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildSectionCard({required String title, required IconData icon, required Widget content}) {
    return Card(
      elevation: 2, shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.indigo.shade700, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24, thickness: 1, color: Color.fromARGB(255, 236, 236, 236)),
            content,
          ],
        ),
      ),
    );
  }
  
  Widget _buildDatePickerField(BuildContext context, String label, DateTime? date, bool isStartDate) {
    return InkWell(
      onTap: () => _selectDate(context, isStartDate),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        child: Text(
          date != null ? DateFormat('dd-MM-yyyy').format(date) : 'Pilih tanggal',
          style: TextStyle(fontSize: 16, color: date == null ? Colors.grey.shade600 : Colors.black),
        ),
      ),
    );
  }
  
  Widget _buildTimePickerField(BuildContext context, String label, TimeOfDay? time, bool isStartTime) {
    return InkWell(
      onTap: () => _selectTime(context, isStartTime),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        child: Text(
          time != null ? time.format(context) : 'Pilih waktu',
          style: TextStyle(fontSize: 16, color: time == null ? Colors.grey.shade600 : Colors.black),
        ),
      ),
    );
  }
}
