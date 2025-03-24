import 'package:flutter/material.dart';

class FireDetectionBackground extends StatelessWidget {
  final Widget child;

  const FireDetectionBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.6), // Noir transparent en haut
            Colors.deepOrange.withOpacity(0.5), // Orange en bas
          ],
        ),
      ),
      child: child,
    );
  }
}
