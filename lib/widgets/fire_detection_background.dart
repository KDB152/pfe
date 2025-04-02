import 'package:flutter/material.dart';
import 'dart:math' as math;

class FireDetectionBackground extends StatefulWidget {
  final Widget child;

  const FireDetectionBackground({super.key, required this.child});

  @override
  State<FireDetectionBackground> createState() =>
      _FireDetectionBackgroundState();
}

class _FireDetectionBackgroundState extends State<FireDetectionBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base gradient background - Utilisez Positioned.fill pour qu'il remplisse tout l'espace
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0F1A30), // Bleu foncé en haut
                      Color(0xFF1F2B50), // Bleu moyen
                      Color(0xFF472D32), // Transition
                      Color(0xFF842E31), // Rouge foncé
                      Color(
                        0xFFF25A3C,
                      ).withOpacity(0.85), // Orange-rouge en bas
                    ],
                    stops: [
                      0.0,
                      0.3,
                      0.5 + 0.05 * math.sin(_controller.value * math.pi * 2),
                      0.7,
                      1.0,
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // House with fire illustration (using CustomPaint)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.6,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: HouseFirePainter(animation: _controller),
                size: Size.infinite,
              );
            },
          ),
        ),

        // Subtle overlay to ensure text readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.4),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 0.6, 1.0],
            ),
          ),
        ),

        // Light overlay at the top to ensure logo and text visibility
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.25,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              ),
            ),
          ),
        ),

        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class HouseFirePainter extends CustomPainter {
  final Animation<double> animation;

  HouseFirePainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // House silhouette
    final housePath = Path();

    // Base and walls
    double houseWidth = size.width * 0.7;
    double houseHeight = size.height * 0.4;
    double houseX = (size.width - houseWidth) / 2;
    double houseY = size.height * 0.6;

    housePath.moveTo(houseX, houseY);
    housePath.lineTo(houseX, houseY - houseHeight);
    housePath.lineTo(
      houseX + houseWidth / 2,
      houseY - houseHeight - size.height * 0.15,
    );
    housePath.lineTo(houseX + houseWidth, houseY - houseHeight);
    housePath.lineTo(houseX + houseWidth, houseY);
    housePath.close();

    // House paint - dark silhouette
    final housePaint =
        Paint()
          ..color = Colors.black.withOpacity(0.7)
          ..style = PaintingStyle.fill;

    canvas.drawPath(housePath, housePaint);

    // Door
    double doorWidth = houseWidth * 0.2;
    double doorHeight = houseHeight * 0.5;
    double doorX = houseX + (houseWidth - doorWidth) * 0.5;
    double doorY = houseY - doorHeight;

    final doorPaint =
        Paint()
          ..color = Colors.brown.shade900.withOpacity(0.8)
          ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(doorX, doorY, doorWidth, doorHeight),
      doorPaint,
    );

    // Windows
    final windowPaint =
        Paint()
          ..color = Colors.amber.withOpacity(
            0.5 + 0.5 * math.sin(animation.value * math.pi * 3),
          )
          ..style = PaintingStyle.fill;

    // Left window
    double windowSize = houseWidth * 0.15;
    double leftWindowX = houseX + houseWidth * 0.2;
    double windowY = houseY - houseHeight * 0.7;

    canvas.drawRect(
      Rect.fromLTWH(leftWindowX, windowY, windowSize, windowSize),
      windowPaint,
    );

    // Right window
    double rightWindowX = houseX + houseWidth * 0.65;

    canvas.drawRect(
      Rect.fromLTWH(rightWindowX, windowY, windowSize, windowSize),
      windowPaint,
    );

    // Draw flames coming from the house
    // Base flame positions
    List<Offset> flameBasePositions = [
      Offset(
        houseX + houseWidth * 0.3,
        houseY - houseHeight - size.height * 0.05,
      ),
      Offset(
        houseX + houseWidth * 0.5,
        houseY - houseHeight - size.height * 0.15,
      ),
      Offset(
        houseX + houseWidth * 0.7,
        houseY - houseHeight - size.height * 0.08,
      ),
      Offset(doorX + doorWidth / 2, doorY),
      Offset(leftWindowX + windowSize / 2, windowY + windowSize / 3),
    ];

    for (Offset basePos in flameBasePositions) {
      _drawFlame(canvas, basePos, size, animation.value);
    }

    // Draw smoke
    _drawSmoke(
      canvas,
      Offset(
        houseX + houseWidth * 0.4,
        houseY - houseHeight - size.height * 0.2,
      ),
      size,
      animation.value,
    );
  }

  // Modification des flammes pour plus de réalisme
  void _drawFlame(
    Canvas canvas,
    Offset basePosition,
    Size size,
    double animValue,
  ) {
    // Variation plus naturelle de la hauteur des flammes
    double flameHeight =
        size.height * (0.1 + 0.06 * math.sin(animValue * math.pi * 3));
    double flameWidth = size.width * 0.07;

    final flamePath = Path();
    flamePath.moveTo(basePosition.dx, basePosition.dy);

    // Forme de flamme plus organique
    for (int i = 0; i <= 15; i++) {
      double t = i / 15;
      double angle = math.pi + t * math.pi;
      double randomVariation = math.sin(t * 10 + animValue * math.pi * 4);

      double radius =
          flameHeight * math.sin(t * math.pi) * (0.9 + 0.4 * randomVariation);

      double xOffset =
          math.cos(angle) *
          flameWidth *
          (0.6 + 0.4 * math.sin(t * 6 + animValue * math.pi * 2));

      flamePath.lineTo(basePosition.dx + xOffset, basePosition.dy - radius);
    }

    flamePath.close();

    // Gradient de flamme plus nuancé et réaliste
    final flameGradient = RadialGradient(
      center: Alignment(0.0, 0.5),
      radius: 1.0,
      colors: [
        Colors.white.withOpacity(0.7), // Lumière blanche intense au centre
        Colors.yellow.withOpacity(0.9),
        Colors.orange.withOpacity(0.85),
        Colors.deepOrange.withOpacity(0.8),
        Colors.red.withOpacity(0.6),
        Colors.transparent, // Dégradé vers la transparence
      ],
      stops: const [0.05, 0.2, 0.4, 0.7, 0.9, 1.0],
    );

    final flamePaint =
        Paint()
          ..shader = flameGradient.createShader(
            Rect.fromCenter(
              center: basePosition.translate(0, -flameHeight / 2),
              width: flameWidth * 2.5,
              height: flameHeight * 1.5,
            ),
          );

    canvas.drawPath(flamePath, flamePaint);

    // Effet de lueur plus subtil et réaliste
    final glowPaint =
        Paint()
          ..color = Colors.orangeAccent.withOpacity(0.2)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawPath(flamePath, glowPaint);
  }

  void _drawSmoke(
    Canvas canvas,
    Offset basePosition,
    Size size,
    double animValue,
  ) {
    final random = math.Random();

    for (int i = 0; i < 10; i++) {
      double t = (animValue + i * 0.08) % 1.0;

      // Trajectoire de fumée plus complexe
      double smokeY =
          basePosition.dy -
          t * size.height * 0.35 * (1 + 0.2 * math.sin(t * math.pi * 5));

      double smokeX =
          basePosition.dx +
          math.sin(t * math.pi * 6) * size.width * 0.07 +
          random.nextDouble() * size.width * 0.02;

      double opacity = (1 - t) * 0.3;
      double smokeSize = size.width * 0.05 * (0.7 + t);

      final smokePaint =
          Paint()
            ..color = Colors.grey.withOpacity(opacity)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

      // Forme de fumée plus complexe et variée
      Path smokePath = Path();
      smokePath.addOval(
        Rect.fromCenter(
          center: Offset(smokeX, smokeY),
          width: smokeSize * (1.5 + random.nextDouble() * 0.5),
          height: smokeSize * (0.8 + random.nextDouble() * 0.4),
        ),
      );

      // Rotation légère de la fumée
      final Matrix4 rotationMatrix =
          Matrix4.identity()..rotateZ(random.nextDouble() * 0.2);

      canvas.save();
      canvas.transform(rotationMatrix.storage);
      canvas.drawPath(smokePath, smokePaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
