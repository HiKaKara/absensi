// lib/main.dart

import 'package:flutter/material.dart';
import 'package:absensi/screens/splash_screen.dart';
import 'package:absensi/screens/wfa_login_screen.dart';
import 'package:absensi/screens/wfo_login_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // <-- TAMBAHKAN IMPORT INI

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

      // --- TAMBAHKAN PROPERTI DI BAWAH INI UNTUK LOKALISASI ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Bahasa Indonesia
        Locale('en', 'US'), // Bahasa Inggris sebagai fallback
      ],
      locale: const Locale('id', 'ID'), // Atur default locale ke Indonesia
      // ---------------------------------------------------------

      home: const SplashScreen(),
      routes: {
        '/wfa-login': (context) => const WfaLoginScreen(),
        '/wfo-login': (context) => const WfoLoginScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}