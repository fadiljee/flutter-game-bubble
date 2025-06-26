// file: login_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'menu_screen.dart';
import 'dart:math';
// === SFX: 1. Impor paket audioplayers ===
import 'package:audioplayers/audioplayers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final nisnController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _controller;

  // === SFX: 2. Deklarasi AudioPlayer dan state volume ===
  final AudioPlayer _sfxPlayer = AudioPlayer();
  double _volume = 0.5; // Default volume

  // --- FUNGSI LOGIN DENGAN PENAMBAHAN SFX ---
  Future<void> _login() async {
    final nisn = nisnController.text.trim();
    if (nisn.isEmpty) {
      _playSound('audio/bubble-pop-7-351339.mp3'); // SFX untuk error
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NISN tidak boleh kosong')));
      return;
    }

    setState(() => _isLoading = true);

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'nisn': nisn});
    final url = Uri.parse('http://127.0.0.1:8000/api/login');
    
    String errorMessage = 'Terjadi kesalahan';
    http.Response? response;

    try {
      response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 15));
      
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final siswa = data['data_siswa'];
        final token = data['access_token'];

        if (siswa == null || token == null) {
          throw Exception('Struktur data dari server tidak sesuai harapan.');
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        // === Perbaikan penulisan key SharedPreferences ===
        await prefs.setString('nama_siswa', siswa['nama']); 
        await prefs.setInt('siswa_id', siswa['id']);

        // === SFX: Mainkan suara sukses sebelum navigasi ===
        _playSound('audio/bubble-pop-6-351337.mp3'); 

        // Tunggu sejenak agar suara sempat terdengar
        await Future.delayed(const Duration(milliseconds: 300));

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MenuScreen(playerName: siswa['nama'])));
        // Jangan panggil setState setelah navigasi
        return; 
      } else if (response.statusCode == 401) {
        errorMessage = 'NISN tidak ditemukan atau tidak valid.';
      } else {
        errorMessage = 'Login gagal. Status: ${response.statusCode}';
      }
    } on SocketException {
      errorMessage = 'Tidak dapat terhubung. Cek koneksi internet Anda.';
    } on TimeoutException {
      errorMessage = 'Server tidak merespon. Coba lagi nanti.';
    } on FormatException {
      errorMessage = 'Gagal memproses data dari server. Mungkin terjadi kesalahan pada server.';
    } catch (e) {
      errorMessage = 'Terjadi kesalahan internal pada aplikasi.';
      print('LOGIN ERROR: $e');
    }

    if (mounted) {
      // === SFX: Mainkan suara error untuk semua kondisi gagal ===
      _playSound('audio/bubble_pop.mp3');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      setState(() => _isLoading = false);
    }
  }
  
  // === SFX: 3. Fungsi helper untuk memainkan suara ===
  void _playSound(String soundAsset) {
    // Memainkan suara sesuai dengan pengaturan volume global
    if (_volume > 0) {
      _sfxPlayer.play(AssetSource(soundAsset), volume: _volume);
    }
  }

  // === SFX: 4. Fungsi untuk memuat volume dari penyimpanan ===
  Future<void> _loadVolume() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _volume = prefs.getDouble('gameVolume') ?? 0.5;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();
    
    // === SFX: 5. Konfigurasi player dan muat volume ===
    _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
    _loadVolume();
  }

  @override
  void dispose() {
    _controller.dispose();
    // === SFX: 6. Hapus resource player ===
    _sfxPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              Container(color: Colors.lightBlue[100]),
              _buildAnimatedBubble(color: Colors.lightBlue[200]!, size: 250, startOffset: Offset(MediaQuery.of(context).size.width - 150, -80), speed: 1.0),
              _buildAnimatedBubble(color: Colors.cyan.withOpacity(0.5), size: 400, startOffset: Offset(-100, MediaQuery.of(context).size.height - 250), speed: 0.7),
              child!,
            ],
          );
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  Text('Masuk', textAlign: TextAlign.center, style: GoogleFonts.nunito(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  Text('Gunakan NISN kamu ya!', textAlign: TextAlign.center, style: GoogleFonts.nunito(fontSize: 18, color: Colors.black54)),
                  const SizedBox(height: 60),
                  TextField(
                    controller: nisnController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(color: Colors.blue[900], fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'NISN',
                      hintStyle: GoogleFonts.nunito(color: Colors.blue[300]),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () {
                        // === SFX: Mainkan suara klik saat tombol ditekan ===
                        _playSound('audio/bubble_pop.mp3');
                        _login();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan[600], foregroundColor: Colors.white, shape: const StadiumBorder(), elevation: 5),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text('KONFIRMASI', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBubble({required Color color, required double size, required Offset startOffset, required double speed}) {
    final double verticalMovement = sin(_controller.value * 2 * pi * speed) * 25;
    return Transform.translate(
      offset: Offset(startOffset.dx, startOffset.dy + verticalMovement),
      child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
    );
  }
}