// file: soal_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart'; // === AUDIO: 1. Impor audioplayers

// Ganti dengan halaman login dan menu Anda yang sebenarnya
import 'login_screen.dart';
import 'menu_screen.dart';

// Palet Warna (tidak berubah)
const Color kBgDark1 = Color(0xFF1D2B4A);
const Color kBgDark2 = Color(0xFF3A1C71);
const Color kAccentColor = Color(0xFFF32179);
const Color kCorrectColor = Color(0xFF16D7A7);
const Color kWrongColor = Color(0xFFF45B69);
const Color kNeutralColor = Color(0xFF2E406F);

class SoalScreen extends StatefulWidget {
  const SoalScreen({Key? key}) : super(key: key);

  @override
  State<SoalScreen> createState() => _SoalScreenState();
}

class _SoalScreenState extends State<SoalScreen> {
  List<dynamic> kuisList = [];
  int currentIndex = 0;
  int waktuSisa = 1;
  int totalWaktu = 1;
  Timer? timer;
  DateTime startTime = DateTime.now();
  String? selectedAnswer;
  bool showAnswerResult = false;
  bool isProcessing = false;

  int _correctCount = 0;
  int _wrongCount = 0;

  String? token;
  int? siswaId;
  String? playerName;

  // === AUDIO: 2. Deklarasi AudioPlayer dan state volume ===
  final AudioPlayer _sfxPlayer = AudioPlayer();
  double _volume = 0.5;

  @override
  void initState() {
    super.initState();
    // === AUDIO: Optimasi player untuk SFX ===
    _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
    _loadSessionAndData();
  }

  Future<void> _loadSessionAndData() async {
    await _loadVolume(); // Muat volume terlebih dahulu
    await _loadTokenAndFetchKuis();
  }

  // === AUDIO: 3. Fungsi untuk memuat volume dari penyimpanan ===
  Future<void> _loadVolume() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _volume = prefs.getDouble('gameVolume') ?? 0.5;
    });
  }

  // === AUDIO: 4. Fungsi untuk menyimpan volume ===
  Future<void> _setVolume(double newVolume) async {
    setState(() {
      _volume = newVolume;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('gameVolume', newVolume);
  }

  // === AUDIO: 5. Fungsi helper untuk memainkan efek suara ===
  void _playSoundEffect(String soundAsset) {
    if (_volume > 0) {
      _sfxPlayer.play(AssetSource(soundAsset), volume: _volume);
    }
  }

  Future<void> _loadTokenAndFetchKuis() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('access_token');
    siswaId = prefs.getInt('siswa_id');
    playerName = prefs.getString('nama_siswa');

    if (token == null || siswaId == null) {
      _goToLogin();
      return;
    }
    await _fetchKuis();
  }

  void _goToLogin() {
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _sfxPlayer.dispose(); // Jangan lupa dispose player
    super.dispose();
  }

  Future<void> _fetchKuis() async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/kuis'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        kuisList = data['kuis'] ?? [];
        
        // === PERUBAHAN: Acak urutan soal ===
        if (kuisList.isNotEmpty) {
          kuisList.shuffle(); // Baris ini akan mengacak daftar soal
          _setupSoal();
        }
      });
    } else if (response.statusCode == 401) {
      _goToLogin();
    } else {}
  }

  void _setupSoal() {
    setState(() {
      waktuSisa = kuisList[currentIndex]['waktu_pengerjaan'] ?? 60;
      totalWaktu = waktuSisa;
      startTime = DateTime.now();
      selectedAnswer = null;
      showAnswerResult = false;
      isProcessing = false;
      _startTimer();
    });
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (waktuSisa > 0) {
        if (mounted) setState(() => waktuSisa--);
      } else {
        t.cancel();
        _pilihJawaban('TIMEOUT');
      }
    });
  }

  void _nextSoal() {
    if (currentIndex < kuisList.length - 1) {
      setState(() {
        currentIndex++;
        _setupSoal();
      });
    } else {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => KuisSelesaiScreen(
                    correctCount: _correctCount,
                    wrongCount: _wrongCount,
                    totalQuestions: kuisList.length,
                    playerName: playerName ?? "Siswa",
                    volume:
                        _volume, // === AUDIO: Kirim data volume ke layar hasil
                  )));
    }
  }

  Future<void> _pilihJawaban(String pilihan) async {
    if (isProcessing) return;
    isProcessing = true;
    timer?.cancel();

    String jawabanBenar = kuisList[currentIndex]['jawaban_benar'];
    if (pilihan == 'TIMEOUT' || pilihan != jawabanBenar) {
      // === AUDIO: Mainkan suara jawaban salah ===
      _playSoundEffect('audio/bubble_merge.mp3');
      setState(() => _wrongCount++);
    } else {
      // === AUDIO: Mainkan suara jawaban benar ===
      _playSoundEffect('audio/level_win.mp3');
      setState(() => _correctCount++);
    }

    setState(() {
      selectedAnswer = pilihan;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    DateTime endTime = DateTime.now();
    int waktuDipakai = endTime.difference(startTime).inSeconds;

    setState(() {
      showAnswerResult = true;
    });

    await _sendHasil(waktuDipakai, pilihan);
    await Future.delayed(const Duration(milliseconds: 1500));
    _nextSoal();
  }

  Future<void> _sendHasil(int waktu, String pilihan) async {
    if (pilihan == 'TIMEOUT') return;
    if (token == null || siswaId == null) return;
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/hasil-kuis'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'siswa_id': siswaId,
        'kuis_id': kuisList[currentIndex]['id'],
        'jawaban_user': pilihan,
        'waktu': waktu,
      }),
    );
    if (response.statusCode == 401) _goToLogin();
  }

  Future<void> _showExitConfirmationDialog() async {
    _playSoundEffect('audio/bubble_pop.mp3'); // Suara klik
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kBgDark2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Keluar dari Kuis?',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text('Progres kuis Anda saat ini tidak akan tersimpan.',
              style: GoogleFonts.poppins(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: Text('Batal',
                  style: GoogleFonts.poppins(color: Colors.white70)),
              onPressed: () {
                _playSoundEffect('audio/bubble_pop.mp3');
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Ya, Keluar',
                  style: GoogleFonts.poppins(
                      color: kWrongColor, fontWeight: FontWeight.bold)),
              onPressed: () {
                _playSoundEffect('audio/bubble_pop.mp3');
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // === AUDIO: 6. Dialog untuk mengatur volume ===
  void _showVolumeDialog() {
    _playSoundEffect('audio/bubble_pop.mp3');
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: kBgDark2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text('Atur Volume',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
              content: Row(
                children: [
                  Icon(_volume == 0 ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white70),
                  Expanded(
                    child: Slider(
                      value: _volume,
                      min: 0.0,
                      max: 1.0,
                      activeColor: kAccentColor,
                      inactiveColor: kNeutralColor,
                      onChanged: (newVolume) {
                        setDialogState(() {
                          _setVolume(newVolume);
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kuisList.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [kBgDark1, kBgDark2])),
        child:
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    var soal = kuisList[currentIndex];
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [kBgDark1, kBgDark2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 32),
                _buildQuestionCard(soal['pertanyaan']),
                const SizedBox(height: 32),
                _buildAnswerList(soal),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white70, size: 30),
              onPressed: _showExitConfirmationDialog,
            ),
            Expanded(
              child: Text(
                "Soal ${currentIndex + 1}/${kuisList.length}",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
              ),
            ),
            // === AUDIO: 7. Tambahkan tombol volume di header ===
            IconButton(
              icon: Icon(
                  _volume > 0
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  color: Colors.white70,
                  size: 28),
              onPressed: _showVolumeDialog,
            ),
            Icon(Icons.timer_outlined, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text("$waktuSisa dtk",
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (totalWaktu - waktuSisa) / totalWaktu,
            backgroundColor: kNeutralColor,
            valueColor: const AlwaysStoppedAnimation<Color>(kAccentColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(String pertanyaan) => Text(pertanyaan,
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
          fontSize: 24,
          color: Colors.white,
          fontWeight: FontWeight.w600,
          height: 1.5));
  Widget _buildAnswerList(dynamic soal) => Expanded(
          child: ListView(children: [
        _buildAnswerCard('A', soal['jawaban_a'], soal['jawaban_benar']),
        _buildAnswerCard('B', soal['jawaban_b'], soal['jawaban_benar']),
        _buildAnswerCard('C', soal['jawaban_c'], soal['jawaban_benar']),
        _buildAnswerCard('D', soal['jawaban_d'], soal['jawaban_benar'])
      ]));
  Widget _buildAnswerCard(String label, String text, String jawabanBenar) {
    bool isSelected = selectedAnswer == label;
    Color borderColor = kNeutralColor;
    Color bgColor = Colors.transparent;
    if (showAnswerResult) {
      if (label == jawabanBenar) {
        borderColor = kCorrectColor;
        bgColor = kCorrectColor.withOpacity(0.15);
      } else if (isSelected) {
        borderColor = kWrongColor;
        bgColor = kWrongColor.withOpacity(0.15);
      }
    } else if (isSelected) {
      borderColor = kAccentColor;
      bgColor = kAccentColor.withOpacity(0.1);
    }
    return GestureDetector(
        onTap: () => _pilihJawaban(label),
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 2)),
            child: Row(children: [
              Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 2)),
                  child: Center(
                      child: Text(label,
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)))),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(text,
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 16)))
            ])));
  }
}

class KuisSelesaiScreen extends StatefulWidget {
  final int correctCount;
  final int wrongCount;
  final int totalQuestions;
  final String playerName;
  final double volume; // === AUDIO: Terima data volume

  const KuisSelesaiScreen({
    Key? key,
    required this.correctCount,
    required this.wrongCount,
    required this.totalQuestions,
    required this.playerName,
    required this.volume, // === AUDIO: Tambahkan di constructor
  }) : super(key: key);

  @override
  State<KuisSelesaiScreen> createState() => _KuisSelesaiScreenState();
}

class _KuisSelesaiScreenState extends State<KuisSelesaiScreen> {
  late ConfettiController _confettiController;
  // === AUDIO: Player untuk layar hasil ===
  final AudioPlayer _sfxPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _confettiController.play();

    // === AUDIO: Mainkan suara kemenangan/selesai ===
    _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
    if (widget.volume > 0) {
      _sfxPlayer.play(AssetSource('audio/complete.mp3'),
          volume: widget.volume); // Ganti dengan nama file suara Anda
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _sfxPlayer.dispose(); // Jangan lupa dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [kBgDark1, kBgDark2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      size: 120, color: Colors.amber),
                  const SizedBox(height: 24),
                  Text('Kuis Selesai!',
                      style: GoogleFonts.poppins(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 12),
                  Text('Lihat hasilmu di bawah ini, ${widget.playerName}!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 18, color: Colors.white70)),
                  Container(
                    margin: const EdgeInsets.only(top: 32, left: 40, right: 40),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildStatRow(
                            icon: Icons.check_circle_outline,
                            label: 'Benar',
                            value: '${widget.correctCount}',
                            color: kCorrectColor),
                        const Divider(color: Colors.white24, height: 24),
                        _buildStatRow(
                            icon: Icons.highlight_off_rounded,
                            label: 'Salah',
                            value: '${widget.wrongCount}',
                            color: kWrongColor),
                        const Divider(color: Colors.white24, height: 24),
                        _buildStatRow(
                            icon: Icons.functions_rounded,
                            label: 'Total Soal',
                            value: '${widget.totalQuestions}',
                            color: Colors.white70),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () {
                      // === AUDIO: Suara klik saat kembali ke menu ===
                      if (widget.volume > 0) {
                        _sfxPlayer.play(AssetSource('audio/bubble_pop.mp3'),
                            volume: widget.volume);
                      }
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                MenuScreen(playerName: widget.playerName)),
                        (route) => false,
                      );
                    },
                    child: Text('Kembali ke Menu',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ],
              ),
            ),
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                kAccentColor,
                Colors.green,
                Colors.blue,
                Colors.orange,
                Colors.purple
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
      {required IconData icon,
      required String label,
      required String value,
      required Color color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(label,
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
          ],
        ),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ],
    );
  }
}
