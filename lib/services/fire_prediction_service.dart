// Exemple d'intégration de TensorFlow Lite dans Flutter
import 'package:tflite_flutter/tflite_flutter.dart';

class FirePredictionService {
  late Interpreter _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/fire_prediction_model.tflite',
    );
  }

  Future<double> predictFireRisk(
    double temperature,
    double humidity,
    double smoke,
    double co2,
  ) async {
    // Préparer les données d'entrée
    var input = [
      [temperature, humidity, smoke, co2],
    ];

    // Préparer les données de sortie
    var output = List<double>.filled(1, 0).reshape([1, 1]);

    // Exécuter l'inférence
    _interpreter.run(input, output);

    return output[0][0]; // Niveau de risque entre 0 et 1
  }
}
