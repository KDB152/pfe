import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class ViewScreen extends StatefulWidget {
  const ViewScreen({super.key});

  @override
  _ViewScreenState createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen>
    with SingleTickerProviderStateMixin {
  String _cameraUrl = '';
  bool _isConnected = false;
  final TextEditingController _ipController = TextEditingController();
  Timer? _streamTimer;
  String _imageUrl = '';
  bool _isStreaming = false;
  bool _isLoading = false;
  int _selectedQuality = 20; // Qualité moyenne par défaut
  int _refreshCounter = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
  }

  @override
  void dispose() {
    _stopStream();
    _ipController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _connectToCamera() {
    setState(() {
      _isLoading = true;
    });

    final ipAddress = _ipController.text.trim();
    if (ipAddress.isEmpty) {
      _showSnackBar("Veuillez entrer une adresse IP");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    http
        .get(Uri.parse('http://$ipAddress'))
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            _showSnackBar(
              "Délai d'attente dépassé. Vérifiez l'adresse IP de votre ESP32-CAM",
            );
            setState(() {
              _isLoading = false;
            });
            return http.Response('Timeout', 408);
          },
        )
        .then((response) {
          if (response.statusCode == 200) {
            setState(() {
              _cameraUrl = 'http://$ipAddress';
              _isConnected = true;
              _isLoading = false;
            });
            _startStream();
          } else {
            _showSnackBar("La connexion a échoué: ${response.statusCode}");
            setState(() {
              _isLoading = false;
            });
          }
        })
        .catchError((error) {
          _showSnackBar("Erreur de connexion: ${error.toString()}");
          setState(() {
            _isLoading = false;
          });
        });
  }

  void _disconnectFromCamera() {
    _stopStream();
    setState(() {
      _isConnected = false;
      _imageUrl = '';
    });
  }

  void _startStream() {
    setState(() {
      _isStreaming = true;
      _refreshCounter++;
      _imageUrl = '$_cameraUrl/stream';
    });

    _streamTimer = Timer.periodic(Duration(seconds: 0), (timer) {
      if (_isStreaming && mounted) {
        setState(() {
          _refreshCounter++;
          _imageUrl = '$_cameraUrl/capture?_t=$_refreshCounter';
        });
      }
    });
  }

  void _stopStream() {
    if (_streamTimer != null) {
      _streamTimer!.cancel();
      _streamTimer = null;
    }

    try {
      if (mounted) {
        setState(() {
          _isStreaming = false;
        });
      }
    } catch (e) {
      print('Failed to update state: $e');
    }
  }

  void _toggleLed() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http
          .get(Uri.parse('$_cameraUrl/control?var=flash&val=1'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        _showSnackBar("LED basculée avec succès");
      } else {
        _showSnackBar("Erreur: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar("Erreur lors de la commutation de la LED: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _adjustQuality(int quality) async {
    setState(() {
      _isLoading = true;
      _selectedQuality = quality;
    });

    try {
      final response = await http
          .get(Uri.parse('$_cameraUrl/control?var=quality&val=$quality'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        _showSnackBar("Qualité modifiée");
        if (_isStreaming) {
          _stopStream();
          _startStream();
        }
      } else {
        _showSnackBar("Erreur: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar(
        "Erreur lors de l'ajustement de la qualité: ${e.toString()}",
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Inter', color: Colors.white),
        ),
        backgroundColor: Colors.black.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Visualisation du local',
          style: TextStyle(color: Colors.white, fontFamily: 'Inter'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD43C38), Color(0xFFFF8A65)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (!_isConnected) ...[
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Connectez-vous à votre caméra',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _ipController,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Inter',
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Adresse IP de l\'ESP32-CAM',
                                    labelStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontFamily: 'Inter',
                                    ),
                                    hintText: 'Ex: 192.168.1.1',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontFamily: 'Inter',
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: Colors.white,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _connectToCamera,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFFD43C38),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child:
                                      _isLoading
                                          ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Color(0xFFD43C38),
                                                  ),
                                            ),
                                          )
                                          : const Text(
                                            'Connecter',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: Color(0xFFD43C38),
                                            ),
                                          ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.link, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Connecté à $_cameraUrl',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _disconnectFromCamera,
                                  icon: const Icon(
                                    Icons.logout,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Déconnecter',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    _isStreaming
                                        ? Image.network(
                                          _imageUrl,
                                          fit: BoxFit.contain,
                                          cacheWidth: 800,
                                          cacheHeight: 600,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            print(
                                              "Erreur de chargement: $error",
                                            );
                                            return Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.videocam_off,
                                                    size: 60,
                                                    color: Colors.red,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  const Text(
                                                    'Erreur de chargement du flux vidéo',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Vérifiez que l\'ESP32-CAM est en marche\net que l\'URL est correcte',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.8),
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  TextButton.icon(
                                                    onPressed: () {
                                                      setState(() {
                                                        _refreshCounter++;
                                                        _imageUrl =
                                                            '$_cameraUrl/capture?_t=$_refreshCounter';
                                                      });
                                                    },
                                                    icon: const Icon(
                                                      Icons.refresh,
                                                      color: Colors.white,
                                                    ),
                                                    label: const Text(
                                                      'Réessayer',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontFamily: 'Inter',
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          loadingBuilder: (
                                            BuildContext context,
                                            Widget child,
                                            ImageChunkEvent? loadingProgress,
                                          ) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  CircularProgressIndicator(
                                                    value:
                                                        loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  const Text(
                                                    'Chargement du flux vidéo...',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        )
                                        : Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.videocam_off,
                                                size: 60,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(height: 16),
                                              const Text(
                                                'Flux vidéo arrêté',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              ElevatedButton.icon(
                                                onPressed: _startStream,
                                                icon: const Icon(
                                                  Icons.play_arrow,
                                                  color: Color(0xFFD43C38),
                                                ),
                                                label: const Text(
                                                  'Démarrer le flux',
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    color: Color(0xFFD43C38),
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                  foregroundColor: const Color(
                                                    0xFFD43C38,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
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
                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            _isLoading
                                                ? null
                                                : (_isStreaming
                                                    ? _stopStream
                                                    : _startStream),
                                        icon: Icon(
                                          _isStreaming
                                              ? Icons.stop
                                              : Icons.play_arrow,
                                          color: Colors.white,
                                        ),
                                        label: Text(
                                          _isStreaming ? 'Arrêter' : 'Démarrer',
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            color: Colors.white,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              _isStreaming
                                                  ? Colors.red
                                                  : Colors.green,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            _isLoading ? null : _toggleLed,
                                        icon: const Icon(
                                          Icons.lightbulb,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          'LED',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            color: Colors.white,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Divider(color: Colors.white.withOpacity(0.3)),
                                const SizedBox(height: 4),
                                const Text(
                                  'Qualité de l\'image:',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildQualityButton('Basse', 10),
                                    _buildQualityButton('Moyenne', 20),
                                    _buildQualityButton('Haute', 30),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQualityButton(String label, int quality) {
    final isSelected = _selectedQuality == quality;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : () => _adjustQuality(quality),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isSelected ? Colors.white : Colors.white.withOpacity(0.1),
            foregroundColor:
                isSelected ? const Color(0xFFD43C38) : Colors.white,
            elevation: isSelected ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              color: isSelected ? const Color(0xFFD43C38) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
