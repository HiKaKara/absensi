import 'package:flutter/material.dart';
import 'package:absensi/pegawai/services/api_service.dart';

class EmployeeDataScreen extends StatefulWidget {
  const EmployeeDataScreen({super.key});
  @override
  State<EmployeeDataScreen> createState() => _EmployeeDataScreenState();
}

class _EmployeeDataScreenState extends State<EmployeeDataScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _employeesFuture;

  @override
  void initState() {
    super.initState();
    _employeesFuture = _apiService.fetchAllEmployees(); // Anda perlu membuat fungsi ini di ApiService
  }

  void _showEditRoleDialog(BuildContext context, Map<String, dynamic> employee) {
    String currentRole = employee['role'];
    final List<String> roles = ['Admin', 'Admin Hosting', 'SaaS Engineer'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ubah Role untuk ${employee['name']}'),
          content: DropdownButton<String>(
            value: currentRole,
            isExpanded: true,
            items: roles.map((String role) {
              return DropdownMenuItem<String>(value: role, child: Text(role));
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                currentRole = newValue;
              }
            },
          ),
          actions: <Widget>[
            TextButton(child: const Text('Batal'), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              child: const Text('Simpan'),
              onPressed: () {
                // Panggil API untuk update role
                _apiService.updateUserRole(employee['id'], currentRole).then((_) {
                  Navigator.of(context).pop();
                  setState(() {
                    _employeesFuture = _apiService.fetchAllEmployees(); // Muat ulang data
                  });
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Pegawai')),
      body: FutureBuilder<List<dynamic>>(
        future: _employeesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada data pegawai.'));
          }

          final employees = snapshot.data!;
          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];
              return Card(
                child: ListTile(
                  title: Text(employee['name'] ?? ''),
                  subtitle: Text(employee['role'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditRoleDialog(context, employee),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}