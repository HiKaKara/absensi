import 'package:flutter/material.dart';
import 'package:absensi/pegawai/services/api_service.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _usersFuture;

  @override
  void initState() {
    super.initState();
    // Panggil fungsi fetchUsers() saat halaman pertama kali dimuat
    _usersFuture = _apiService.fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pengguna (dari API)'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          // 1. Saat data sedang dimuat
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. Jika terjadi error
          else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          // 3. Jika data berhasil didapat dan tidak kosong
          else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final users = snapshot.data!;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(user['name'][0])),
                  title: Text(user['name']),
                  subtitle: Text(user['email']),
                );
              },
            );
          }
          // 4. Jika data kosong
          else {
            return const Center(child: Text('Tidak ada data pengguna.'));
          }
        },
      ),
    );
  }
}