import 'package:flutter/material.dart';
import 'package:absensi/services/api_service.dart';
import 'package:absensi/pegawai/screens/dashboard_screen.dart';
import 'package:absensi/admin/admin_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WfaLoginScreen extends StatefulWidget {
  const WfaLoginScreen({super.key});

  @override
  State<WfaLoginScreen> createState() => _WfaLoginScreenState();
}

class _WfaLoginScreenState extends State<WfaLoginScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.login(
        _emailController.text,
        _passwordController.text,
      );

      // --- PERBAIKAN LOGIKA PARSING DAN NAVIGASI ---
      final Map<String, dynamic> userData;
      // Cek apakah data pengguna ada di dalam objek 'user'
      if (response.containsKey('user') && response['user'] is Map) {
        userData = response['user'] as Map<String, dynamic>;
      } else {
        // Jika tidak, asumsikan data pengguna ada di level atas
        userData = response;
      }

      // Pastikan data 'id' dan 'role' ada dan tidak null
      if (userData.containsKey('id') && userData['id'] != null && userData.containsKey('role') && userData['role'] != null) {
        final userId = int.parse(userData['id'].toString());
        final userRole = userData['role'] as String;

        // Simpan semua data sesi yang diperlukan
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', userId);
        await prefs.setString('user_role', userRole);
        await prefs.setInt('login_timestamp', DateTime.now().millisecondsSinceEpoch);
        await prefs.setString('login_type', 'wfa');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login Berhasil!'), backgroundColor: Colors.green),
          );
          
          // Arahkan ke dashboard yang sesuai berdasarkan role
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => userRole.toLowerCase() == 'admin' 
                  ? const AdminDashboardScreen() 
                  : const DashboardScreen(),
            ),
          );
        }
      } else {
        // Lemparkan error jika format respons dari API tidak sesuai harapan
        throw Exception('Respons dari server tidak valid (data user tidak ditemukan).');
      }
      // --- AKHIR PERBAIKAN ---

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Work from Anywhere')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Email tidak boleh kosong' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'Password tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text('Login'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
