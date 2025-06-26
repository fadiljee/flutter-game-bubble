// file: game_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';

// Impor halaman lain (tidak berubah)
import 'game_leaderboard_screen.dart';

class GameScreen extends StatefulWidget {
  final int stage;
  final int level;

  const GameScreen({super.key, required this.stage, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Semua state dan fungsi logika (initState, dispose, _playMusic, dll) tidak berubah.
  // ... (kode dari baris 37 hingga 286 dibiarkan sama)
  final Random _random = Random();
  late AnimationController _bubbleAnimationController;

  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  double _volume = 0.5;

  int _currentQuestionNumber = 1;
  int _score = 0;
  int _correctAnswersCount = 0;
  int _incorrectAttempts = 0;

  Timer? _gameTimer;
  int _elapsedSeconds = 0;

  String _operatorSymbol = '+';
  int _number1 = 0;
  int _number2 = 0;
  int _correctAnswer = 0;

  int? _leftBoxValue;
  int? _rightBoxValue;
  List<int> _availableNumbers = [];

  Color _feedbackColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);

    _bubbleAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _loadVolumeAndStartGame();
  }

  Future<void> _loadVolumeAndStartGame() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _volume = prefs.getDouble('gameVolume') ?? 0.5;
    });
    _startGame();
    _playMusic();
  }

  Future<void> _playMusic() async {
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(_volume);
    await _musicPlayer.play(AssetSource('audio/music_1.mp3'));
  }

  void _playSoundEffect(String soundAsset) {
    if (_volume > 0) {
      _sfxPlayer.play(AssetSource(soundAsset), volume: _volume);
    }
  }

  Future<void> _setVolume(double newVolume) async {
    setState(() {
      _volume = newVolume;
    });
    await _musicPlayer.setVolume(_volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('gameVolume', _volume);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final bool isMuted = _volume == 0;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _musicPlayer.pause();
    } else if (state == AppLifecycleState.resumed && !isMuted) {
      _musicPlayer.resume();
    }
  }

  @override
  void dispose() {
    _bubbleAnimationController.dispose();
    _gameTimer?.cancel();
    _musicPlayer.stop();
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startGame() {
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      _currentQuestionNumber = 1;
      _score = 0;
      _correctAnswersCount = 0;
      _incorrectAttempts = 0;
      _elapsedSeconds = 0;
    });
    _startGameTimer();
    _generateQuestion();
    if (_volume > 0) {
      _musicPlayer.resume();
    }
  }

  void _startGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _generateQuestion() {
    setState(() {
      _leftBoxValue = null;
      _rightBoxValue = null;
      _feedbackColor = Colors.transparent;
    });

    List<String> operators;
    if (_currentQuestionNumber <= 10) {
      operators = ['+', '-'];
    } else if (_currentQuestionNumber <= 20) {
      operators = ['*', '/'];
    } else {
      operators = ['+', '-', '*', '/'];
    }
    _operatorSymbol = operators[_random.nextInt(operators.length)];

    int maxNumber = 10 + (_currentQuestionNumber);

    if (_operatorSymbol == '+') {
      _number1 = _random.nextInt(maxNumber) + 1;
      _number2 = _random.nextInt(maxNumber) + 1;
      _correctAnswer = _number1 + _number2;
    } else if (_operatorSymbol == '-') {
      _number1 = _random.nextInt(maxNumber) + 5;
      _number2 = _random.nextInt(_number1) + 1;
      _correctAnswer = _number1 - _number2;
    } else if (_operatorSymbol == '*') {
      _number1 = _random.nextInt(10) + 1;
      _number2 = _random.nextInt(10) + 1;
      _correctAnswer = _number1 * _number2;
    } else if (_operatorSymbol == '/') {
      _number2 = _random.nextInt(9) + 2;
      _correctAnswer = _random.nextInt(10) + 1;
      _number1 = _number2 * _correctAnswer;
    }

    _availableNumbers = [_number1, _number2];

    int numberOfBubbles;
    if (_currentQuestionNumber <= 10) {
      numberOfBubbles = 5;
    } else if (_currentQuestionNumber <= 20) {
      numberOfBubbles = 6;
    } else {
      numberOfBubbles = 7;
    }

    while (_availableNumbers.length < numberOfBubbles) {
      int wrongNumber = _random.nextInt(maxNumber > 0 ? maxNumber : 1) + 1;
      if (!_availableNumbers.contains(wrongNumber) &&
          wrongNumber > 0 &&
          wrongNumber != _correctAnswer) {
        _availableNumbers.add(wrongNumber);
      }
    }
    _availableNumbers.shuffle();
  }

  void _onAcceptToAnswerBox(int boxIndex, int draggedNumber) {
    _playSoundEffect('audio/bubble_merge.mp3');

    setState(() {
      if (boxIndex == 0) _leftBoxValue = draggedNumber;
      if (boxIndex == 1) _rightBoxValue = draggedNumber;
      _availableNumbers.remove(draggedNumber);
    });

    if (_leftBoxValue != null && _rightBoxValue != null) {
      _checkAnswer();
    }
  }

  void _returnNumberToPool(int number) {
    setState(() {
      if (_leftBoxValue == number) _leftBoxValue = null;
      if (_rightBoxValue == number) _rightBoxValue = null;
      if (!_availableNumbers.contains(number)) {
        _availableNumbers.add(number);
      }
    });
  }

  void _checkAnswer() {
    bool isCorrect = false;

    if (_leftBoxValue != null && _rightBoxValue != null) {
      int val1 = _leftBoxValue!;
      int val2 = _rightBoxValue!;

      if (_operatorSymbol == '+' || _operatorSymbol == '*') {
        if ((val1 == _number1 && val2 == _number2) ||
            (val1 == _number2 && val2 == _number1)) {
          isCorrect = true;
        }
      } else {
        if (val1 == _number1 && val2 == _number2) {
          isCorrect = true;
        }
      }
    }

    if (isCorrect) {
      _playSoundEffect('audio/bubble_pop.mp3');
      setState(() {
        _score += 10;
        _correctAnswersCount++;
        _feedbackColor = Colors.greenAccent.shade400;
      });
      Future.delayed(const Duration(milliseconds: 900), () {
        if (_currentQuestionNumber < 30) {
          setState(() {
            _currentQuestionNumber++;
          });
          _generateQuestion();
        } else {
          _handleGameEnd();
        }
      });
    } else {
      _playSoundEffect('audio/bubble-pop-6-351337.mp3');
      setState(() {
        _incorrectAttempts++;
        _feedbackColor = Colors.redAccent.shade400;
      });
      Future.delayed(const Duration(milliseconds: 900), () {
        setState(() {
          if (_leftBoxValue != null) _availableNumbers.add(_leftBoxValue!);
          if (_rightBoxValue != null) _availableNumbers.add(_rightBoxValue!);
          _leftBoxValue = null;
          _rightBoxValue = null;
          _feedbackColor = Colors.transparent;
        });
      });
    }
  }

  Future<void> _handleGameEnd() async {
    _gameTimer?.cancel();
    _musicPlayer.pause();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      if (token != null) {
        await http.post(
          Uri.parse('http://127.0.0.1:8000/api/leaderboard'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'time': _elapsedSeconds}),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print("Gagal mengirim skor: $e");
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => GameResultsDialog(
          correctAnswers: _correctAnswersCount,
          incorrectAttempts: _incorrectAttempts,
          finalScore: _score,
          onPlayAgain: () {
            Navigator.of(context).pop();
            _resetGame();
          },
          onViewLeaderboard: () {
            Navigator.of(context).pop();
            _musicPlayer.stop();
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const GameLeaderboardScreen()));
          },
        ),
      );
    }
  }

  void _showVolumeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Atur Volume',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade800),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        _volume == 0 ? Icons.volume_off : Icons.volume_up,
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
                  child: Text('Tutup',
                      style: GoogleFonts.poppins(
                          color: Colors.blue.shade500,
                          fontWeight: FontWeight.bold)),
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showExitConfirmationDialog() async {
    _gameTimer?.cancel();
    _musicPlayer.pause();
    _playSoundEffect('audio/bubble-pop-7-351339.mp3');

    final bool? shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Keluar dari Permainan?',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade800)),
          content: Text(
              'Apakah Anda yakin ingin keluar? Progress tidak akan tersimpan.',
              style: GoogleFonts.poppins(color: Colors.blueGrey.shade700)),
          actions: <Widget>[
            TextButton(
              child: Text('Batal',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600)),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: Text('Ya, Keluar',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (shouldExit == true) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      _startGameTimer();
      if (_volume > 0) {
        _musicPlayer.resume();
      }
    }
  }

  // === UI FIX: Perubahan besar ada di dalam method build() dan beberapa widget buildernya ===
  @override
  Widget build(BuildContext context) {
    // PopScope tetap ada untuk menangani tombol kembali Android
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        _showExitConfirmationDialog();
      },
      child: Scaffold(
        body: Stack(
          children: [
            const AnimatedBubbleBackground(),
            SafeArea(
              // === UI FIX: Gunakan SingleChildScrollView agar layar bisa di-scroll jika kontennya terlalu panjang ===
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  // Pastikan Column memiliki tinggi minimal setinggi layar
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // Memberi jarak antar elemen
                    children: [
                      _buildHeader(),
                      // === UI FIX: Spacer diganti dengan SizedBox agar kompatibel dengan SingleChildScrollView ===
                      const SizedBox(height: 20),
                      _buildQuestionArea(),
                      const SizedBox(height: 20),
                      _buildNumberPool(),
                      const SizedBox(height: 20), // Beri jarak di bawah
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButton(
            onTap: _showExitConfirmationDialog,
            child: const Icon(Icons.reply, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          _buildActionButton(
            onTap: _showVolumeDialog,
            child: Icon(
              _volume > 0.5
                  ? Icons.volume_up_rounded
                  : (_volume > 0
                      ? Icons.volume_down_rounded
                      : Icons.volume_off_rounded),
              color: Colors.white,
              size: 28,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Soal $_currentQuestionNumber dari 30',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          shadows: [
                            const Shadow(color: Colors.black26, blurRadius: 4)
                          ])),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _currentQuestionNumber / 30,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 5,
                      offset: const Offset(0, 2))
                ]),
            child: Row(children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text('$_score',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.blueGrey.shade700)),
            ]),
          )
        ],
      ),
    );
  }

  Widget _buildQuestionArea() {
    // === UI FIX: Bungkus dengan FittedBox agar ukuran soal otomatis mengecil di layar sempit ===
    return FittedBox(
      fit: BoxFit
          .scaleDown, // Pastikan tidak membesar, hanya mengecil jika perlu
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 5)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDropTargetBubble(0, _leftBoxValue),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(_operatorSymbol,
                  style: GoogleFonts.nunito(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade800)),
            ),
            _buildDropTargetBubble(1, _rightBoxValue),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('=',
                  style: GoogleFonts.nunito(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade800)),
            ),
            _buildAnswerBubble(_correctAnswer),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPool() {
    return DragTarget<int>(
      onAccept: (number) => _returnNumberToPool(number),
      builder: (context, candidateData, rejectedData) {
        return Container(
          // === UI FIX: Hapus tinggi tetap, biarkan Wrap yang menentukan tingginya ===
          // height: 200, <-- Dihapus
          constraints:
              const BoxConstraints(minHeight: 180), // Beri tinggi minimal
          width: double.infinity, // Penuhi lebar layar
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color:
                Colors.black.withOpacity(candidateData.isNotEmpty ? 0.3 : 0.15),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Center(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: _availableNumbers
                  .map((number) => _buildDraggableBubble(number))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  // Sisa kode widget build lainnya tidak perlu diubah karena sudah cukup baik...
  Widget _buildDraggableBubble(int number) {
    return AnimatedBuilder(
      animation: _bubbleAnimationController,
      builder: (context, child) {
        final animationValue =
            sin(_bubbleAnimationController.value * 2 * pi + (number % 5));
        return Transform.translate(
          offset: Offset(0, animationValue * 5),
          child: child,
        );
      },
      child: Draggable<int>(
        data: number,
        feedback: _buildBubble(number, isDragging: true),
        childWhenDragging: const SizedBox(width: 85, height: 85),
        onDragStarted: () => _playSoundEffect('audio/bubble-pop-7-351339.mp3'),
        child: _buildBubble(number),
      ),
    );
  }

  Widget _buildDropTargetBubble(int boxIndex, int? value) {
    return DragTarget<int>(
      onWillAccept: (data) => value == null,
      onAccept: (data) => _onAcceptToAnswerBox(boxIndex, data),
      builder: (context, candidateData, rejectedData) {
        bool isTargeted = candidateData.isNotEmpty;

        if (value != null) {
          return Draggable<int>(
            data: value,
            feedback: _buildBubble(value, isDragging: true),
            onDragStarted: () {
              _playSoundEffect('audio/bubble_pop.mp3');
              _returnNumberToPool(value);
            },
            child: _buildBubble(value,
                isAnswerBox: true, feedbackColor: _feedbackColor),
          );
        }

        return Container(
          width: 85,
          height: 85,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: isTargeted
                  ? Colors.greenAccent.shade400
                  : Colors.blue.shade100,
              width: 4,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnswerBubble(int number) {
    return Container(
      width: 85,
      height: 85,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.cyan.shade100,
          border: Border.all(color: Colors.cyan.shade300, width: 2)),
      child: Center(
          child: Text('$number',
              style: GoogleFonts.nunito(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.cyan.shade800))),
    );
  }

  Widget _buildBubble(int number,
      {bool isDragging = false,
      bool isAnswerBox = false,
      Color feedbackColor = Colors.transparent}) {
    Color bubbleColor = isAnswerBox ? feedbackColor : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 85,
        height: 85,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bubbleColor,
          gradient: bubbleColor == Colors.transparent
              ? LinearGradient(
                  colors: isDragging
                      ? [Colors.blue.shade400, Colors.lightBlueAccent.shade200]
                      : [Colors.blue.shade300, Colors.lightBlue.shade200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 5, offset: Offset(0, 3))
          ],
        ),
        child: Center(
            child: Text('$number',
                style: GoogleFonts.nunito(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white))),
      ),
    );
  }

  Widget _buildActionButton(
      {required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
        child: child,
      ),
    );
  }
}

// Sisa kode (GameResultsDialog, AnimatedBubbleBackground) tidak berubah
class GameResultsDialog extends StatelessWidget {
  final int correctAnswers;
  final int incorrectAttempts;
  final int finalScore;
  final VoidCallback onPlayAgain;
  final VoidCallback onViewLeaderboard;

  const GameResultsDialog({
    super.key,
    required this.correctAnswers,
    required this.incorrectAttempts,
    required this.finalScore,
    required this.onPlayAgain,
    required this.onViewLeaderboard,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded,
                color: Colors.amber, size: 80),
            const SizedBox(height: 16),
            Text(
              'Kerja Bagus!',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade800,
              ),
            ),
            const SizedBox(height: 24),
            _buildStatRow(
              icon: Icons.check_circle_rounded,
              label: 'Soal Benar',
              value: '$correctAnswers',
              color: Colors.green.shade500,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              icon: Icons.cancel_rounded,
              label: 'Percobaan Salah',
              value: '$incorrectAttempts',
              color: Colors.red.shade500,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              icon: Icons.star_rounded,
              label: 'Skor Akhir',
              value: '$finalScore',
              color: Colors.amber.shade700,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: onPlayAgain,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.grey.shade800,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: Text('Main Lagi',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onViewLeaderboard,
                  icon: const Icon(Icons.leaderboard_rounded),
                  label: Text('Peringkat',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            )
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
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 16, color: Colors.blueGrey.shade700)),
          ],
        ),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade800)),
      ],
    );
  }
}

class AnimatedBubbleBackground extends StatefulWidget {
  const AnimatedBubbleBackground({super.key});

  @override
  State<AnimatedBubbleBackground> createState() =>
      _AnimatedBubbleBackgroundState();
}

class _AnimatedBubbleBackgroundState extends State<AnimatedBubbleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Bubble> bubbles;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    bubbles = List.generate(30, (index) {
      return Bubble(
        color: Colors.white.withOpacity(random.nextDouble() * 0.2 + 0.05),
        size: random.nextDouble() * 40 + 20,
        position: Offset(random.nextDouble(), random.nextDouble()),
        speed: random.nextDouble() * 0.4 + 0.1,
      );
    });

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )
      ..addListener(() {
        updateBubblePositions();
      })
      ..repeat();
  }

  void updateBubblePositions() {
    if (mounted) {
      setState(() {
        for (var bubble in bubbles) {
          bubble.position = Offset(
            bubble.position.dx,
            bubble.position.dy - 0.002 * bubble.speed,
          );
          if (bubble.position.dy < -0.2) {
            bubble.position = Offset(random.nextDouble(), 1.2);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF29B6F6), Color(0xFF81D4FA)],
        ),
      ),
      child: CustomPaint(
        painter: BubblePainter(bubbles: bubbles),
        child: Container(),
      ),
    );
  }
}

class Bubble {
  Color color;
  double size;
  Offset position;
  double speed;

  Bubble(
      {required this.color,
      required this.size,
      required this.position,
      required this.speed});
}

class BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;

  BubblePainter({required this.bubbles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var bubble in bubbles) {
      final paint = Paint()..color = bubble.color;
      final position = Offset(
          bubble.position.dx * size.width, bubble.position.dy * size.height);
      canvas.drawCircle(position, bubble.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
