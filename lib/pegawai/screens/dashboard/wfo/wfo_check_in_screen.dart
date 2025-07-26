import 'dart:async';
import 'dart:io';
import 'package:absensi/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WfoCheckInScreen extends StatefulWidget {
  const WfoCheckInScreen({super.key});

  @override
  State<WfoCheckInScreen> createState() => _WfoCheckInScreenState();
}

class _WfoCheckInScreenState extends State<WfoCheckInScreen> {
  late Future<void> _initializationFuture;

  CameraController? _cameraController;
  XFile? _capturedImage;
  Position? _currentPosition;
  String _currentAddress = "Memuat alamat...";
  final Completer<GoogleMapController> _mapController = Completer();
  String _currentShift = "Memuat shift...";
  bool _isSubmitting = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializePage();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    try {
      await Future.wait([
        _initializeCamera(),
        _initializeLocation(),
      ]);
      _determineShift();
    } catch (e) {
      throw Exception('Gagal memuat halaman: ${e.toString().replaceAll("Exception: ", "")}');
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
        throw Exception('Izin lokasi ditolak permanen.');
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      if (mounted) {
        setState(() => _currentPosition = position);
        await _getAddressFromLatLng();
      }
    } catch (e) {
      if(mounted) setState(() => _currentAddress = "Gagal mendapatkan lokasi");
      throw Exception(e.toString());
    }
  }

  Future<void> _getAddressFromLatLng() async {
    try {
      if (_currentPosition == null) return;
      List<Placemark> placemarks = await placemarkFromCoordinates(_currentPosition!.latitude, _currentPosition!.longitude);
      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];
        setState(() => _currentAddress = "${place.street}, ${place.subLocality}, ${place.locality}");
      }
    } catch (e) {
      if (mounted) setState(() => _currentAddress = "Gagal menerjemahkan lokasi.");
    }
  }

  void _determineShift() {
    final hour = TimeOfDay.now().hour;
    if (hour >= 7 && hour < 15) _currentShift = "Shift 1 (07:00 - 15:00)";
    else if (hour >= 15 && hour < 23) _currentShift = "Shift 2 (15:00 - 23:00)";
    else _currentShift = "Shift 3 (23:00 - 07:00)";
  }

  Future<void> _takePicture() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) return;
      final image = await _cameraController!.takePicture();
      if (mounted) setState(() => _capturedImage = image);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _submitCheckIn() async {
    // PERBAIKAN: Validasi input sebelum mengirim
    if (_isSubmitting) return;
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan ambil foto terlebih dahulu.'), backgroundColor: Colors.orange));
      return;
    }
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lokasi tidak ditemukan. Pastikan GPS aktif.'), backgroundColor: Colors.orange));
      return;
    }

    const double officeLatitude = -6.342621240893616;
    const double officeLongitude = 106.78842019412906;
    const double maxDistanceInMeters = 100;

    final distance = Geolocator.distanceBetween(
      officeLatitude, officeLongitude,
      _currentPosition!.latitude, _currentPosition!.longitude,
    );

    if (distance > maxDistanceInMeters) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anda di luar jangkauan kantor. Jarak Anda ${distance.round()} meter.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) throw Exception("Sesi berakhir, mohon login ulang.");

      print("Mengirim data WFO Check-in untuk user ID: $userId");
      final response = await _apiService.submitCheckIn(
        userId: userId,
        imageFile: File(_capturedImage!.path),
        position: _currentPosition!,
        address: _currentAddress,
        shift: _currentShift,
        workLocationType: 'WFO',
      );
      
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Check In Berhasil'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      print("Error saat submit WFO Check-in: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check In (WFO)')),
      body: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
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

          return _buildCheckInForm();
        },
      ),
    );
  }

  Widget _buildCheckInForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            title: 'Jadwal Presensi Saat Ini',
            icon: Icons.access_time_filled,
            content: Text(_currentShift, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Capture Wajah',
            icon: Icons.camera_alt,
            content: Column(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                  child: _capturedImage != null
                      ? Image.file(File(_capturedImage!.path), fit: BoxFit.cover)
                      : (_cameraController != null && _cameraController!.value.isInitialized)
                          ? CameraPreview(_cameraController!)
                          : const Center(child: Text("Kamera tidak tersedia")),
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
            title: 'Lokasi Anda',
            icon: Icons.location_on,
            content: Column(
              children: [
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: _currentPosition == null
                      ? Center(child: Text(_currentAddress))
                      : GoogleMap(
                          mapType: MapType.normal,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            zoom: 17.0,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('currentLocation'),
                              position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            )
                          },
                          onMapCreated: (GoogleMapController controller) {
                            if(!_mapController.isCompleted) _mapController.complete(controller);
                          },
                          zoomGesturesEnabled: false,
                          scrollGesturesEnabled: false,
                        ),
                ),
                const SizedBox(height: 8),
                Text(_currentAddress, textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitCheckIn,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('SUBMIT CHECK IN', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget content}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 20),
            content,
          ],
        ),
      ),
    );
  }
}
