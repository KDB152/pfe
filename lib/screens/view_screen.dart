import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class ViewScreen extends StatefulWidget {
  @override
  _ViewScreenState createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> {
  String _cameraUrl = '';
  bool _isConnected = false;
  final TextEditingController _ipController = TextEditingController();
  Timer? _streamTimer;
  String _imageUrl = '';
  bool _isStreaming = false;
  bool _isLoading = false;
  int _selectedQuality = 20; // Qualité moyenne par défaut

  // Pour forcer l'actualisation de l'image
  int _refreshCounter = 0;

  @override
  void dispose() {
    _stopStream();
    _ipController.dispose();
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

    // Test de connexion avant de se connecter complètement
    http
        .get(Uri.parse('http://$ipAddress'))
        .timeout(
          const Duration(seconds: 5), // Augmentation du délai d'attente
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

      // Correction pour un flux vidéo live en utilisant le format MJPEG natif
      // Ne pas ajouter de paramètre timestamp pour éviter de casser le streaming continu
      _imageUrl = '$_cameraUrl/mjpeg/1';

      // Alternative si le premier endpoint ne fonctionne pas
      // _imageUrl = '$_cameraUrl/stream';
    });

    // Supprimer le timer qui rafraîchit périodiquement l'image
    // Pour un vrai streaming, l'Image.network gère automatiquement le flux MJPEG
    if (_streamTimer != null) {
      _streamTimer!.cancel();
      _streamTimer = null;
    }
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
      // Correction de l'URL de contrôle LED pour l'ESP32-CAM standard
      final response = await http
          .get(Uri.parse('$_cameraUrl/control?var=flash&val=1'))
          .timeout(const Duration(seconds: 3));

      // Pour éteindre, on pourrait utiliser val=0, mais ici on veut juste basculer
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
      // Correction de l'URL pour ajuster la qualité sur l'ESP32-CAM standard
      final response = await http
          .get(Uri.parse('$_cameraUrl/control?var=quality&val=$quality'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        _showSnackBar("Qualité modifiée");
        // Redémarrer le flux pour appliquer les changements
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
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ESP32-CAM Viewer'),
        backgroundColor: Colors.deepOrange,
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.deepOrange.shade50, Colors.white],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (!_isConnected) ...[
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Connectez-vous à votre caméra',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: _ipController,
                              decoration: InputDecoration(
                                labelText: 'Adresse IP de l\'ESP32-CAM',
                                hintText: 'Ex: 192.168.1.1',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: Icon(Icons.camera_alt),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _connectToCamera,
                              child:
                                  _isLoading
                                      ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Text('Connecter'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.link, color: Colors.green),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Connecté à $_cameraUrl',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _disconnectFromCamera,
                              icon: Icon(Icons.logout, size: 18),
                              label: Text('Déconnecter'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child:
                              _isStreaming
                                  ? Image.network(
                                    _imageUrl,
                                    fit: BoxFit.contain,
                                    // Suppression du cache pour obtenir un streaming en temps réel
                                    // cacheWidth et cacheHeight interfèrent avec les flux MJPEG
                                    gaplessPlayback:
                                        true, // Empêche le clignotement lors des mises à jour
                                    errorBuilder: (context, error, stackTrace) {
                                      print("Erreur de chargement: $error");
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.videocam_off,
                                              size: 60,
                                              color: Colors.red,
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'Erreur de chargement du flux vidéo',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Vérifiez que l\'ESP32-CAM est en marche\net que l\'URL est correcte',
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: 16),
                                            TextButton.icon(
                                              onPressed: () {
                                                // Essayer avec une URL alternative pour le streaming
                                                setState(() {
                                                  if (_imageUrl.contains(
                                                    '/mjpeg/1',
                                                  )) {
                                                    _imageUrl =
                                                        '$_cameraUrl/stream';
                                                  } else {
                                                    _imageUrl =
                                                        '$_cameraUrl/mjpeg/1';
                                                  }
                                                });
                                              },
                                              icon: Icon(Icons.refresh),
                                              label: Text('Réessayer'),
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
                                        Icon(
                                          Icons.videocam_off,
                                          size: 60,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Flux vidéo arrêté',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: _startStream,
                                          icon: Icon(Icons.play_arrow),
                                          label: Text('Démarrer le flux'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.deepOrange,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    ),
                                    label: Text(
                                      _isStreaming ? 'Arrêter' : 'Démarrer',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          _isStreaming
                                              ? Colors.red
                                              : Colors.deepOrange,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading ? null : _toggleLed,
                                    icon: Icon(Icons.lightbulb),
                                    label: Text('LED'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Divider(),
                            SizedBox(height: 4),
                            Text(
                              'Qualité de l\'image:',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                  ],
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
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
          child: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isSelected ? Colors.deepOrange : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.black87,
            elevation: isSelected ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}
