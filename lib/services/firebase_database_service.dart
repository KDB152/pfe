import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data_model.dart';

class FirebaseDatabaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Références pour les différentes parties de la base de données
  late final DatabaseReference _sensorDataRef;
  late final DatabaseReference _alertsRef;

  // Singleton pattern
  static final FirebaseDatabaseService _instance =
      FirebaseDatabaseService._internal();
  factory FirebaseDatabaseService() => _instance;

  FirebaseDatabaseService._internal() {
    _sensorDataRef = _database.child('sensor_data');
    _alertsRef = _database.child('alerts');
  }

  // Méthodes pour les données de capteur
  Future<void> saveSensorData(SensorData data) async {
    await _sensorDataRef.set(data.toJson());
  }

  Future<SensorData> getSensorData() async {
    DatabaseEvent event = await _sensorDataRef.once();
    if (event.snapshot.value != null) {
      return SensorData.fromJson(
        Map<String, dynamic>.from(event.snapshot.value as Map),
      );
    }
    // Retourner des valeurs par défaut si aucune donnée n'existe
    return SensorData(
      temperature: 22.0,
      humidity: 45.0,
      smoke: 0.0,
      co2: 850.0,
      isAlarmActive: false,
    );
  }

  Stream<SensorData> getSensorDataStream() {
    return _sensorDataRef.onValue.map((event) {
      if (event.snapshot.value != null) {
        return SensorData.fromJson(
          Map<String, dynamic>.from(event.snapshot.value as Map),
        );
      }
      return SensorData(
        temperature: 22.0,
        humidity: 45.0,
        smoke: 0.0,
        co2: 850.0,
        isAlarmActive: false,
      );
    });
  }

  // Méthodes pour les alertes
  Future<void> saveAlert(Alert alert) async {
    await _alertsRef.child(alert.id).set(alert.toJson());
  }

  Future<void> markAlertAsRead(String alertId) async {
    await _alertsRef.child(alertId).update({'isRead': true});
  }

  Future<void> clearAllAlerts() async {
    await _alertsRef.remove();
  }

  Future<List<Alert>> getAlerts() async {
    DatabaseEvent event = await _alertsRef.once();
    List<Alert> alerts = [];

    if (event.snapshot.value != null) {
      Map<dynamic, dynamic> values = event.snapshot.value as Map;
      values.forEach((key, value) {
        alerts.add(Alert.fromJson(Map<String, dynamic>.from(value)));
      });
    }

    // Trier par horodatage, le plus récent en premier
    alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return alerts;
  }

  Stream<List<Alert>> getAlertsStream() {
    return _alertsRef.onValue.map((event) {
      List<Alert> alerts = [];

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> values = event.snapshot.value as Map;
        values.forEach((key, value) {
          alerts.add(Alert.fromJson(Map<String, dynamic>.from(value)));
        });
      }

      // Trier par horodatage, le plus récent en premier
      alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return alerts;
    });
  }
}
