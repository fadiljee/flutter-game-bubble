// file: game_leaderboard_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// === AUDIO: 1. Impor paket yang diperlukan ===
import 'package:audioplayers/audioplayers.dart';

// Palet Warna (tidak berubah)
const Color kBgDark1 = Color(0xFF1D2B4A);
const Color kBgDark2 = Color(0xFF3A1C71);
const Color kGoldColor = Color(0xFFFFD700);
const Color kSilverColor = Color(0xFFC0C0C0);
const Color kBronzeColor = Color(0xFFCD7F32);

class GameLeaderboardScreen extends StatefulWidget {
  const GameLeaderboardScreen({Key? key}) : super(key: key);

  @override
  _GameLeaderboardScreenState createState() => _GameLeaderboardScreenState();
}

// === AUDIO: 2. Tambahkan 'WidgetsBindingObserver' untuk siklus hidup aplikasi ===
class _GameLeaderboardScreenState extends State<GameLeaderboardScreen>
    with WidgetsBindingObserver {
  late Future<List<dynamic>> _leaderboardFuture;
  int? _mySiswaId;

  // === AUDIO: 3. Deklarasi player dan state volume ===
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  double _volume = 0.5;

  @override
  void initState() {
    super.initState();
    // === AUDIO: Tambahkan observer dan konfigurasikan player ===
    WidgetsBinding.instance.addObserver(this);
    _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
    _musicPlayer.setReleaseMode(ReleaseMode.loop);

    _initializeScreen();
  }

  // === AUDIO: 4. Gabungkan proses inisialisasi di satu tempat ===
  Future<void> _initializeScreen() async {
    await _loadVolume();
    _playBackgroundMusic(); // Musik dimulai segera
    _loadData(); // Memuat data leaderboard
  }

  // === AUDIO: 5. Kumpulan fungsi untuk mengelola audio ===
  Future<void> _loadVolume() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _volume = prefs.getDouble('gameVolume') ?? 0.5;
    });
  }

  Future<void> _playBackgroundMusic() async {
    if (_volume > 0) {
      await _musicPlayer.setVolume(_volume);
      // Ganti dengan file musik Anda untuk leaderboard (misal: musik epik)
      await _musicPlayer.play(AssetSource('audio/music_2.mp3'));
    }
  }

  void _playSoundEffect(String soundAsset) {
    if (_volume > 0) {
      _sfxPlayer.play(AssetSource(soundAsset), volume: _volume);
    }
  }

  // === AUDIO: 6. Kelola state musik saat aplikasi di-pause/resume ===
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _musicPlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_volume > 0) {
        _musicPlayer.resume();
      }
    }
  }

  @override
  void dispose() {
    // === AUDIO: Hentikan dan hapus semua resource audio ===
    WidgetsBinding.instance.removeObserver(this);
    _musicPlayer.stop();
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  void _loadData() {
    final prefsFuture = SharedPreferences.getInstance();
    prefsFuture.then((prefs) {
      setState(() {
        _mySiswaId = prefs.getInt('siswa_id');
        _leaderboardFuture = _fetchLeaderboard();
      });
    });
  }

  Future<List<dynamic>> _fetchLeaderboard() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login ulang.');
    }

    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/leaderboard'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Gagal memuat leaderboard. Status: ${response.statusCode}');
    }
  }

  String _formatWaktu(int totalDetik) {
    int menit = totalDetik ~/ 60;
    int detik = totalDetik % 60;
    String menitStr = menit.toString().padLeft(2, '0');
    String detikStr = detik.toString().padLeft(2, '0');
    return '$menitStr:$detikStr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kBgDark1, kBgDark2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 20, 20, 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                      // === AUDIO: 7. Tambahkan SFX pada tombol kembali ===
                      onPressed: () {
                        _playSoundEffect('audio/bubble_pop.mp3');
                        Navigator.of(context).pop();
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Papan Peringkat',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // FutureBuilder untuk menampilkan data
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _leaderboardFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.white));
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.white70)));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'Jadilah yang pertama di leaderboard!',
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 16),
                        ),
                      );
                    }

                    final players = snapshot.data!;

                    return RefreshIndicator(
                      // === AUDIO: 8. Tambahkan SFX saat refresh ===
                      onRefresh: () async {
                        _playSoundEffect(
                            'audio/bubble_pop.mp3'); // Ganti dengan nama file sfx refresh Anda
                        _loadData();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final player = players[index];
                          final rank = index + 1;
                          final bool isCurrentUser =
                              player['siswa_id'] == _mySiswaId;

                          return _buildRankTile(
                            rank: rank,
                            player: player,
                            isCurrentUser: isCurrentUser,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankTile(
      {required int rank,
      required dynamic player,
      required bool isCurrentUser}) {
    final siswa = player['siswa'] ?? {'nama': 'Tanpa Nama'};
    final String name = siswa['nama'];
    final String score = _formatWaktu(player['time']);

    Color rankColor = Colors.white70;
    FontWeight rankFontWeight = FontWeight.bold;
    if (rank == 1) rankColor = kGoldColor;
    if (rank == 2) rankColor = kSilverColor;
    if (rank == 3) rankColor = kBronzeColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Colors.white.withOpacity(0.2)
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border:
            isCurrentUser ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: rankFontWeight,
                color: rankColor,
                shadows: rank <= 3
                    ? [Shadow(color: rankColor.withOpacity(0.5), blurRadius: 5)]
                    : [],
              ),
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 22,
            backgroundColor: rankColor.withOpacity(0.5),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF3A1C71),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            score,
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
