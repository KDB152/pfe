import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class IntroScreen extends StatefulWidget {
  const IntroScreen({Key? key}) : super(key: key);

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _gradientAnimation;
  late Animation<double> _particleAnimation;
  int _currentPage = 0;
  final int _numPages = 3;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutSine,
      ),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    _initParticles();
  }

  void _initParticles() {
    final random = math.Random();
    for (int i = 0; i < 30; i++) {
      _particles.add(
        Particle(
          position: Offset(
            random.nextDouble() * 500,
            random.nextDouble() * 1000,
          ),
          velocity: Offset(
            random.nextDouble() * 3 - 1.5,
            random.nextDouble() * 3 - 1.5,
          ),
          color: Color.fromRGBO(
            255,
            87 + random.nextInt(80), // Adjusted to stay closer to 0xFFFF8A65
            34 + random.nextInt(30),
            0.5 + random.nextDouble() * 0.5,
          ),
          size: 3 + random.nextDouble() * 12,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<Widget> _buildPageIndicator() {
    List<Widget> list = [];
    for (int i = 0; i < _numPages; i++) {
      list.add(i == _currentPage ? _indicator(true) : _indicator(false));
    }
    return list;
  }

  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 10.0,
      width: isActive ? 28.0 : 10.0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isActive
                  ? [const Color(0xFFD43C38), const Color(0xFFFF8A65)]
                  : [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.3),
                  ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow:
            isActive
                ? [
                  BoxShadow(
                    color: const Color(0xFFD43C38).withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
                : null,
      ),
      child:
          isActive
              ? Transform.scale(
                scale: 1.0 + 0.1 * math.sin(_gradientAnimation.value * math.pi),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
              : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFD43C38),
                        const Color(0xFFFF8A65),
                      ],
                      stops: const [0.1, 0.9],
                      transform: GradientRotation(
                        _gradientAnimation.value * 0.6,
                      ),
                    ),
                  ),
                  child: CustomPaint(
                    painter: ParticlePainter(
                      _particleAnimation.value,
                      _particles,
                      screenSize,
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, right: 16.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD43C38).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Passer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    physics: const BouncingScrollPhysics(),
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: [
                      _buildFirstPage(screenSize),
                      _buildSecondPage(screenSize),
                      _buildThirdPage(screenSize),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildPageIndicator(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      if (_currentPage == _numPages - 1) {
                        Navigator.pushReplacementNamed(context, '/login');
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutBack,
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD43C38).withOpacity(0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _currentPage == _numPages - 1
                              ? 'Commencer'
                              : 'Suivant',
                          style: const TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Inter',
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstPage(Size screenSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale:
                    1.0 +
                    0.15 * math.sin(_gradientAnimation.value * math.pi * 2),
                child: Container(
                  height: screenSize.height * 0.3,
                  width: screenSize.height * 0.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.4),
                        const Color(0xFFD43C38).withOpacity(0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.2, 0.6, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD43C38).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_fire_department,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32.0),
          AnimatedOpacity(
            opacity: _currentPage == 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: const Text(
                'Bienvenue dans\nDétecteur d’Incendie',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36.0,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          AnimatedOpacity(
            opacity: _currentPage == 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD43C38).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Protection incendie en temps réel avec alertes instantanées',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondPage(Size screenSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: screenSize.height * 0.25,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: _gradientAnimation.value * math.pi,
                      child: Container(
                        width: 180 + (60 * _gradientAnimation.value),
                        height: 180 + (60 * _gradientAnimation.value),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFFD43C38).withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
                        ),
                      ),
                      child: Transform.scale(
                        scale:
                            1.0 +
                            0.1 * math.sin(_gradientAnimation.value * math.pi),
                        child: const Center(
                          child: Icon(
                            Icons.sensors,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24.0),
          AnimatedOpacity(
            opacity: _currentPage == 1 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: const Text(
                'Détection en temps réel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30.0,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Column(
            children: [
              AnimatedOpacity(
                opacity: _currentPage == 1 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: _buildInfoCard(
                    'Capteurs Intelligents',
                    'Surveillance continue via un réseau connecté',
                    Icons.wifi_tethering,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedOpacity(
                opacity: _currentPage == 1 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: _buildInfoCard(
                    'Alertes Instantanées',
                    'Notifications dès détection d’anomalie',
                    Icons.notifications_active,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThirdPage(Size screenSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16.0),
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale:
                      1.0 + 0.1 * math.sin(_gradientAnimation.value * math.pi),
                  child: Container(
                    height: screenSize.height * 0.3,
                    width: screenSize.width * 0.8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          const Color(0xFFD43C38).withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD43C38).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.support_agent,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32.0),
            AnimatedOpacity(
              opacity: _currentPage == 2 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: const Text(
                  'Besoin d’Aide ?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36.0,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            AnimatedOpacity(
              opacity: _currentPage == 2 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: _buildContactItem(
                  Icons.phone,
                  'Téléphone',
                  '+216 22 900 603',
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedOpacity(
              opacity: _currentPage == 2 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: _buildContactItem(
                  Icons.email,
                  'E-mail',
                  'detecteurincendie7@gmail.com',
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedOpacity(
              opacity: _currentPage == 2 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: _buildContactItem(
                  Icons.access_time,
                  'Disponibilité',
                  '24/7',
                ),
              ),
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String description, IconData icon) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            const Color(0xFFD43C38).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD43C38).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale:
                    1.0 +
                    0.1 * math.sin(_gradientAnimation.value * math.pi * 2),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String title, String value) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            const Color(0xFFD43C38).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD43C38).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale:
                    1.0 +
                    0.1 * math.sin(_gradientAnimation.value * math.pi * 2),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Particle {
  Offset position;
  Offset velocity;
  Color color;
  double size;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
  });
}

class ParticlePainter extends CustomPainter {
  final double animationValue;
  final List<Particle> particles;
  final Size screenSize;

  ParticlePainter(this.animationValue, this.particles, this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint =
          Paint()
            ..color = particle.color
            ..style = PaintingStyle.fill
            ..blendMode = BlendMode.plus;

      final animatedPosition =
          particle.position +
          Offset(
            particle.velocity.dx * animationValue * 12,
            particle.velocity.dy * animationValue * 12,
          );

      final clampedX = animatedPosition.dx.clamp(0.0, screenSize.width);
      final clampedY = animatedPosition.dy.clamp(0.0, screenSize.height);
      final clampedPosition = Offset(clampedX, clampedY);

      canvas.drawCircle(
        clampedPosition,
        particle.size * (1 - animationValue * 0.3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
