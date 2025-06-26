import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

import 'game_screen.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> with TickerProviderStateMixin {
  late AnimationController _bubbleController;
  late AnimationController _loaderController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Controller untuk animasi "nafas" tombol play
    _bubbleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    
    _loaderController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  void _startGame(BuildContext context) {
    setState(() {
      _isLoading = true;
      _loaderController.repeat();
    });

    Future.delayed(const Duration(seconds: 3), () {
      if(mounted) {
        // Hentikan animasi loader sebelum navigasi untuk menghindari error
        _loaderController.stop();
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const GameScreen(stage: 1, level: 1),
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final playButtonAlignment = _isLoading ? Alignment.center : const Alignment(0, 0.45);

    return Scaffold(
      body: Stack(
        children: [
          // Latar Belakang Animasi Bubble yang sudah diperbarui
          const AnimatedBubbleBackground(),
          
          SafeArea(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _isLoading ? 0.0 : 1.0,
              child: Column(
                children: [
                  _buildHeader(context),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'Petualangan Dimulai!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        shadows: const [Shadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                    ),
                  ),
                  const Spacer(flex: 4),
                ],
              ),
            ),
          ),

          AnimatedAlign(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            alignment: playButtonAlignment,
            child: _buildPlayButton(
              onTap: () => _isLoading ? null : _startGame(context),
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
     return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          GestureDetector(
             onTap: () => Navigator.of(context).pop(),
             child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5)
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton({VoidCallback? onTap, required bool isLoading}) {
    final anim = CurvedAnimation(parent: _bubbleController, curve: Curves.easeInOut);
    const buttonSize = 180.0;

    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final scale = isLoading ? 1.0 : 1.0 + (sin(anim.value * pi) * 0.05);
        return Transform.scale(scale: scale, child: child);
      },
      child: SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 6),
              // === PERUBAHAN: Warna gradasi tombol menjadi biru ===
              gradient: RadialGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade700],
                center: const Alignment(-0.6, -0.5),
              ),
              boxShadow: [
                if (!isLoading)
                  BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 25, spreadRadius: 5, offset: const Offset(0, 10))
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
              },
              child: isLoading
                  // Tampilan saat loading -> Loader Kustom dengan ikon baru
                  ? CoolLoaderWidget(controller: _loaderController)
                  // Tampilan awal -> Ikon dan Teks
                  : Stack(
                      key: const ValueKey('play_icon'),
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                              stops: const [0.7, 1.0],
                            ),
                          ),
                        ),
                        // === PERUBAHAN: Ikon tombol diganti ===
                        const Icon(Icons.play_arrow_rounded, size: 100, color: Colors.white),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// Widget Latar Belakang Animasi Bubble
class AnimatedBubbleBackground extends StatefulWidget {
  const AnimatedBubbleBackground({super.key});

  @override
  State<AnimatedBubbleBackground> createState() => _AnimatedBubbleBackgroundState();
}

class _AnimatedBubbleBackgroundState extends State<AnimatedBubbleBackground> with SingleTickerProviderStateMixin {
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
    )..addListener(() {
      updateBubblePositions();
    })..repeat();
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

  Bubble({required this.color, required this.size, required this.position, required this.speed});
}

class BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;

  BubblePainter({required this.bubbles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var bubble in bubbles) {
      final paint = Paint()..color = bubble.color;
      final position = Offset(bubble.position.dx * size.width, bubble.position.dy * size.height);
      canvas.drawCircle(position, bubble.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


// Widget Loader dengan Ikon Baru
class CoolLoaderWidget extends StatelessWidget {
  final AnimationController controller;
  const CoolLoaderWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: controller.value * 2 * pi,
          child: CustomPaint(
            painter: CoolLoaderPainter(),
            child: Center(
              // === PERUBAHAN: Ikon loading diganti ===
              child: Icon(
                Icons.hourglass_empty_rounded,
                color: Colors.white.withOpacity(0.8),
                size: 60,
              ),
            ),
          ),
        );
      },
    );
  }
}

class CoolLoaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    final paint1 = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),-pi / 2, pi * 1.2, false, paint1);

    final paint2 = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 12), pi / 2, pi * 0.8, false, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
