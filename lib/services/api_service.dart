import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import 'package:intl/intl.dart';

class ApiService {
  // CATATAN PENTING: Pastikan IP address ini dapat diakses dari perangkat Anda.
  // '10.0.2.2' adalah alamat localhost untuk emulator Android.
  // Jika Anda menggunakan perangkat fisik, ganti dengan IP address komputer Anda di jaringan yang sama.
  static const String _baseUrl = 'http://192.168.1.5:8080/api/';


Future<List<dynamic>> fetchAllEmployees() async {
    final url = Uri.parse('${_baseUrl}admin/employees'); // Panggil endpoint admin
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Coba baca pesan error dari server jika ada
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

Future<void> validateWfoIp() async {
  final url = Uri.parse('${_baseUrl}attendance/validate-wfo-ip');
  try {
    final response = await http.post(url).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['messages']['error'] ?? 'Akses WFO ditolak. Pastikan Anda terhubung ke jaringan kantor.');
    }
  } on TimeoutException {
    throw Exception('Gagal memverifikasi jaringan: koneksi timeout.');
  } on SocketException {
      throw Exception('Tidak dapat terhubung ke server untuk validasi IP. Periksa koneksi jaringan Anda.');
  } catch (e) {
    throw Exception('Gagal terhubung ke server untuk validasi IP.');
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
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['messages']['error'] ?? 'Terjadi kesalahan saat login');
      }
    } on TimeoutException {
      throw Exception('Koneksi ke server timeout. Gagal login.');
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    } catch (e) {
      print('Login Error: $e');
      throw Exception('Gagal login: ${e.toString()}');
    }
  }
  Future<Map<String, dynamic>> fetchUserProfile(int userId) async {
    final url = Uri.parse('${_baseUrl}users/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal memuat profil pengguna.');
      }
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    } catch (e) {
      throw Exception('Terjadi kesalahan: ${e.toString()}');
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
  Future<Map<String, dynamic>> submitCheckOut(int userId, File imageFile, Position position, String currentAddress) async {
  final url = Uri.parse('${_baseUrl}attendance/checkout');
  var request = http.MultipartRequest('POST', url);

  request.fields['user_id'] = userId.toString();
  request.fields['latitude'] = position.latitude.toString();
  request.fields['longitude'] = position.longitude.toString();
  request.fields['address'] = currentAddress;
  request.fields['checkout_checklist'] = checklist;
  
  request.files.add(
    await http.MultipartFile.fromPath('photo_out', imageFile.path),
  );

  try {
    final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamedResponse);

      if (!response.headers['content-type']!.contains('application/json')) {
          print('--- SERVER RESPONSE BUKAN JSON ---');
          print('Status Code: ${response.statusCode}');
          print('Response Body: ${response.body}');
          print('---------------------------------');
          throw Exception('Server memberikan respons yang tidak valid.');
      }

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return responseData;
    } else {
        print('Server Error Response: $responseData');
      String errorMessage = responseData['messages']?['error'] ?? 'Gagal melakukan Check Out.';
        
        throw Exception(errorMessage);
    }
  } on TimeoutException catch (_) {
      throw Exception('Koneksi ke server timeout. Periksa jaringan Anda.');
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    } catch (e) {
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
      throw Exception('Gagal memuat riwayat presensi.');
    }
  } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
  } catch (e) {
    throw Exception(e.toString());
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
      throw Exception('Gagal memuat riwayat lembur.');
    }
  } on SocketException {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
  } catch (e) {
    throw Exception(e.toString());
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
    int? coworkerId,
  }) async {
    final url = Uri.parse('${_baseUrl}overtime/submit');
    var request = http.MultipartRequest('POST', url);

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
  Future<Map<String, dynamic>> getAdminDashboardSummary() async {
        final url = Uri.parse('${_baseUrl}admin/dashboard-summary');
        try {
            final response = await http.get(url).timeout(const Duration(seconds: 20));
            if (response.statusCode == 200) {
                return jsonDecode(response.body);
            } else {
                throw Exception('Gagal memuat data dashboard.');
            }
        } on TimeoutException {
            throw Exception('Koneksi ke server timeout.');
        } on SocketException {
            throw Exception('Tidak dapat terhubung ke server.');
        } catch (e) {
            throw Exception(e.toString());
        }
    }
}
