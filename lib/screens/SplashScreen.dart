import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _flameController;
  late AnimationController _waveController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;

  late Animation<double> _flameAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<Particle> _particles = [];
  final int _particleCount = 20;

  @override
  void initState() {
    super.initState();
    NotificationService().initialize();

    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _flameAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flameController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _initParticles();
    _scaleController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(seconds: 3), () {
        Navigator.pushReplacementNamed(context, '/intro');
      });
    });
  }

  void _initParticles() {
    final random = math.Random();
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(
        Particle(
          position: Offset(
            -10 + random.nextDouble() * 20,
            -20 + random.nextDouble() * 40,
          ),
          velocity: Offset(
            -0.5 + random.nextDouble() * 1,
            -1 - random.nextDouble() * 1,
          ),
          color: Color.fromRGBO(
            255,
            87 + random.nextInt(80), // Adjusted to match 0xFFFF8A65
            34 + random.nextInt(30),
            0.7 + random.nextDouble() * 0.3,
          ),
          size: 6 + random.nextDouble() * 12,
          lifespan: 0.9 + random.nextDouble() * 0.3,
        ),
      );
    }
  }

  @override
  void dispose() {
    _flameController.dispose();
    _waveController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
            stops: [0.0, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: BackgroundPainter(_waveController)),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _flameAnimation,
                      _scaleAnimation,
                      _fadeAnimation,
                    ]),
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            height: screenSize.width * 0.45,
                            width: screenSize.width * 0.45,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.9),
                                  Colors.white.withOpacity(0.4),
                                  Colors.transparent,
                                ],
                                stops: [0.3, 0.7, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFD43C38).withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: Size(
                                    screenSize.width * 0.35,
                                    screenSize.width * 0.35,
                                  ),
                                  painter: FlamePainter(
                                    _flameAnimation.value,
                                    _particles,
                                  ),
                                ),
                                ShaderMask(
                                  shaderCallback:
                                      (bounds) => LinearGradient(
                                        colors: [
                                          Color(0xFFD43C38),
                                          Color(0xFFFF8A65),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                  child: Icon(
                                    Icons.local_fire_department,
                                    size: 70,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: 200,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _flameController,
                      builder: (context, child) {
                        return Stack(
                          children: [
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _flameController.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFD43C38),
                                      Color(0xFFFF8A65),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFFD43C38).withOpacity(0.3),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _flameController,
                      _fadeAnimation,
                    ]),
                    builder: (context, child) {
                      final dotsCount =
                          ((_flameController.value * 3) % 3).floor() + 1;
                      final dots = '.' * dotsCount;
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Text(
                          'Chargement$dots',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Particle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double lifespan;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.lifespan,
  });
}

class FlamePainter extends CustomPainter {
  final double animationValue;
  final List<Particle> particles;

  FlamePainter(this.animationValue, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      final paint =
          Paint()
            ..color = particle.color
            ..style = PaintingStyle.fill
            ..blendMode = BlendMode.plus;

      final animatedPosition =
          center +
          particle.position +
          Offset(
            particle.velocity.dx * animationValue * 8,
            particle.velocity.dy * animationValue * 8,
          );

      final wobble = math.sin(animationValue * 2 * math.pi) * 3;

      final radius = particle.size * (1 - animationValue * 0.4);
      final clampedX = (animatedPosition.dx + wobble).clamp(
        radius,
        size.width - radius,
      );
      final clampedY = (animatedPosition.dy + wobble).clamp(
        radius,
        size.height - radius,
      );
      final clampedPosition = Offset(clampedX, clampedY);

      paint.color = particle.color.withOpacity(
        math.max(0, particle.lifespan - (animationValue * 0.6)),
      );

      canvas.drawCircle(clampedPosition, radius, paint);
    }

    final glowPaint =
        Paint()
          ..color = Color(0xFFD43C38).withOpacity(0.2)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(
      center,
      35 + (math.sin(animationValue * math.pi * 2) * 4),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BackgroundPainter extends CustomPainter {
  final AnimationController controller;

  BackgroundPainter(this.controller);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final animValue = controller.value;

    for (int i = 0; i < 3; i++) {
      final opacity = 0.08 - (i * 0.015);
      final phase = animValue * 2 * math.pi + (i * math.pi / 3);

      final path = Path();
      path.moveTo(0, h * 0.7);

      for (double x = 0; x <= w; x += w / 40) {
        final rawY =
            h * 0.7 + math.sin(x / w * 5 * math.pi + phase) * 50 + (i * 30);
        final y = rawY.clamp(0.0, h);
        path.lineTo(x, y);
      }

      path.lineTo(w, h);
      path.lineTo(0, h);
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.overlay,
      );
    }

    for (double i = 0; i < 5; i++) {
      final phase = animValue * 2 * math.pi + (i * math.pi / 4);
      final radius = 15 + (i * 10);
      final x = w * (0.15 + i * 0.12) + math.cos(phase) * 30;
      final y = h * (0.25 + i * 0.08) + math.sin(phase) * 25;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = Colors.white.withOpacity(0.06)
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.overlay,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
