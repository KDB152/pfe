// lib/services/sensor_service.dart

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data_model.dart';

class SensorService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'sensors/esp32cam/current',
  );
  late StreamController<SensorData> _sensorStreamController;

  Stream<SensorData> get sensorDataStream => _sensorStreamController.stream;

  Future<void> initialize() async {
    _sensorStreamController = StreamController<SensorData>.broadcast();

    // Écouter les mises à jour en temps réel de Firebase
    _dbRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        // Convertir les données Firebase en modèle SensorData
        final sensorData = SensorData(
          temperature: double.tryParse(data['temperature'].toString()) ?? 0.0,
          humidity: double.tryParse(data['humidity'].toString()) ?? 0.0,
          smoke:
              (data['flame'] == true)
                  ? 3.0
                  : 0.0, // Convertir l'état de flamme en valeur de fumée
          co2: double.tryParse(data['co2'].toString()) ?? 0.0,
          isAlarmActive: data['alarm'] ?? false,
          timestamp: DateTime.now(),
        );

        // Ajouter les données au stream
        _sensorStreamController.add(sensorData);
      }
    });
  }

  // Récupérer les dernières données
  SensorData getLastSensorData() {
    // Cette méthode sera remplacée par les données du stream
    return SensorData(
      temperature: 23.0,
      humidity: 45.0,
      smoke: 0.0,
      co2: 600.0,
      isAlarmActive: false,
      timestamp: DateTime.now(),
    );
  }

  // Obtenir l'historique des alertes
  List<Alert> getAlerts() {
    // Vous pouvez implémenter la récupération des alertes depuis Firebase ici
    return [];
  }
}
