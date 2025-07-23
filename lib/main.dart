import 'package:flutter/material.dart';
import 'package:absensi/screens/splash_screen.dart'; // Ganti import
import 'package:absensi/screens/wfa_login_screen.dart';
import 'package:absensi/screens/wfo_login_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Presensi',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      routes: {
        '/wfa-login': (context) => const WfaLoginScreen(),
        '/wfo-login': (context) => const WfoLoginScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}