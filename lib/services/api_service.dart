import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:absensi/services/app_config.dart';

class ApiService {
  static const String _baseUrl = AppConfig.baseUrl;

  Future<void> validateWfoIp() async {
    final url = Uri.parse('${_baseUrl}attendance/validate-wfo-ip');
    try {
      final response = await http.post(url).timeout(const Duration(seconds: 15));
      
      if (response.statusCode != 200) {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['messages']['error'] ?? 'Akses WFO ditolak oleh server.');
        } catch (e) {
          throw Exception('Akses WFO ditolak. Status: ${response.statusCode}');
        }
      }
    } on TimeoutException {
      throw Exception('Gagal memverifikasi jaringan: koneksi timeout.');
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server untuk validasi IP. Periksa koneksi jaringan Anda.');
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // PERBAIKAN: Menambahkan parameter kelima 'checklist'
  Future<Map<String, dynamic>> submitCheckOut(int userId, File imageFile, Position position, String address, String checklist) async {
    final url = Uri.parse('${_baseUrl}attendance/checkout');
    var request = http.MultipartRequest('POST', url);

    request.fields['user_id'] = userId.toString();
    request.fields['latitude'] = position.latitude.toString();
    request.fields['longitude'] = position.longitude.toString();
    request.fields['address'] = address;
    request.fields['checkout_checklist'] = checklist;
    
    request.files.add(
      await http.MultipartFile.fromPath('photo_out', imageFile.path),
    );

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamedResponse);

      if (!response.headers['content-type']!.contains('application/json')) {
          throw Exception('Server memberikan respons yang tidak valid.');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        String errorMessage = responseData['messages']?['error'] ?? 'Gagal melakukan Check Out.';
        throw Exception(errorMessage);
      }
    } on TimeoutException catch (_) {
      throw Exception('Koneksi ke server timeout. Periksa jaringan Anda.');
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }
  
  Future<Map<String, dynamic>> getAdminDashboardSummary() async {
    final url = Uri.parse('${_baseUrl}admin/dashboard-summary');
    try {
        final response = await http.get(url).timeout(const Duration(seconds: 20));
        if (response.statusCode == 200) {
            return jsonDecode(response.body) as Map<String, dynamic>;
        } else {
            // Coba parse pesan error dari server untuk memberikan feedback yang lebih baik
            try {
              final errorData = jsonDecode(response.body);
              final errorMessage = errorData['messages']?['error'] ?? 'Gagal memuat data dashboard. Status: ${response.statusCode}';
              throw Exception(errorMessage);
            } catch (_) {
              // Jika parsing gagal (misal respons bukan JSON), lempar error generik
              throw Exception('Gagal memuat data dashboard. Status: ${response.statusCode}');
            }
        }
    } on TimeoutException {
        throw Exception('Koneksi ke server timeout.');
    } on SocketException {
        throw Exception('Tidak dapat terhubung ke server.');
    } catch (e) {
        rethrow; // Lemparkan kembali error asli agar tidak kehilangan jejak
    }
  }

  Future<List<dynamic>> fetchAllEmployees() async {
    final url = Uri.parse('${_baseUrl}admin/employees');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['messages']['error'] ?? 'Gagal memuat data pegawai.');
      }
    } on TimeoutException catch (_) {
      throw Exception('Koneksi ke server timeout.');
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi jaringan Anda.');
    } catch (e) {
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  Future<void> updateUserRole(int userId, String role) async {
    final url = Uri.parse('${_baseUrl}admin/employees/update_role/$userId');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'role': role}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['messages']['error'] ?? 'Gagal memperbarui role.');
      }
    } on TimeoutException catch (_) {
      throw Exception('Koneksi ke server timeout.');
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi jaringan Anda.');
    } catch (e) {
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  Future<List<dynamic>> fetchUsers() async {
    final url = Uri.parse('$_baseUrl/users');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal memuat data pengguna dari server.');
      }
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    } catch (e) {
      throw Exception('Terjadi kesalahan saat memuat pengguna: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('${_baseUrl}auth/login');
    
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        final errorMessage = responseData['messages']?['error'] ?? 'Login gagal, periksa kembali email dan password Anda.';
        throw Exception(errorMessage);
      }
    } on TimeoutException {
      throw Exception('Koneksi ke server timeout. Pastikan server berjalan dan terhubung ke jaringan yang sama.');
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa alamat IP server dan koneksi jaringan Anda.');
    } on FormatException {
      throw Exception('Server memberikan respons yang tidak valid. Periksa log di sisi server.');
    } catch (e) {
      // Lemparkan kembali error aslinya agar tidak kehilangan konteks
      rethrow;
    }
  }
  Future<Map<String, dynamic>> fetchUserProfile(int userId) async {
    final url = Uri.parse('${_baseUrl}users/$userId');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['messages']?['error'] ?? 'Gagal memuat profil pengguna. Status: ${response.statusCode}';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception('Gagal memuat profil pengguna. Status: ${response.statusCode}');
        }
      }
    } on TimeoutException {
      throw Exception('Koneksi ke server timeout saat memuat profil.');
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadProfilePicture(int userId, File imageFile) async {
    final url = Uri.parse('${_baseUrl}users/upload/$userId');
    var request = http.MultipartRequest('POST', url);
    
    request.files.add(
      await http.MultipartFile.fromPath(
        'profile_picture',
        imageFile.path,
      ),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal mengunggah foto. Status: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    } catch (e) {
      throw Exception('Error saat mengunggah foto: $e');
    }
  }
  Future<Map<String, dynamic>> submitCheckIn({
  required int userId,
  required File imageFile,
  required Position position,
  required String address,
  required String shift,
  required String workLocationType,
}) async {
  final url = Uri.parse('${_baseUrl}attendance/checkin');
  var request = http.MultipartRequest('POST', url);

  request.fields['user_id'] = userId.toString();
  request.fields['latitude'] = position.latitude.toString();
  request.fields['longitude'] = position.longitude.toString();
  request.fields['address'] = address;
  request.fields['shift'] = shift;
  request.fields['work_location_type'] = workLocationType;
  
  request.files.add(
    await http.MultipartFile.fromPath('photo_in', imageFile.path),
  );

    try {
      print('Mengirim data check-in ke server...');
      final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Respons diterima dari server dengan status code: ${response.statusCode}');
      
      if (!response.headers['content-type']!.contains('application/json')) {
          print('--- SERVER RESPONSE BUKAN JSON (CHECK IN) ---');
          print('Response Body: ${response.body}');
          print('-------------------------------------------');
          throw Exception('Server memberikan respons yang tidak valid (bukan JSON).');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Check-in berhasil: $responseData');
        return responseData;
      } else {
        print('Server Error Response (Check In): $responseData');
        String errorMessage = responseData['messages']?['error'] ?? 'Gagal melakukan Check In.';
        throw Exception(errorMessage);
      }
    } on TimeoutException catch (_) {
      print('Error: Koneksi ke server timeout.');
      throw Exception('Koneksi ke server timeout. Periksa jaringan Anda.');
    } on SocketException {
      print('Error: Tidak dapat terhubung ke server.');
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi jaringan Anda.');
    } catch (e) {
      print('Terjadi error saat check-in: $e');
      throw Exception(e.toString());
    }
  }
  
  Future<List<dynamic>> fetchAttendanceHistory(
  int userId, {
  DateTime? startDate,
  DateTime? endDate,
}) async {
  var uri = Uri.parse('${_baseUrl}attendance/history/$userId');

  if (startDate != null && endDate != null) {
    uri = uri.replace(queryParameters: {
      'startDate': DateFormat('yyyy-MM-dd').format(startDate),
      'endDate': DateFormat('yyyy-MM-dd').format(endDate),
    });
  }

  try {
    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['messages']?['error'] ?? 'Gagal memuat riwayat presensi. Status: ${response.statusCode}';
        throw Exception(errorMessage);
      } catch (_) {
        throw Exception('Gagal memuat riwayat presensi. Status: ${response.statusCode}');
      }
    }
  } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
  } on TimeoutException {
      throw Exception('Koneksi ke server timeout saat memuat riwayat.');
  } catch (e) {
    rethrow;
  }
}
  Future<List<dynamic>> fetchOvertimeHistory(
  int userId, {
  DateTime? startDate,
  DateTime? endDate,
}) async {
  var uri = Uri.parse('${_baseUrl}overtime/history/$userId');

  if (startDate != null && endDate != null) {
    uri = uri.replace(queryParameters: {
      'startDate': DateFormat('yyyy-MM-dd').format(startDate),
      'endDate': DateFormat('yyyy-MM-dd').format(endDate),
    });
  }

  try {
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['messages']?['error'] ?? 'Gagal memuat riwayat lembur. Status: ${response.statusCode}';
        throw Exception(errorMessage);
      } catch (_) {
        throw Exception('Gagal memuat riwayat lembur. Status: ${response.statusCode}');
      }
    }
  } on TimeoutException {
    throw Exception('Koneksi ke server timeout saat memuat riwayat lembur.');
  } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
  } catch (e) {
    rethrow;
  }
}
  Future<Map<String, dynamic>> submitOvertime({
    required int userId,
    required String overtimeType,
    required DateTime startDate,
    required DateTime endDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required File imageFile,
    required Position position,
    required String address,
    required String keterangan,
    int? coworkerId,
  }) async {
    final token = await _getAuthToken();
    final url = Uri.parse('${_baseUrl}overtime/submit');
    var request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token';

    String formatTimeOfDay(TimeOfDay tod) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
      return DateFormat('HH:mm:ss').format(dt);
    }

    request.fields['user_id'] = userId.toString();
    request.fields['overtime_type'] = overtimeType;
    request.fields['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
    request.fields['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
    request.fields['start_time'] = formatTimeOfDay(startTime);
    request.fields['end_time'] = formatTimeOfDay(endTime);
    request.fields['location_address'] = address;
    request.fields['latitude'] = position.latitude.toString();
    request.fields['longitude'] = position.longitude.toString();
    request.fields['keterangan'] = keterangan;
    if (coworkerId != null) {
      request.fields['coworker_id'] = coworkerId.toString();
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'evidence_photo',
        imageFile.path,
      ),
    );

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return responseData;
      } else {
        throw Exception(responseData['messages']['error'] ?? 'Gagal mengirim pengajuan.');
      }
    } on TimeoutException catch (_) {
      throw Exception('Koneksi ke server timeout.');
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> updateOvertimeStatus(String overtimeId, String status) async {
    final token = await _getAuthToken();
    final url = Uri.parse('$_baseUrl/admin/overtime/status/$overtimeId');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'status': status}),
    );

    final responseBody = json.decode(response.body);
    if (response.statusCode == 200) {
      return responseBody;
    } else {
      final errorMessage = responseBody['messages']?['error'] ?? 'Gagal memperbarui status.';
      throw Exception(errorMessage);
    }
  }
  
  Future<List<dynamic>> fetchAllAttendanceHistory() async {
    final url = Uri.parse('${_baseUrl}admin/attendance-history');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['messages']?['error'] ?? 'Gagal memuat riwayat absensi. Status: ${response.statusCode}';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception('Gagal memuat riwayat absensi. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      // Rethrow untuk menangkap TimeoutException, SocketException, dll.
      rethrow;
    }
  }

    Future<List<dynamic>> fetchAllOvertimeHistory() async {
    final url = Uri.parse('${_baseUrl}admin/overtime-history');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal memuat riwayat lembur semua pegawai.');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> addEmployee(String name, String email, String password, String role, String position) async {
    final url = Uri.parse('$_baseUrl/admin/employees'); // Endpoint untuk create user

    try {
      final response = await http.post(
        url,
        // PERBAIKAN: Tambahkan header dan encode body ke JSON
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'position': position,
        }),
      );

      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        // Ini terjadi jika body bukan JSON, misal halaman error HTML
        throw Exception('Server memberikan respons yang tidak valid. Cek log error di API CodeIgniter Anda.');
      }

      // Gunakan HttpStatus untuk kode yang lebih mudah dibaca
      if (response.statusCode == 200 || response.statusCode == 201) { // Terima 200 (OK) atau 201 (Created)
        return responseData;
      } else {
        // Ambil pesan error dari JSON dengan aman
        final errorMessage = responseData['messages']?['error'] ?? 'Terjadi error yang tidak diketahui dari server.';
        throw Exception(errorMessage);
      }
    } on SocketException {
      // Error jika tidak ada koneksi sama sekali (misal, WiFi mati atau IP salah)
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi internet dan alamat IP.');
    } catch (e) {
      // Menangkap semua error lainnya, termasuk yang kita lempar di atas
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> updateEmployee(int id, String name, String role, {String? password}) async {
    final url = Uri.parse('${_baseUrl}admin/employees/$id');
    try {
      Map<String, dynamic> body = {
        'name': name,
        'role': role,
      };
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Gagal memperbarui pegawai: ${e.toString()}');
    }
  }

  // Helper method to get authentication token from SharedPreferences
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // Assuming 'token' is where you store the auth token
  }
}
