import 'package:flutter/material.dart';
import 'package:absensi/services/api_service.dart';
import 'package:absensi/admin/add_employee_screen.dart';
import 'package:absensi/admin/edit_employee_screen.dart';

class EmployeeDataScreen extends StatefulWidget {
  const EmployeeDataScreen({super.key});

  @override
  State<EmployeeDataScreen> createState() => _EmployeeDataScreenState();
}

class _EmployeeDataScreenState extends State<EmployeeDataScreen> {
  late Future<List<dynamic>> _employeesFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  void _loadEmployees() {
    setState(() {
      _employeesFuture = _apiService.fetchAllEmployees();
    });
  }

  void _navigateAndReload(Widget page) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
    // Jika halaman add/edit mengembalikan true, muat ulang data
    if (result == true) {
      _loadEmployees();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Pegawai'),
        automaticallyImplyLeading: false,
      ),
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(employee['name']?[0] ?? 'P'),
                  ),
                  title: Text(employee['name'] ?? 'Tanpa Nama'),
                  subtitle: Text(employee['email'] ?? 'Tanpa Email'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(label: Text(employee['role'] ?? 'pegawai')),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _navigateAndReload(EditEmployeeScreen(employee: employee)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateAndReload(const AddEmployeeScreen()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
