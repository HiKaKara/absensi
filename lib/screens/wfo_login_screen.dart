import 'package:absensi/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:absensi/services/api_service.dart';
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
      // Langkah 1: Validasi IP terlebih dahulu
      await _apiService.validateWfoIp();
      
      // Langkah 2: Jika IP valid, lanjutkan ke proses login
      final response = await _apiService.login(
        _emailController.text,
        _passwordController.text,
      );
  
      if (response.containsKey('user') && response['user']['id'] != null) {
        final userId = int.parse(response['user']['id'].toString());
        final prefs = await SharedPreferences.getInstance();

        // --- PERUBAHAN DI SINI ---
        // Simpan semua data sesi yang diperlukan
        await prefs.setInt('user_id', userId);
        await prefs.setInt('login_timestamp', DateTime.now().millisecondsSinceEpoch);
        await prefs.setString('login_type', 'wfo'); // Tandai sebagai login WFO
        // -------------------------

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login Berhasil!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else {
        throw Exception('Respons dari server tidak valid.');
      }

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