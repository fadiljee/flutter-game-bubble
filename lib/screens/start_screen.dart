// file: start_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'dart:math'; // Impor untuk matematika

// 1. Ubah menjadi StatefulWidget
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

// 2. Tambahkan 'with SingleTickerProviderStateMixin'
class _StartScreenState extends State<StartScreen> with SingleTickerProviderStateMixin {
  // 3. Deklarasikan AnimationController
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 4. Inisialisasi controller
    _controller = AnimationController(
      duration: const Duration(seconds: 20), // Durasi satu siklus animasi
      vsync: this,
    )..repeat(); // Langsung mulai dan ulangi animasi
  }

  @override
  void dispose() {
    _controller.dispose(); // 5. Hentikan controller saat widget dihancurkan
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        // 6. Gunakan AnimatedBuilder untuk mendengarkan perubahan controller
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              Container(color: Colors.lightBlue[100]),
              
              // 7. Buat gelembung bergerak dengan Transform.translate
              _buildAnimatedBubble(
                color: Colors.lightBlue[200]!,
                size: 250,
                startOffset: const Offset(-100, -100),
                speed: 0.8,
              ),
              _buildAnimatedBubble(
                color: Colors.cyan.withOpacity(0.5),
                size: 350,
                startOffset: Offset(MediaQuery.of(context).size.width - 230, 150),
                speed: 0.6,
              ),
               _buildAnimatedBubble(
                color: Colors.white.withOpacity(0.7),
                size: 200,
                startOffset: Offset(50, MediaQuery.of(context).size.height - 120),
                 speed: 1.2,
              ),
              _buildAnimatedBubble(
                color: Colors.white.withOpacity(0.6),
                size: 80,
                startOffset: Offset(MediaQuery.of(context).size.width - 120, 120),
                speed: 0.5,
              ),

              // Konten utama tidak berubah
              child!, 
            ],
          );
        },
        // 8. Child ini adalah konten statis yang tidak perlu di-rebuild
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bubble_chart_rounded,
                  size: 120,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Text('Bubble Math', style: GoogleFonts.nunito(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 80),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue[800],
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                    elevation: 5,
                  ),
                  child: Text('START', style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Widget helper untuk gelembung yang sudah dianimasikan
  Widget _buildAnimatedBubble({
    required Color color,
    required double size,
    required Offset startOffset,
    required double speed,
  }) {
    // Menghitung pergerakan vertikal berdasarkan nilai controller
    // sin() digunakan untuk membuat gerakan naik turun yang halus
    final double verticalMovement = sin(_controller.value * 2 * pi * speed) * 30; 
    
    return Transform.translate(
      offset: Offset(startOffset.dx, startOffset.dy + verticalMovement),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}