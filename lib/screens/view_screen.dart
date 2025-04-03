import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class ViewScreen extends StatefulWidget {
  final String ipAddress;

  const ViewScreen({Key? key, required this.ipAddress}) : super(key: key);

  @override
  _ViewScreenState createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> {
  bool _isConnected = false;
  bool _isStreaming = false;
  late WebSocketChannel? _channel;
  String _imageData = '';
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _connectToCamera();
  }

  Future<void> _connectToCamera() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Vérifier si l'ESP32-CAM est accessible
      final response = await http
          .get(Uri.parse('http://${widget.ipAddress}/status'))
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Délai de connexion dépassé');
            },
          );

      if (response.statusCode == 200) {
        _startStream();
        setState(() {
          _isConnected = true;
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur de connexion: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de se connecter à l\'ESP32-CAM: $e';
        _isLoading = false;
      });
    }
  }

  void _startStream() {
    try {
      // Se connecter au websocket de l'ESP32-CAM
      _channel = IOWebSocketChannel.connect('ws://${widget.ipAddress}/ws');

      _channel!.stream.listen(
        (dynamic message) {
          setState(() {
            _imageData = message.toString();
            _isStreaming = true;
            _isLoading = false;
          });
        },
        onError: (error) {
          setState(() {
            _errorMessage = 'Erreur de streaming: $error';
            _isStreaming = false;
            _isLoading = false;
          });
        },
        onDone: () {
          setState(() {
            _isStreaming = false;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de l\'initialisation du stream: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleFlashlight() async {
    try {
      await http.get(
        Uri.parse('http://${widget.ipAddress}/control?flash=toggle'),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de contrôler le flash: $e';
      });
    }
  }

  void _captureImage() async {
    try {
      final response = await http.get(
        Uri.parse('http://${widget.ipAddress}/capture'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image capturée avec succès')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la capture: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de capturer l\'image: $e')),
      );
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surveillance du Local'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _connectToCamera,
            tooltip: 'Reconnecter',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: Center(child: _buildCameraView())),
          if (_isConnected) _buildControlPanel(),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (_isLoading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Connexion à la caméra ESP32-CAM...'),
        ],
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _connectToCamera,
            child: const Text('Réessayer'),
          ),
        ],
      );
    }

    if (_isStreaming && _imageData.isNotEmpty) {
      return Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(_imageData),
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        ),
      );
    }

    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.videocam_off, size: 48, color: Colors.grey),
        SizedBox(height: 16),
        Text('Aucun flux vidéo disponible'),
      ],
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.flash_on,
            label: 'Flash',
            onPressed: _toggleFlashlight,
          ),
          _buildControlButton(
            icon: Icons.camera_alt,
            label: 'Capturer',
            onPressed: _captureImage,
          ),
          _buildControlButton(
            icon: Icons.settings,
            label: 'Paramètres',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/camera_settings',
                arguments: widget.ipAddress,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: Icon(icon),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}
