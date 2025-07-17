import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absensi/services/api_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CheckOutScreen extends StatefulWidget {
  const CheckOutScreen({super.key});

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> {
  // State untuk Kamera, Lokasi, dan Shift (sama seperti CheckInScreen)
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

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first);
    _cameraController = CameraController(firstCamera, ResolutionPreset.medium);
    _initializeControllerFuture = _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _initializeLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _currentAddress = 'Layanan lokasi mati.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _currentAddress = 'Izin lokasi ditolak.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _currentAddress = 'Izin lokasi ditolak permanen.');
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });

    _getAddressFromLatLng();
  }

  // FUNGSI YANG HILANG - SAYA TAMBAHKAN DI SINI
  Future<void> _getAddressFromLatLng() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude, _currentPosition!.longitude);

      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
      });
    } catch (e) {
      print(e);
    }
  }
  
  // Deteksi Shift untuk Check Out
  void _determineShift() {
    final hour = TimeOfDay.now().hour;
    // Shift 1 (07:00 - 15:00) -> Checkout bisa terjadi di rentang ini
    if (hour >= 7 && hour < 15) {
      _currentShift = "Shift 1 (07:00 - 15:00)";
    } 
    // Shift 2 (15:00 - 23:00) -> Checkout bisa terjadi di rentang ini
    else if (hour >= 15 && hour < 23) {
      _currentShift = "Shift 2 (15:00 - 23:00)";
    } 
    // Shift 3 (23:00 - 07:00) -> Checkout bisa terjadi di rentang ini
    else {
      _currentShift = "Shift 3 (23:00 - 07:00)";
    }
    if (mounted) setState(() {});
  }
  
  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = image;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _submitCheckOut() async {
    if (_capturedImage == null || _currentPosition == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) {
        throw Exception("User ID tidak ditemukan, silakan login ulang.");
      }

      final response = await _apiService.submitCheckOut(
        userId,
        File(_capturedImage!.path),
        _currentPosition!,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message']), backgroundColor: Colors.green),
      );
      // Kembali ke halaman dashboard setelah berhasil
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lakukan Check Out')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionCard(
              title: 'Jadwal Presensi Saat Ini',
              icon: Icons.access_time_filled,
              content: Text(_currentShift,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
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
                    decoration:
                        BoxDecoration(border: Border.all(color: Colors.grey)),
                    child: _capturedImage != null
                        ? Image.file(File(_capturedImage!.path),
                            fit: BoxFit.cover)
                        : FutureBuilder<void>(
                            future: _initializeControllerFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.done) {
                                return CameraPreview(_cameraController!);
                              } else {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera),
                    label: Text(_capturedImage == null
                        ? 'Ambil Gambar'
                        : 'Ambil Ulang'),
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
                  Container(
                    height: 200,
                    width: double.infinity,
                    child: _currentPosition == null
                        ? const Center(child: CircularProgressIndicator())
                        : GoogleMap(
                            mapType: MapType.normal,
                            initialCameraPosition: CameraPosition(
                              target: LatLng(_currentPosition!.latitude,
                                  _currentPosition!.longitude),
                              zoom: 17.0,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('currentLocation'),
                                position: LatLng(_currentPosition!.latitude,
                                    _currentPosition!.longitude),
                              )
                            },
                            onMapCreated: (GoogleMapController controller) {
                              _mapController.complete(controller);
                            },
                            zoomGesturesEnabled: false,
                            scrollGesturesEnabled: false,
                            tiltGesturesEnabled: false,
                            rotateGesturesEnabled: false,
                            zoomControlsEnabled: false,
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
                backgroundColor: Colors.red,
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

  Widget _buildSectionCard(
      {required String title,
      required IconData icon,
      required Widget content}) {
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
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
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
