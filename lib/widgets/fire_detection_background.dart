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
      children: [
        // Base gradient background
        AnimatedBuilder(
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
                    Color(0xFFF25A3C).withOpacity(0.85), // Orange-rouge en bas
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

        // The actual content
        widget.child,
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

  void _drawFlame(
    Canvas canvas,
    Offset basePosition,
    Size size,
    double animValue,
  ) {
    double flameHeight =
        size.height * (0.08 + 0.04 * math.sin(animValue * math.pi * 2));
    double flameWidth = size.width * 0.06;

    final flamePath = Path();
    flamePath.moveTo(basePosition.dx, basePosition.dy);

    // Create flame shape
    for (int i = 0; i <= 12; i++) {
      double t = i / 12;
      double angle = math.pi + t * math.pi;
      double radius =
          flameHeight *
          math.sin(t * math.pi) *
          (0.8 + 0.3 * math.sin(t * 6 + animValue * math.pi * 2));

      double xOffset =
          math.cos(angle) *
          flameWidth *
          (0.5 + 0.5 * math.sin(t * 4 + animValue * math.pi * 3));

      flamePath.lineTo(basePosition.dx + xOffset, basePosition.dy - radius);
    }

    flamePath.close();

    // Flame gradient
    final flameGradient = RadialGradient(
      center: Alignment(0.0, 0.5),
      radius: 1.0,
      colors: [
        Colors.yellow.withOpacity(0.9),
        Colors.orange.withOpacity(0.85),
        Colors.deepOrange.withOpacity(0.8),
        Colors.red.withOpacity(0.7),
      ],
      stops: const [0.1, 0.4, 0.7, 1.0],
    );

    final flamePaint =
        Paint()
          ..shader = flameGradient.createShader(
            Rect.fromCenter(
              center: basePosition.translate(0, -flameHeight / 2),
              width: flameWidth * 2,
              height: flameHeight,
            ),
          );

    canvas.drawPath(flamePath, flamePaint);

    // Add glow effect
    final glowPaint =
        Paint()
          ..color = Colors.orangeAccent.withOpacity(0.3)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(flamePath, glowPaint);
  }

  void _drawSmoke(
    Canvas canvas,
    Offset basePosition,
    Size size,
    double animValue,
  ) {
    for (int i = 0; i < 6; i++) {
      double t = (animValue + i * 0.15) % 1.0;
      double smokeY = basePosition.dy - t * size.height * 0.25;
      double smokeX =
          basePosition.dx + math.sin(t * math.pi * 3) * size.width * 0.03;

      double opacity = (1 - t) * 0.2;
      double smokeSize = size.width * 0.03 * (0.5 + t);

      final smokePaint =
          Paint()
            ..color = Colors.grey.withOpacity(opacity)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(Offset(smokeX, smokeY), smokeSize, smokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
