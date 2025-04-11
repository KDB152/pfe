import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Contrôleurs pour plusieurs animations
  late AnimationController _flameController;
  late AnimationController _waveController;
  late AnimationController _scaleController;

  // Animations
  late Animation<double> _flameAnimation;
  late Animation<double> _scaleAnimation;

  // Liste de particules pour effet de flamme
  final List<Particle> _particles = [];
  final int _particleCount = 20;

  @override
  void initState() {
    super.initState();

    // Contrôleur pour l'animation de la flamme
    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Contrôleur pour l'animation des vagues
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Contrôleur pour l'animation d'échelle
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Animation de flamme
    _flameAnimation = Tween<double>(begin: 0, end: 1).animate(_flameController);

    // Animation d'échelle
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Initialiser les particules
    _initParticles();

    // Démarrer l'animation d'échelle
    _scaleController.forward();

    // Timer pour naviguer vers l'écran d'introduction après un délai
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/intro');
    });
  }

  void _initParticles() {
    final random = math.Random();
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(
        Particle(
          position: Offset(
            -20 + random.nextDouble() * 40,
            50 - random.nextDouble() * 100,
          ),
          velocity: Offset(
            -1 + random.nextDouble() * 2,
            -2 - random.nextDouble() * 2,
          ),
          color: Color.fromRGBO(
            255,
            150 + random.nextInt(105),
            random.nextInt(100),
            0.5 + random.nextDouble() * 0.5,
          ),
          size: 5 + random.nextDouble() * 15,
          lifespan: 0.7 + random.nextDouble() * 0.3,
        ),
      );
    }
  }

  @override
  void dispose() {
    _flameController.dispose();
    _waveController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF7043), Color(0xFFE64A19)],
          ),
        ),
        child: Stack(
          children: [
            // Éléments d'arrière-plan
            Positioned.fill(
              child: CustomPaint(painter: BackgroundPainter(_waveController)),
            ),

            // Contenu principal
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Logo avec animation de flamme
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _flameAnimation,
                      _scaleAnimation,
                    ]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Cercle blanc
                            Container(
                              height: screenSize.width * 0.4,
                              width: screenSize.width * 0.4,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                            ),

                            // Effet de flamme animé
                            SizedBox(
                              height: screenSize.width * 0.5,
                              width: screenSize.width * 0.5,
                              child: CustomPaint(
                                painter: FlamePainter(
                                  _flameAnimation.value,
                                  _particles,
                                ),
                              ),
                            ),

                            // Icône de feu
                            const Icon(
                              Icons.local_fire_department,
                              size: 70,
                              color: Color(0xFFE64A19),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 60),

                  // Indicateur de chargement stylisé
                  Container(
                    width: 200,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: AnimatedBuilder(
                      animation: _flameController,
                      builder: (context, child) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _flameController.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Texte de chargement avec animation
                  AnimatedBuilder(
                    animation: _flameController,
                    builder: (context, child) {
                      final dotsCount =
                          ((_flameController.value * 3) % 3).floor() + 1;
                      final dots = '.' * dotsCount;
                      return Text(
                        'Chargement$dots',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Classe pour les particules de l'effet de flamme
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

// Peintre pour l'effet de flamme
class FlamePainter extends CustomPainter {
  final double animationValue;
  final List<Particle> particles;

  FlamePainter(this.animationValue, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Dessiner les particules
    for (final particle in particles) {
      final paint =
          Paint()
            ..color = particle.color
            ..style = PaintingStyle.fill;

      // Mise à jour de la position avec l'animation
      final animatedPosition =
          center +
          particle.position +
          Offset(
            particle.velocity.dx * animationValue * 10,
            particle.velocity.dy * animationValue * 10,
          );

      // Appliquer une variation basée sur la valeur d'animation sinusoïdale
      final wobbleX = math.sin(animationValue * 2 * math.pi) * 5;
      final wobbleY = math.cos(animationValue * 2 * math.pi) * 5;

      // Dessiner la particule avec une opacité décroissante
      paint.color = particle.color.withOpacity(
        math.max(0, particle.lifespan - (animationValue * 0.7)),
      );

      canvas.drawCircle(
        animatedPosition + Offset(wobbleX, wobbleY),
        particle.size * (1 - animationValue * 0.5),
        paint,
      );
    }

    // Ajouter une lueur autour du centre
    final glowPaint =
        Paint()
          ..color = const Color(0xFFFF7043).withOpacity(0.3)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawCircle(
      center,
      40 + (math.sin(animationValue * math.pi * 2) * 5),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Peintre pour l'arrière-plan avec effet de vagues
class BackgroundPainter extends CustomPainter {
  final AnimationController controller;

  BackgroundPainter(this.controller);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final animValue = controller.value;

    // Dessiner des formes ondulantes en arrière-plan
    for (int i = 0; i < 3; i++) {
      final opacity = 0.1 - (i * 0.03);
      final phase = animValue * 2 * math.pi + (i * math.pi / 3);

      final path = Path();
      path.moveTo(0, h * 0.7);

      for (double x = 0; x <= w; x += w / 20) {
        final y =
            h * 0.7 + math.sin(x / w * 4 * math.pi + phase) * 50 + (i * 30);
        path.lineTo(x, y);
      }

      path.lineTo(w, h);
      path.lineTo(0, h);
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..style = PaintingStyle.fill,
      );
    }

    // Dessiner quelques cercles décoratifs
    for (double i = 0; i < 5; i++) {
      final phase = animValue * 2 * math.pi + (i * math.pi / 2.5);
      final radius = 15 + (i * 10);
      final x = w * 0.2 + math.cos(phase) * 30;
      final y = h * 0.2 + math.sin(phase) * 20;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = Colors.white.withOpacity(0.05)
          ..style = PaintingStyle.fill,
      );
    }

    for (double i = 0; i < 3; i++) {
      final phase = -animValue * 2 * math.pi + (i * math.pi / 2);
      final radius = 20 + (i * 15);
      final x = w * 0.8 + math.cos(phase) * 20;
      final y = h * 0.6 + math.sin(phase) * 30;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = Colors.white.withOpacity(0.07)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
