// file: materi_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// Palet warna (tidak berubah)
const Color kBgColor = Color(0xFFE3F2FD);
const Color kPrimaryTextColor = Color(0xFF0D47A1);
const Color kSecondaryTextColor = Color(0xFF1565C0);
const Color kAccentColor = Color(0xFFFFC107);
final List<Color> kCardColors = [
  Colors.blue.shade200,
  Colors.teal.shade200,
  Colors.lightGreen.shade200,
  Colors.purple.shade200,
];

// Kelas MateriScreen (tidak ada perubahan di sini)
class MateriScreen extends StatefulWidget {
  const MateriScreen({super.key});

  @override
  _MateriScreenState createState() => _MateriScreenState();
}

class _MateriScreenState extends State<MateriScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late Future<List<dynamic>> _materiFuture;
  late AnimationController _animationController;

  Set<String> _completedMateriIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _materiFuture = _fetchMateri();
    _animationController = AnimationController(
      duration: const Duration(seconds: 40),
      vsync: this,
    )..repeat();
    _loadCompletedStatus();
  }

  Future<void> _loadCompletedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final completedIds = prefs.getStringList('completed_materi_ids') ?? [];
    setState(() {
      _completedMateriIds = completedIds.toSet();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
  }

  Future<List<dynamic>> _fetchMateri() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      if (token == null) {
        throw Exception('Token tidak ditemukan, silakan login ulang');
      }

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/materi'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal memuat materi. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')));
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          _buildAnimatedBgBubble(
              color: Colors.lightBlue.shade100.withOpacity(0.6),
              size: 220,
              startOffset: const Offset(-50, 100),
              speed: 0.8),
          _buildAnimatedBgBubble(
              color: Colors.cyan.shade100.withOpacity(0.7),
              size: 300,
              startOffset: Offset(MediaQuery.of(context).size.width - 200, 250),
              speed: 0.6),
          _buildAnimatedBgBubble(
              color: Colors.white.withOpacity(0.7),
              size: 180,
              startOffset: Offset(50, MediaQuery.of(context).size.height - 200),
              speed: 1.1),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCustomHeader(context),
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: _materiFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingState();
                      }
                      if (snapshot.hasError) {
                        return _buildErrorState(
                            context, snapshot.error.toString());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState(context);
                      }

                      var materiList = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.only(
                            left: 20, right: 20, top: 10, bottom: 40),
                        itemCount: materiList.length,
                        itemBuilder: (context, index) {
                          final bool isCompleted = _completedMateriIds
                              .contains(materiList[index]['id'].toString());

                          return _buildBubbleMateriItem(
                              context, materiList[index], index, isCompleted);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleMateriItem(
      BuildContext context, dynamic materi, int index, bool isCompleted) {
    final cardColor = kCardColors[index % kCardColors.length];
    bool hasVideo = materi['link_yt'] != null && materi['link_yt'].isNotEmpty;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailMateriScreen(materi: materi),
            ),
          );
          _loadCompletedStatus();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: cardColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
              boxShadow: [
                BoxShadow(
                    color: cardColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ]),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: Icon(
                    hasVideo
                        ? Icons.play_circle_fill_rounded
                        : Icons.auto_stories_rounded,
                    color: kPrimaryTextColor,
                    size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(materi['judul'],
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryTextColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                        isCompleted
                            ? "Sudah dipelajari!"
                            : "Ketuk untuk mulai belajar!",
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isCompleted
                                ? Colors.green.shade800
                                : kSecondaryTextColor.withOpacity(0.9),
                            fontWeight: isCompleted
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ],
                ),
              ),
              if (isCompleted)
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 28)
              else
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: kPrimaryTextColor, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          Text('Materi Belajar',
              style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryTextColor)),
        ],
      ),
    );
  }

  Widget _buildAnimatedBgBubble(
          {required Color color,
          required double size,
          required Offset startOffset,
          required double speed}) =>
      AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) => Transform.translate(
              offset: Offset(
                  startOffset.dx +
                      sin(_animationController.value * 2 * pi * speed) * 30,
                  startOffset.dy +
                      cos(_animationController.value * 2 * pi * speed) * 40),
              child: Container(
                  width: size,
                  height: size,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: color))));
  Widget _buildLoadingState() =>
      const Center(child: CircularProgressIndicator(color: kPrimaryTextColor));
  Widget _buildEmptyState(BuildContext context) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.cloud_off_rounded,
            size: 100, color: kSecondaryTextColor.withOpacity(0.5)),
        const SizedBox(height: 20),
        Text("Waduh, materi belum ada nih!",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 20,
                color: kPrimaryTextColor,
                fontWeight: FontWeight.w600)),
        Text("Coba cek lagi nanti ya!",
            textAlign: TextAlign.center,
            style:
                GoogleFonts.poppins(fontSize: 16, color: kSecondaryTextColor))
      ]));
  Widget _buildErrorState(BuildContext context, String error) => Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline_rounded,
            size: 100, color: Colors.orange.shade400),
        const SizedBox(height: 20),
        Text("Oops, ada masalah koneksi!",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 20,
                color: kPrimaryTextColor,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text("Gagal mengambil data dari server. Coba periksa internetmu.",
            textAlign: TextAlign.center,
            style:
                GoogleFonts.poppins(fontSize: 16, color: kSecondaryTextColor)),
        const SizedBox(height: 30),
        ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: kSecondaryTextColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            onPressed: () {
              setState(() {
                _materiFuture = _fetchMateri();
              });
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text("Coba Lagi",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)))
      ])));
}

// =========================================================================
// DetailMateriScreen dengan perbaikan pemutar video Youtube
// =========================================================================

class DetailMateriScreen extends StatefulWidget {
  final dynamic materi;
  const DetailMateriScreen({super.key, required this.materi});
  @override
  State<DetailMateriScreen> createState() => _DetailMateriScreenState();
}

class _DetailMateriScreenState extends State<DetailMateriScreen> {
  YoutubePlayerController? _youtubeController;
  Timer? _readTimer;
  Timer? _countdownTimer;
  static const int _totalReadTime = 300;
  int _countdown = _totalReadTime;
  bool _isCompleted = false;

  bool _isPlayerReady = false;
  bool _showControls = true;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    final String? youtubeUrl = widget.materi['link_yt'];
    if (youtubeUrl != null && youtubeUrl.isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(youtubeUrl);
      print('Debug youtubeUrl=$youtubeUrl videoId=$videoId');
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            showLiveFullscreenButton: false,
          ),
        )..addListener(_playerListener);
      }
    }
    _startReadingTimer();
  }

  void _playerListener() {
    if (_isPlayerReady && mounted) {
      setState(() {});
      if (_youtubeController!.value.isPlaying) {
        _hideControlsAfterDelay();
      }
    }
  }

  void _hideControlsAfterDelay() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _youtubeController!.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  Future<void> _startReadingTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final completedIds = prefs.getStringList('completed_materi_ids') ?? [];
    if (completedIds.contains(widget.materi['id'].toString())) {
      setState(() {
        _isCompleted = true;
      });
      return;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });

    _readTimer = Timer(const Duration(seconds: _totalReadTime), () {
      _markAsCompleted();
    });
  }

  Future<void> _markAsCompleted() async {
    if (mounted && !_isCompleted) {
      final prefs = await SharedPreferences.getInstance();
      final completedIds = prefs.getStringList('completed_materi_ids') ?? [];
      String currentMateriId = widget.materi['id'].toString();
      if (!completedIds.contains(currentMateriId)) {
        completedIds.add(currentMateriId);
        await prefs.setStringList('completed_materi_ids', completedIds);
      }
      setState(() {
        _isCompleted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.green.shade400,
          content: Text('Hebat! Kamu telah menyelesaikan materi ini.',
              style: GoogleFonts.poppins())));
    }
  }

  @override
  void dispose() {
    _readTimer?.cancel();
    _countdownTimer?.cancel();
    _controlsTimer?.cancel();
    _youtubeController?.removeListener(_playerListener);
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            backgroundColor: kBgColor,
            elevation: 2,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 60, right: 60, bottom: 16),
              centerTitle: true,
              title: Text(widget.materi['judul'],
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                      shadows: const [
                        Shadow(blurRadius: 2, color: Colors.black54)
                      ]),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              background: _buildMediaWidget(),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(top: 30, left: 24, right: 24),
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedFadeSlide(
                      delay: const Duration(milliseconds: 200),
                      child: Text(widget.materi['judul'],
                          style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryTextColor,
                              height: 1.3))),
                  const SizedBox(height: 24),
                  AnimatedFadeSlide(
                      delay: const Duration(milliseconds: 300),
                      child: const InfoBubble(
                          text:
                              "Tonton video atau baca materi dengan teliti hingga waktu habis untuk menyelesaikan.",
                          icon: Icons.timer_outlined)),
                  const SizedBox(height: 32),
                  AnimatedFadeSlide(
                      delay: const Duration(milliseconds: 500),
                      child:
                          StyledContentText(content: widget.materi['konten'])),
                  const SizedBox(height: 50),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 700),
                    child: TombolSelesai(
                      isCompleted: _isCompleted,
                      countdown: _countdown,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMediaWidget() {
    String? imageUrl = widget.materi['gambar_url'];
    bool isImageValid =
        imageUrl != null && Uri.tryParse(imageUrl)?.isAbsolute == true;

    if (_youtubeController != null) {
      return _buildVideoPlayer();
    } else if (isImageValid) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderGradient(),
        ),
      );
    } else {
      return _buildPlaceholderGradient();
    }
  }

  Widget _buildVideoPlayer() {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: kAccentColor,
        onReady: () {
          setState(() {
            _isPlayerReady = true;
          });
        },
      ),
      builder: (context, player) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _showControls = !_showControls;
              if (_showControls) _hideControlsAfterDelay();
            });
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                child: player,
              ),
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _buildVideoControls(),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 30),
            onPressed: _isPlayerReady ? () {
              final newPosition = _youtubeController!.value.position - const Duration(seconds: 10);
              _youtubeController!.seekTo(newPosition);
            } : null,
          ),
          IconButton(
            icon: Icon(
              _youtubeController!.value.isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              color: Colors.white,
              size: 50,
            ),
            onPressed: _isPlayerReady ? () {
              _youtubeController!.value.isPlaying
                  ? _youtubeController!.pause()
                  : _youtubeController!.play();
              _hideControlsAfterDelay();
            } : null,
          ),
          IconButton(
            icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 30),
            onPressed: _isPlayerReady ? () {
              final newPosition = _youtubeController!.value.position + const Duration(seconds: 10);
              _youtubeController!.seekTo(newPosition);
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderGradient() => Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.blue.shade300, kPrimaryTextColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)));
}

// Widget-widget lainnya (InfoBubble, TombolSelesai, dll.) tidak berubah
class InfoBubble extends StatelessWidget {
  final String text;
  final IconData icon;
  const InfoBubble({super.key, required this.text, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: kAccentColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kAccentColor.withOpacity(0.5), width: 1.5)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Colors.amber.shade700, size: 28),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(
                    fontSize: 15, color: Colors.brown.shade800, height: 1.6)))
      ]));
}

class TombolSelesai extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isCompleted;
  final int countdown;

  const TombolSelesai(
      {super.key,
      required this.onPressed,
      required this.isCompleted,
      required this.countdown});

  @override
  Widget build(BuildContext context) {
    final Color buttonColor =
        isCompleted ? Colors.green.shade400 : Colors.grey.shade400;
    final IconData iconData = isCompleted
        ? Icons.check_circle_outline_rounded
        : Icons.hourglass_empty_rounded;
    final String countdownText = isCompleted
        ? "Kembali"
        : "Selesaikan Baca (${(countdown ~/ 60).toString().padLeft(2, '0')}:${(countdown % 60).toString().padLeft(2, '0')})";

    return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
            onPressed: isCompleted ? onPressed : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              elevation: 5,
              shadowColor: buttonColor.withOpacity(0.4),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            icon: Icon(iconData, size: 28),
            label: Text(countdownText,
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold))));
  }
}

class StyledContentText extends StatelessWidget {
  final String content;
  const StyledContentText({super.key, required this.content});
  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return const Text("");
    String firstLetter = content.substring(0, 1);
    String restOfText = content.substring(1);
    return RichText(
        textAlign: TextAlign.justify,
        text: TextSpan(
            style: GoogleFonts.sourceSerif4(
                fontSize: 18, color: const Color(0xFF333333), height: 1.8),
            children: [
              TextSpan(
                  text: firstLetter,
                  style: GoogleFonts.poppins(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryTextColor,
                      height: 1)),
              TextSpan(text: restOfText)
            ]));
  }
}

class AnimatedFadeSlide extends StatefulWidget {
  final Duration delay;
  final Widget child;
  const AnimatedFadeSlide({super.key, required this.delay, required this.child});
  @override
  State<AnimatedFadeSlide> createState() => _AnimatedFadeSlideState();
}

class _AnimatedFadeSlideState extends State<AnimatedFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child));
}
