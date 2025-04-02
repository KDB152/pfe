// services/ai_service.dart
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/fire_detection_model.dart';

class AIService {
  late Interpreter _interpreter;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Chargement du modèle TFLite
      _interpreter = await Interpreter.fromAsset(
        'assets/fire_detection_model.tflite',
      );
      _isInitialized = true;
    } catch (e) {
      print('Erreur , $e');
      rethrow;
    }
  }

  Future<FireDetectionResult> analyzeImage(File imageFile) async {
    if (!_isInitialized) await initialize();

    // Prétraitement de l'image
    // Code pour redimensionner l'image et la convertir en tenseur

    // Exécution de l'inférence
    var input = [/* votre image prétraitée */];
    var output = List.filled(1 * 2, 0.0).reshape([1, 2]);

    _interpreter.run(input, output);

    // Traitement du résultat
    double fireConfidence = output[0][1];
    bool fireDetected = fireConfidence > 0.7; // Seuil de confiance

    return FireDetectionResult(
      isFireDetected: fireDetected,
      confidence: fireConfidence,
      timestamp: DateTime.now(),
    );
  }

  // Méthode alternative - utiliser une API distante
  Future<FireDetectionResult> analyzeImageViaAPI(File imageFile) async {
    // Code pour envoyer l'image à une API et récupérer le résultat
    // Utilisez http ou dio pour les requêtes API

    // Simulons un résultat pour l'exemple
    return FireDetectionResult(
      isFireDetected: true,
      confidence: 0.85,
      timestamp: DateTime.now(),
    );
  }
}
