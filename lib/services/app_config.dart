class AppConfig {
  // Gunakan IP ini untuk koneksi dari Android Emulator ke server di komputer host.
  static const String _emulatorIp = "10.0.2.2";

  // Ganti dengan IP WiFi komputer jika akan testing di HP fisik.
  // Contoh: static const String _physicalDeviceIp = "10.14.72.135";
  static const String _activeIp = _emulatorIp;

  // Base URL untuk semua request API
  static const String baseUrl = 'http://$_activeIp:8080/api/';

  // Base URL untuk path gambar
  static const String imageUrlBase = 'http://$_activeIp:8080/uploads/';
}