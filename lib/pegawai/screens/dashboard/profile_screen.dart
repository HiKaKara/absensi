import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absensi/services/api_service.dart';
import 'package:absensi/selection_screen.dart'; // Import halaman awal

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  // URL dasar untuk menampilkan gambar dari server CI
  // final String _imageUrlBase = 'http://192.168.1.5:8080/uploads/avatars/';
  final String _imageUrlBase = 'http://10.14.72.250:8080/uploads/avatars/';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) {
        throw Exception('User ID tidak ditemukan. Silakan login kembali.');
      }
      final data = await _apiService.fetchUserProfile(userId);
      setState(() {
        _userData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      try {
      final userIdString = _userData?['id']?.toString();
      if (userIdString == null) return;
      final userIdInt = int.parse(userIdString);
        
        // Tampilkan loading
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mengunggah foto...')));
        
        final response = await _apiService.uploadProfilePicture(userIdInt, imageFile);
        
        // Perbarui UI setelah berhasil
        setState(() {
          _userData!['profile_picture'] = response['file_path'].toString().split('/').last;
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto berhasil diperbarui!'), backgroundColor: Colors.green));

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus semua data yang tersimpan
    
    // Navigasi kembali ke halaman awal dan hapus semua halaman sebelumnya
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const SelectionScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    if (_userData == null) {
      return const Center(child: Text('Data profil tidak tersedia.'));
    }
    
    String? profilePictureName = _userData!['profile_picture'];
    Widget profileImage;

    if (profilePictureName != null && profilePictureName.isNotEmpty) {
      profileImage = CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage('$_imageUrlBase$profilePictureName'),
      );
    } else {
      profileImage = const CircleAvatar(
        radius: 50,
        child: Icon(Icons.person, size: 50),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Center(
            child: Stack(
              children: [
                profileImage,
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.indigo,
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                      onPressed: _pickAndUploadImage,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProfileInfo('Nama', _userData!['name'] ?? 'N/A'),
                  _buildProfileInfo('Email', _userData!['email'] ?? 'N/A'),
                  _buildProfileInfo('ID Karyawan', _userData!['employee_id'] ?? 'N/A'),
                  _buildProfileInfo('Posisi', _userData!['position'] ?? 'N/A'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProfileInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}