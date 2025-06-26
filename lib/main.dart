// file: main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 1. Impor paket services
import 'screens/start_screen.dart';   // Pastikan path ini sesuai dengan struktur proyek Anda

// 2. Jadikan fungsi main menjadi async
void main() async {
  // 3. Pastikan semua plugin Flutter siap sebelum menjalankan kode lain
  WidgetsFlutterBinding.ensureInitialized();

  // 4. Atur dan kunci orientasi aplikasi hanya untuk potret (tegak)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 5. Jalankan aplikasi seperti biasa
  runApp(BubbleMathApp());
}

class BubbleMathApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bubble Math',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Penggunaan font kustom Anda sudah bagus.
        // Pastikan font 'ComicSans' sudah didaftarkan di pubspec.yaml
        fontFamily: 'ComicSans',
      ),
      home: StartScreen(),
    );
  }
}