import 'package:flutter/material.dart';
import 'dart:ui';

class IntroScreen extends StatefulWidget {
  const IntroScreen({Key? key}) : super(key: key);

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _currentPage = 0;
  final int _numPages = 3;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
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
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      height: 8.0,
      width: isActive ? 24.0 : 16.0,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        boxShadow:
            isActive
                ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Fond animé
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFF7043),
                        Color(0xFFFF5722),
                        Color(0xFFE64A19),
                      ],
                      stops: [0.1, 0.5, 0.9],
                      transform: GradientRotation(_animation.value * 0.2),
                    ),
                  ),
                );
              },
            ),
          ),

          // Éléments graphiques de fond
          Positioned.fill(child: CustomPaint(painter: BackgroundPainter())),

          // Contenu principal
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, right: 24.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Ignorer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
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
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildPageIndicator(),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30.0,
                    vertical: 30.0,
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _numPages - 1) {
                        Navigator.pushReplacementNamed(context, '/login');
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFE64A19),
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: Text(
                      _currentPage == _numPages - 1 ? 'COMMENCER' : 'SUIVANT',
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
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
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo animé
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 4 * _animation.value),
                child: Container(
                  height: screenSize.height * 0.25,
                  width: screenSize.height * 0.25,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_fire_department,
                      size: 80,
                      color: Color(0xFFE64A19),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40.0),

          // Titre avec style amélioré
          ShaderMask(
            shaderCallback:
                (bounds) => const LinearGradient(
                  colors: [Colors.white, Colors.white70],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
            child: const Text(
              'Bienvenue sur\nDétecteur Incendie',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20.0),

          // Description avec container décoré
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: const Text(
                  'Votre application de surveillance et d\'alerte incendie',
                  style: TextStyle(color: Colors.white, fontSize: 18.0),
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
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation des capteurs - taille réduite
          SizedBox(
            height: screenSize.height * 0.22, // Réduit de 0.25 à 0.22
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cercles pulsants - même contenu
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 180 + (40 * _animation.value),
                          height: 180 + (40 * _animation.value),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(
                              0.1 * (1 - _animation.value),
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(
                                0.3 * (1 - _animation.value),
                              ),
                              width: 2,
                            ),
                          ),
                        ),
                        Container(
                          width: 120 + (30 * _animation.value),
                          height: 120 + (30 * _animation.value),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(
                              0.15 * (1 - _animation.value),
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(
                                0.4 * (1 - _animation.value),
                              ),
                              width: 2,
                            ),
                          ),
                        ),
                        // Icône du capteur
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.sensors,
                              size: 40,
                              color: Color(0xFFE64A19),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30.0), // Réduit de 40.0 à 30.0
          // Titre
          const Text(
            'Détection en temps réel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 15.0), // Réduit de 20.0 à 15.0
          // Points d'information dans des cartes
          Column(
            children: [
              _buildInfoCard(
                'Capteurs intelligents',
                'Réseau de capteurs connectés pour une surveillance constante',
                Icons.wifi_tethering,
              ),
              const SizedBox(height: 12), // Réduit de 16 à 12
              _buildInfoCard(
                'Alertes instantanées',
                'Notifications immédiates en cas de détection',
                Icons.notifications_active,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThirdPage(Size screenSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation d'aide
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                height: screenSize.height * 0.25,
                width: screenSize.width * 0.8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1 * _animation.value),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.support_agent,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40.0),

          // Titre
          const Text(
            'Besoin d\'aide ?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30.0),

          // Informations de contact avec icônes
          _buildContactItem(Icons.phone, 'Téléphone', '+216 22 900 603'),
          const SizedBox(height: 16),
          _buildContactItem(
            Icons.email,
            'Email',
            'detecteurincendie7@gmail.com',
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            Icons.access_time,
            'Disponibilité',
            '24h/24 et 7j/7',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String description, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment
                    .center, // Assurez-vous que les éléments sont centrés
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow:
                          TextOverflow
                              .ellipsis, // Évite le débordement du texte
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                      overflow:
                          TextOverflow
                              .ellipsis, // Évite le débordement du texte
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Peintre personnalisé pour les éléments graphiques d'arrière-plan
class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..style = PaintingStyle.fill;

    // Formes géométriques en arrière-plan
    final path1 =
        Path()
          ..moveTo(0, size.height * 0.2)
          ..quadraticBezierTo(
            size.width * 0.25,
            size.height * 0.25,
            size.width * 0.5,
            size.height * 0.2,
          )
          ..quadraticBezierTo(
            size.width * 0.75,
            size.height * 0.15,
            size.width,
            size.height * 0.3,
          )
          ..lineTo(size.width, 0)
          ..lineTo(0, 0)
          ..close();

    final path2 =
        Path()
          ..moveTo(size.width, size.height * 0.8)
          ..quadraticBezierTo(
            size.width * 0.75,
            size.height * 0.85,
            size.width * 0.5,
            size.height * 0.8,
          )
          ..quadraticBezierTo(
            size.width * 0.25,
            size.height * 0.75,
            0,
            size.height * 0.9,
          )
          ..lineTo(0, size.height)
          ..lineTo(size.width, size.height)
          ..close();

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);

    // Quelques cercles décoratifs
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.4),
      30,
      Paint()..color = Colors.white.withOpacity(0.07),
    );

    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.6),
      50,
      Paint()..color = Colors.white.withOpacity(0.05),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
