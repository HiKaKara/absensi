import 'package:flutter/material.dart';
import 'package:absensi/services/api_service.dart';

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

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Validasi IP terlebih dahulu
      await _apiService.validateWfoIp();
      
      // 2. Jika IP valid, lanjutkan ke proses login
      await _apiService.login(
        _emailController.text,
        _passwordController.text,
      );
      
      // Jika login berhasil, navigasi ke halaman dashboard (belum dibuat)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login WFO Berhasil!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      // Tangani error dari validasi IP atau dari proses login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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