import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data_model.dart';
import 'notification_service.dart';

class SensorService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'sensors/esp32cam/current',
  );
  late StreamController<SensorData> _sensorStreamController;
  final NotificationService _notificationService = NotificationService();
  SensorData? _lastSensorData; // Stocker les dernières données
  Timer?
  _notificationTimer; // Timer pour envoyer des notifications toutes les 5 secondes

  Stream<SensorData> get sensorDataStream => _sensorStreamController.stream;

  Future<void> initialize() async {
    _sensorStreamController = StreamController<SensorData>.broadcast();

    // Initialiser le service de notifications
    await _notificationService.initialize();

    // Écouter les mises à jour en temps réel de Firebase
    _dbRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        // Convertir les données Firebase en modèle SensorData
        final sensorData = SensorData(
          temperature: double.tryParse(data['temperature'].toString()) ?? 0.0,
          humidity: double.tryParse(data['humidity'].toString()) ?? 0.0,
          smoke: (data['flame'] == true) ? 3.0 : 0.0,
          co2: double.tryParse(data['co2'].toString()) ?? 0.0,
          isAlarmActive: data['alarm'] ?? false,
          timestamp: DateTime.now(),
        );

        // Mettre à jour les dernières données
        _lastSensorData = sensorData;

        // Ajouter les données au stream
        _sensorStreamController.add(sensorData);
      }
    });

    // Lancer un timer pour vérifier les seuils toutes les 5 secondes
    _startNotificationTimer();
  }

  // Lancer un timer pour envoyer des notifications toutes les 5 secondes
  void _startNotificationTimer() {
    _notificationTimer?.cancel(); // Annuler tout timer existant
    _notificationTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (_lastSensorData != null) {
        _checkThresholds(_lastSensorData!);
      }
    });
  }

  // Vérifier les seuils et envoyer des notifications
  void _checkThresholds(SensorData data) {
    if (data.temperature > 40) {
      _notificationService.sendThresholdNotification(
        'Alerte Température',
        'La température dépasse 40°C : ${data.temperature}°C',
      );
    }
    if (data.humidity > 40) {
      _notificationService.sendThresholdNotification(
        'Alerte Humidité',
        'L\'humidité dépasse 40% : ${data.humidity}%',
      );
    }
  }

  SensorData getLastSensorData() {
    return _lastSensorData ??
        SensorData(
          temperature: 23.0,
          humidity: 45.0,
          smoke: 0.0,
          co2: 600.0,
          isAlarmActive: false,
          timestamp: DateTime.now(),
        );
  }

  List<Alert> getAlerts() {
    return [];
  }

  // Nettoyer lors de la fermeture
  void dispose() {
    _notificationTimer?.cancel();
    _sensorStreamController.close();
  }
}
