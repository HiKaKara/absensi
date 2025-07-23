import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absensi/services/api_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class WfaCheckOutScreen extends StatefulWidget {
  const WfaCheckOutScreen({super.key});

  @override
  State<WfaCheckOutScreen> createState() => _WfaCheckOutScreenState();
}

class _WfaCheckOutScreenState extends State<WfaCheckOutScreen> {
  // --- State ---
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
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
    _initializeCamera();
    _initializeLocation();
    _determineShift();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // --- Logika ---
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first);
      _cameraController = CameraController(firstCamera, ResolutionPreset.medium);
      _initializeControllerFuture = _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print("Error inisialisasi kamera: $e");
    }
  }

  Future<void> _initializeLocation() async {
    try {
      setState(() => _currentAddress = 'Mencari lokasi akurat...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Layanan lokasi (GPS) tidak aktif.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Izin lokasi ditolak.');
      }
      if (permission == LocationPermission.deniedForever) throw Exception('Izin lokasi ditolak permanen.');

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      if (mounted) {
        setState(() => _currentPosition = position);
        await _getAddressFromLatLng();
      }
    } catch (e) {
      if (mounted) setState(() => _currentAddress = e.toString().replaceAll("Exception: ", ""));
    }
  }

  Future<void> _getAddressFromLatLng() async {
  try {
    if (_currentPosition == null) {
      if(mounted) setState(() => _currentAddress = "Koordinat tidak ditemukan.");
      return;
    }
    
    // Panggil API geocoding
    List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude, _currentPosition!.longitude);
        
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      
      // --- Logika Baru untuk Format Alamat yang Lebih Baik ---
      // 'name' sering kali berisi nama tempat/gedung (seperti "Icon+ Gandul")
      String placeName = place.name ?? '';
      // 'thoroughfare' berisi nama jalan
      String street = place.thoroughfare ?? '';
      // 'subLocality' biasanya berisi nama kelurahan/area
      String subLocality = place.subLocality ?? '';

      // Gabungkan untuk format yang lebih relevan
      String formattedAddress = placeName;
      if (street.isNotEmpty && !placeName.contains(street)) {
        formattedAddress += ", $street";
      }
      if (subLocality.isNotEmpty && !formattedAddress.contains(subLocality)) {
        formattedAddress += ", $subLocality";
      }
      // --- Akhir Logika Baru ---

      if (mounted) {
        setState(() {
          _currentAddress = formattedAddress;
        });
      }
    } else {
      if (mounted) setState(() => _currentAddress = "Alamat tidak ditemukan.");
    }
  } catch (e) {
    if (mounted) setState(() => _currentAddress = "Gagal menerjemahkan lokasi.");
    print("Error Geocoding: $e");
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
      await _initializeControllerFuture;
      final image = await _cameraController!.takePicture();
      if (mounted) setState(() => _capturedImage = image);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _submitCheckOut() async {
    if (_capturedImage == null || _currentPosition == null || _isSubmitting) return;

    // TIDAK ADA VALIDASI JARAK UNTUK WFA

    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) throw Exception("Sesi berakhir, mohon login ulang.");

      final response = await _apiService.submitCheckOut(
        userId,
        File(_capturedImage!.path),
        _currentPosition!,
      );
      
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message']), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check Out (WFA)')),
      body: SingleChildScrollView(
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
                        : FutureBuilder<void>(
                            future: _initializeControllerFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done) {
                                return _cameraController != null ? CameraPreview(_cameraController!) : const Center(child: Text("Kamera tidak tersedia"));
                              } else {
                                return const Center(child: CircularProgressIndicator());
                              }
                            },
                          ),
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
              onPressed: _submitCheckOut,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red, // Warna berbeda untuk check out
                foregroundColor: Colors.white,
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('SUBMIT CHECK OUT', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
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