import 'package:flutter/material.dart';
import 'package:absensi/services/api_service.dart';
import 'package:absensi/screens/dashboard_screen.dart';
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

    setState(() {
      _isLoading = true;
    });

    try {
    final response = await _apiService.login(
      _emailController.text,
      _passwordController.text,
    );

    // Ambil user ID dari response
    final userIdString = response['user']['id'].toString();

    // UBAH STRING MENJADI INT DENGAN PARSE
    final userIdInt = int.parse(userIdString);

    // Simpan ID pengguna yang sudah menjadi integer
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userIdInt);
      // Anda bisa menggunakan data 'response' di sini jika perlu
      print('Login berhasil untuk: ${response['user']['name']}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login WFA Berhasil!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // Menghapus "Exception: " dari pesan error
          content: Text(e.toString().replaceAll("Exception: ", "")),
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