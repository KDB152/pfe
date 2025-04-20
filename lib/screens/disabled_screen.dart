import 'package:flutter/material.dart';
import 'dart:ui';
import '../screens/login_screen.dart';

class DisabledScreen extends StatefulWidget {
  const DisabledScreen({Key? key}) : super(key: key);

  @override
  _DisabledScreenState createState() => _DisabledScreenState();
}

class _DisabledScreenState extends State<DisabledScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double contentPadding = 16.0;
    const double spacingLarge = 24.0;
    const double spacingMedium = 16.0;
    const double iconSize = 80.0;
    const double titleFontSize = 24.0;
    const double bodyFontSize = 16.0;
    const double subtitleFontSize = 18.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD43C38).withOpacity(0.8),
              Color(0xFFFF8A65).withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(contentPadding),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: EdgeInsets.all(contentPadding),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: iconSize,
                              height: iconSize,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFD43C38),
                                    Color(0xFFFF8A65),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFD43C38).withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.block_rounded,
                                  color: Colors.white,
                                  size: iconSize * 0.6,
                                ),
                              ),
                            ),
                            SizedBox(height: spacingLarge),
                            Text(
                              'Compte Désactivé',
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: spacingMedium),
                            Text(
                              'Votre compte a été désactivé par un administrateur.',
                              style: TextStyle(
                                fontSize: bodyFontSize,
                                color: Colors.white.withOpacity(0.8),
                                fontFamily: 'Inter',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: spacingMedium),
                            Container(
                              padding: EdgeInsets.all(contentPadding),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: 20,
                                    color: Color(0xFFFF8A65),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Pour toute assistance, contactez-nous à detecteurincendie7@gmail.com',
                                      style: TextStyle(
                                        fontSize: bodyFontSize * 0.9,
                                        color: Colors.white.withOpacity(0.9),
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: spacingLarge * 1.5),
                            CustomButton(
                              text: 'Retourner à la connexion',
                              isLoading: false,
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginScreen(),
                                  ),
                                );
                              },
                              textColor: Colors.white,
                              gradient: LinearGradient(
                                colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
                              ),
                              borderRadius: 12,
                              textSize: subtitleFontSize,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                              elevation: 0,
                              shadowColor: Color(0xFFD43C38).withOpacity(0.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onPressed;
  final Color textColor;
  final Color? backgroundColor;
  final LinearGradient? gradient;
  final double borderRadius;
  final double textSize;
  final FontWeight? fontWeight;
  final String? fontFamily;
  final double elevation;
  final Color? shadowColor;

  const CustomButton({
    Key? key,
    required this.text,
    required this.isLoading,
    required this.onPressed,
    required this.textColor,
    this.backgroundColor,
    this.gradient,
    this.borderRadius = 8,
    this.textSize = 16,
    this.fontWeight,
    this.fontFamily,
    this.elevation = 0,
    this.shadowColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? backgroundColor : null,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: shadowColor ?? Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isLoading)
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A65)),
                strokeWidth: 3,
              ),
            Center(
              child: Text(
                text,
                style: TextStyle(
                  color: isLoading ? Colors.transparent : textColor,
                  fontSize: textSize,
                  fontWeight: fontWeight ?? FontWeight.w600,
                  fontFamily: fontFamily,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
