import 'package:flutter/material.dart';
import 'package:absensi/pegawai/services/api_service.dart';
import 'package:absensi/pegawai/screens/dashboard_screen.dart';
import 'package:absensi/admin/admin_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WfoLoginScreen extends StatefulWidget {
  const WfoLoginScreen({super.key});

  @override
  State<WfoLoginScreen> createState() => _WfoLoginScreenState();
}

class _WfoLoginScreenState extends State<WfoLoginScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _apiService.validateWfoIp();
      
      final response = await _apiService.login(
        _emailController.text,
        _passwordController.text,
      );
  
      // --- PERBAIKAN LOGIKA PARSING JSON ---
      final Map<String, dynamic> userData;
      if (response.containsKey('user') && response['user'] is Map) {
        userData = response['user'] as Map<String, dynamic>;
      } else {
        userData = response;
      }

      if (userData.containsKey('id') && userData['id'] != null && userData.containsKey('role') && userData['role'] != null) {
        final userId = int.parse(userData['id'].toString());
        final userRole = userData['role'] as String;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', userId);
        await prefs.setString('user_role', userRole);
        await prefs.setInt('login_timestamp', DateTime.now().millisecondsSinceEpoch);
        await prefs.setString('login_type', 'wfo');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login Berhasil!'), backgroundColor: Colors.green),
          );
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => userRole.toLowerCase() == 'admin'
                  ? const AdminDashboardScreen() 
                  : const DashboardScreen(),
            ),
          );
        }
      } else {
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
      appBar: AppBar(title: const Text('Login Work from Office')),
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
