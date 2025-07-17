import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class ApiService {
  // Ganti IP ini jika backend Anda dihosting di tempat lain.
  // 10.0.2.2 adalah localhost untuk emulator Android.
  static const String _baseUrl = 'http://192.168.137.1:8080/api/';

  // Fungsi untuk memvalidasi IP untuk WFO
  Future<void> validateWfoIp() async {
    final url = Uri.parse('${_baseUrl}attendance/validate-wfo-ip');
    
    try {
      final response = await http.post(url);

      if (response.statusCode == 200) {
        // IP valid, tidak perlu melakukan apa-apa
        print("IP address is valid for WFO.");
        return;
      } else {
        // IP tidak valid, lempar error dengan pesan dari API
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['messages']['error'] ?? 'Akses WFO ditolak.');
      }
    } catch (e) {
      // Tangani error koneksi atau error lainnya
      print('Error during IP validation: $e');
      throw Exception('Gagal terhubung ke server. Periksa koneksi internet Anda.');
    }
  }
  Future<List<dynamic>> fetchUsers() async {
    final url = Uri.parse('$_baseUrl/users');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Jika request berhasil, decode JSON dan kembalikan sebagai List
        return jsonDecode(response.body);
      } else {
        // Jika server mengembalikan error
        throw Exception('Gagal memuat data pengguna dari server.');
      }
    } catch (e) {
      // Jika terjadi error koneksi
      throw Exception('Gagal terhubung ke server. Periksa koneksi Anda.');
    }
  }
  // Placeholder untuk fungsi login sebenarnya
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
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Jika login berhasil, kembalikan data pengguna
        return responseData;
      } else {
        // Jika login gagal (misal: password salah), lempar pesan error dari API
        throw Exception(responseData['messages']['error'] ?? 'Terjadi kesalahan');
      }
    } catch (e) {
      // Tangani error koneksi atau error lainnya
      print('Login Error: $e');
      throw Exception('Gagal terhubung ke server. Periksa koneksi Anda.');
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
    } catch (e) {
      throw Exception('Gagal terhubung ke server.');
    }
  }

  Future<Map<String, dynamic>> uploadProfilePicture(int userId, File imageFile) async {
    final url = Uri.parse('${_baseUrl}users/upload/$userId');
    var request = http.MultipartRequest('POST', url);
    
    // Tambahkan file ke request
    request.files.add(
      await http.MultipartFile.fromPath(
        'profile_picture', // Nama field ini harus sama dengan di CI: getFile('profile_picture')
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
  }) async {
    final url = Uri.parse('${_baseUrl}attendance/checkin');
    var request = http.MultipartRequest('POST', url);

    // Tambahkan field data
    request.fields['user_id'] = userId.toString();
    request.fields['latitude'] = position.latitude.toString();
    request.fields['longitude'] = position.longitude.toString();
    request.fields['address'] = address;
    request.fields['shift'] = shift;
    
    // Tambahkan file foto
    request.files.add(
      await http.MultipartFile.fromPath(
        'photo_in', // Sesuaikan dengan key di backend
        imageFile.path,
      ),
    );

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamedResponse);
      
      if (!response.headers['content-type']!.contains('application/json')) {
          print('--- SERVER RESPONSE BUKAN JSON (CHECK IN) ---');
          print('Status Code: ${response.statusCode}');
          print('Response Body: ${response.body}');
          print('-------------------------------------------');
          throw Exception('Server memberikan respons yang tidak valid.');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) { // Check In biasanya mengembalikan status 201 Created
        return responseData;
      } else {
        print('Server Error Response (Check In): $responseData');
        String errorMessage = 'Gagal melakukan Check In.';
        if (responseData != null && responseData['messages'] is Map && responseData['messages']['error'] != null) {
          errorMessage = responseData['messages']['error'];
        }
        throw Exception(errorMessage);
      }
    } on TimeoutException catch (_) {
      throw Exception('Koneksi ke server timeout. Periksa jaringan Anda.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
  Future<Map<String, dynamic>> submitCheckOut(int userId, File imageFile, Position position) async {
  final url = Uri.parse('${_baseUrl}attendance/checkout');
  var request = http.MultipartRequest('POST', url);

  // Tambahkan field data
  request.fields['user_id'] = userId.toString();
  request.fields['latitude'] = position.latitude.toString();
  request.fields['longitude'] = position.longitude.toString();
  
  // Tambahkan file foto
  request.files.add(
    await http.MultipartFile.fromPath(
      'photo_out', 
      imageFile.path,
    ),
  );

  try {
    final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamedResponse);

          // Ini mencegah error jika server mengembalikan halaman error HTML
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
        // Cetak seluruh respons error untuk debugging
        print('Server Error Response: $responseData');
      String errorMessage = 'Gagal melakukan Check Out.';
        
        if (responseData != null && responseData['messages'] is Map && responseData['messages']['error'] != null) {
          errorMessage = responseData['messages']['error'];
        }
        
        throw Exception(errorMessage);
    }
  } on TimeoutException catch (_) {
      // Menangani error jika request terlalu lama
      throw Exception('Koneksi ke server timeout. Periksa jaringan Anda.');
    } catch (e) {
      // Menangani error koneksi atau parsing yang sudah diformat
      throw Exception(e.toString());
    }
}
Future<List<dynamic>> fetchAttendanceHistory(int userId) async {
    final url = Uri.parse('${_baseUrl}attendance/history/$userId');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Server Error (History): ${response.body}');
        throw Exception('Gagal memuat riwayat presensi.');
      }
    } on TimeoutException catch (_) {
      throw Exception('Koneksi ke server timeout.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}