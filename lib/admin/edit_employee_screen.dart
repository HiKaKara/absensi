import 'package:flutter/material.dart';
import 'package:absensi/services/api_service.dart';

class EditEmployeeScreen extends StatefulWidget {
  final Map<String, dynamic> employee;

  const EditEmployeeScreen({super.key, required this.employee});

  @override
  State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final _passwordController = TextEditingController();
  late String _selectedRole;
  bool _isLoading = false;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee['name']);
    _selectedRole = widget.employee['role'] ?? 'pegawai';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final response = await _apiService.updateEmployee(
          int.parse(widget.employee['id']),
          _nameController.text,
          _selectedRole,
          password: _passwordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Berhasil!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Data Pegawai')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: widget.employee['email'],
              decoration: const InputDecoration(labelText: 'Email (tidak dapat diubah)'),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password Baru (opsional)', hintText: 'Kosongkan jika tidak ingin diubah'),
              obscureText: true,
              validator: (value) => value!.isNotEmpty && value.length < 6 ? 'Password minimal 6 karakter' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'pegawai', child: Text('Pegawai')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }
}
