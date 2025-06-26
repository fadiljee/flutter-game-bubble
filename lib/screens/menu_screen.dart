// file: menu_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
// === PERUBAHAN: Impor http untuk cek API ===
import 'package:http/http.dart' as http;
import 'dart:convert';

// Impor halaman-halaman lain
import 'materi_screen.dart';
import 'play_screen.dart';
import 'soal_screen.dart';
import 'game_leaderboard_screen.dart';

class MenuScreen extends StatefulWidget {
  final String playerName;

  const MenuScreen({super.key, required this.playerName});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _bgController;
  late AnimationController _menuController;
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  double _volume = 0.5;

  // === PERUBAHAN: State untuk status kunci game ===
  bool _isGameUnlocked = false;
  bool _isLoadingStatus = true; // Untuk menampilkan loading saat cek status

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bgController = AnimationController(duration: const Duration(seconds: 25), vsync: this)..repeat();
    _menuController = AnimationController(duration: const Duration(seconds: 4), vsync: this)..repeat(reverse: true);
    _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    _initializeAudio();

    // === PERUBAHAN: Cek status kunci game saat layar dibuka ===
    _checkGameUnlockStatus();
  }

  Future<void> _initializeAudio() async {
    await _loadVolume();
    _playBackgroundMusic();
  }

  // === PERUBAHAN: Fungsi baru untuk mengecek status unlock game ===
  Future<void> _checkGameUnlockStatus() async {
    setState(() { _isLoadingStatus = true; });

    try {
      // 1. Dapatkan daftar materi yang sudah selesai dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final completedIds = prefs.getStringList('completed_materi_ids') ?? [];

      // 2. Dapatkan jumlah total materi dari API
      String? token = prefs.getString('access_token');
      if (token == null) throw Exception("Token not found");

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/materi'), // Sesuaikan URL
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List materiList = jsonDecode(response.body);
        final int totalMateri = materiList.length;

        // 3. Bandingkan. Game terbuka jika jumlah selesai >= jumlah total
        // dan total materi tidak nol (untuk kasus materi belum ada)
        if (totalMateri > 0 && completedIds.length >= totalMateri) {
          setState(() {
            _isGameUnlocked = true;
          });
        } else {
           setState(() {
            _isGameUnlocked = false;
          });
        }
      } else {
        // Jika API gagal, anggap game terkunci
        setState(() { _isGameUnlocked = false; });
      }
    } catch (e) {
      // Jika ada error (misal, tidak ada koneksi), anggap game terkunci
      setState(() { _isGameUnlocked = false; });
      print("Error checking game status: $e");
    } finally {
      setState(() { _isLoadingStatus = false; });
    }
  }

  // ... (dispose, didChangeAppLifecycleState, audio functions tidak berubah) ...
    @override
  void dispose() {
    _bgController.dispose();
    _menuController.dispose();
    _musicPlayer.stop();
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _musicPlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_volume > 0) {
         _musicPlayer.resume();
      }
    }
  }

  Future<void> _loadVolume() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _volume = prefs.getDouble('gameVolume') ?? 0.5;
    });
  }

  Future<void> _setVolume(double newVolume) async {
    setState(() {
      _volume = newVolume;
    });
    await _musicPlayer.setVolume(newVolume); 
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('gameVolume', newVolume);
  }

  void _playButtonTapSound({bool isError = false}) {
    if (_volume > 0) {
      final sound = isError ? 'audio/error_sound.mp3' : 'audio/bubble_pop.mp3';
      _sfxPlayer.play(AssetSource(sound), volume: _volume);
    }
  }
  
  Future<void> _playBackgroundMusic() async {
    await _musicPlayer.setVolume(_volume);
    await _musicPlayer.play(AssetSource('audio/music_4.mp3'));
  }

  void _showVolumeDialog() {
    _playButtonTapSound(); 
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Atur Volume',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        _volume == 0 ? Icons.volume_off_rounded : _volume > 0.5 ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                        color: Colors.blue.shade400,
                      ),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          min: 0.0,
                          max: 1.0,
                          activeColor: Colors.blue.shade400,
                          inactiveColor: Colors.blue.shade100,
                          onChanged: (newVolume) {
                            setDialogState(() {
                              _setVolume(newVolume);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Tutup', style: GoogleFonts.poppins(color: Colors.blue.shade500, fontWeight: FontWeight.bold)),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF81D4FA),
        child: Stack(
          children: [
            // ... (background dan header tidak berubah) ...
            _buildAnimatedBgBubble(color: Colors.lightBlue.shade300, size: 220, startOffset: const Offset(-50, 100), speed: 0.8),
            _buildAnimatedBgBubble(color: Colors.cyan.shade200, size: 300, startOffset: Offset(MediaQuery.of(context).size.width - 200, 250), speed: 0.6),
            _buildAnimatedBgBubble(color: Colors.white.withOpacity(0.7), size: 180, startOffset: Offset(50, MediaQuery.of(context).size.height - 150), speed: 1.1),
            _buildAnimatedBgBubble(color: Colors.yellow.shade200.withOpacity(0.5), size: 60, startOffset: Offset(MediaQuery.of(context).size.width - 70, 80), speed: 1.5),
            _buildAnimatedBgBubble(color: Colors.pink.shade100.withOpacity(0.6), size: 80, startOffset: const Offset(20, 300), speed: 1.2),

            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Halo, ${widget.playerName}!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: const [Shadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2))],
                          ),
                        ),
                        const SizedBox(height: 8),
                         Text(
                          'Siap untuk petualangan hari ini?',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildBubbleMenuItem(
                              animation: _menuController,
                              icon: Icons.auto_stories_rounded,
                              title: 'Materi',
                              color: const Color(0xFF66BB6A),
                              onTap: () async { // Jadikan async
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => const MateriScreen()));
                                // Setelah kembali dari materi, cek ulang status game
                                _checkGameUnlockStatus();
                              },
                            ),
                            // === PERUBAHAN: Kirim status unlock ke tombol Mainkan ===
                            _buildBubbleMenuItem(
                              animation: _menuController,
                              icon: Icons.sports_esports_rounded,
                              title: 'Mainkan',
                              color: const Color(0xFFFFA726),
                              isEnabled: _isLoadingStatus ? false : _isGameUnlocked, // Disable saat loading
                              isLoading: _isLoadingStatus, // Kirim status loading
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayScreen())),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                             _buildBubbleMenuItem(
                              animation: _menuController,
                              icon: Icons.edit_note_rounded,
                              title: 'Soal',
                              color: const Color(0xFFAB47BC),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SoalScreen())),
                            ),
                            _buildBubbleMenuItem(
                              animation: _menuController,
                              icon: Icons.emoji_events_rounded,
                              title: 'Peringkat',
                              color: const Color(0xFF29B6F6),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GameLeaderboardScreen())),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            
            Positioned(
              top: 45,
              right: 15,
              child: IconButton(
                icon: Icon(
                  _volume > 0.5 ? Icons.volume_up_rounded : (_volume > 0 ? Icons.volume_down_rounded : Icons.volume_off_rounded),
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: _showVolumeDialog,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.15),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBgBubble({required Color color, required double size, required Offset startOffset, required double speed}) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        final verticalMovement = sin(_bgController.value * 2 * pi * speed) * 20;
        final horizontalMovement = cos(_bgController.value * 2 * pi * speed) * 10;
        return Transform.translate(
          offset: Offset(startOffset.dx + horizontalMovement, startOffset.dy + verticalMovement),
          child: child,
        );
      },
      child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
    );
  }

  // === PERUBAHAN: Modifikasi widget menu untuk menangani status terkunci ===
  Widget _buildBubbleMenuItem({
    required Animation<double> animation,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isEnabled = true, // Defaultnya tombol aktif
    bool isLoading = false, // Default tidak loading
  }) {
    final anim = CurvedAnimation(parent: animation, curve: Curves.elasticInOut);
    final buttonColor = isEnabled ? color : Colors.grey.shade600;
    final iconToShow = isLoading ? null : (isEnabled ? icon : Icons.lock_rounded);

    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final scale = isEnabled ? (1.0 + (anim.value * 0.1)) : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: () {
          if (isLoading) return; // Jangan lakukan apa-apa jika sedang loading

          if (isEnabled) {
            _playButtonTapSound();
            _musicPlayer.pause();
            onTap();
          } else {
            _playButtonTapSound(isError: true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red.shade400,
                content: Text(
                  'Selesaikan semua materi terlebih dahulu ya!',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 115, height: 115,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 5),
                gradient: RadialGradient(
                  colors: [buttonColor.withOpacity(0.7), buttonColor],
                  center: const Alignment(-0.5, -0.5),
                  radius: 1.0,
                  stops: const [0.0, 1.0],
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 8))],
              ),
              child: Center(
                child: isLoading 
                ? const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 4,))
                : Icon(iconToShow, size: 60, color: Colors.white)
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: buttonColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
