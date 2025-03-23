import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sensor_data_model.dart';

class SensorService {
  // Singleton pattern pour SensorService
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  // Clés pour SharedPreferences
  static const String _sensorDataKey = 'sensor_data';
  static const String _alertsKey = 'alerts';

  // Stream controller pour les mises à jour de capteurs
  final _sensorDataStreamController = StreamController<SensorData>.broadcast();
  Stream<SensorData> get sensorDataStream => _sensorDataStreamController.stream;

  // Stream controller pour les alertes
  final _alertsStreamController = StreamController<List<Alert>>.broadcast();
  Stream<List<Alert>> get alertsStream => _alertsStreamController.stream;

  // Timer pour simuler les mises à jour des capteurs
  Timer? _updateTimer;

  // Dernières valeurs de capteurs
  SensorData _lastSensorData = SensorData(
    temperature: 22.0,
    humidity: 45.0,
    smoke: 0.0,
    co2: 850.0, // Valeur initiale de CO2 adaptée
    isAlarmActive: false,
  );

  // Liste des alertes
  List<Alert> _alerts = [];

  // Initialiser le service
  Future<void> initialize() async {
    // Charger les données de capteurs depuis SharedPreferences
    await _loadSensorData();
    await _loadAlerts();

    // Démarrer le timer pour simuler les mises à jour des capteurs
    _startUpdateTimer();
  }

  // Charger les données des capteurs depuis SharedPreferences
  Future<void> _loadSensorData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sensorDataString = prefs.getString(_sensorDataKey);

      if (sensorDataString != null) {
        final sensorDataMap =
            jsonDecode(sensorDataString) as Map<String, dynamic>;
        _lastSensorData = SensorData.fromJson(sensorDataMap);
        _sensorDataStreamController.add(_lastSensorData);
      }
    } catch (e) {
      print('Erreur lors du chargement des données de capteurs: $e');
    }
  }

  // Enregistrer les données des capteurs dans SharedPreferences
  Future<void> _saveSensorData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _sensorDataKey,
        jsonEncode(_lastSensorData.toJson()),
      );
    } catch (e) {
      print('Erreur lors de l\'enregistrement des données de capteurs: $e');
    }
  }

  // Charger les alertes depuis SharedPreferences
  Future<void> _loadAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsString = prefs.getString(_alertsKey);

      if (alertsString != null) {
        final alertsList = jsonDecode(alertsString) as List;
        _alerts = alertsList.map((item) => Alert.fromJson(item)).toList();
        _alertsStreamController.add(_alerts);
      }
    } catch (e) {
      print('Erreur lors du chargement des alertes: $e');
    }
  }

  // Enregistrer les alertes dans SharedPreferences
  Future<void> _saveAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = _alerts.map((alert) => alert.toJson()).toList();
      await prefs.setString(_alertsKey, jsonEncode(alertsJson));
    } catch (e) {
      print('Erreur lors de l\'enregistrement des alertes: $e');
    }
  }

  // Démarrer le timer pour simuler les mises à jour des capteurs
  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _simulateSensorUpdate();
    });
  }

  // Simuler une mise à jour des capteurs
  void _simulateSensorUpdate() {
    // Générer de nouvelles valeurs simulées pour les capteurs
    final random = DateTime.now().millisecondsSinceEpoch % 100 / 100;
    final random2 =
        (DateTime.now().millisecondsSinceEpoch % 90 / 100) * 2 -
        1; // Entre -1 et 1

    // Variation de la température entre 18 et 60
    double newTemp = _lastSensorData.temperature + random2 * 2;
    if (newTemp < 18) newTemp = 18 + random;
    if (newTemp > 60) newTemp = 60 - random;

    // Variation de l'humidité entre 30 et 80
    double newHumidity = _lastSensorData.humidity + random2 * 3;
    if (newHumidity < 30) newHumidity = 30 + random;
    if (newHumidity > 80) newHumidity = 80 - random;

    // Variation du niveau de fumée entre 0 et 100%
    double newSmoke = _lastSensorData.smoke;
    // Généralement pas de fumée, mais parfois une variation
    if (random < 0.1) {
      // 10% de chance de changer significativement
      newSmoke = newSmoke + random2 * 15;
    } else {
      // Petites variations le reste du temps
      newSmoke = newSmoke + random2 * 1;
    }
    if (newSmoke < 0) newSmoke = 0;
    if (newSmoke > 100) newSmoke = 100;

    // Variation du CO2 entre 800 et 1300
    double newCO2 = _lastSensorData.co2 + random2 * 50;
    if (newCO2 < 800) newCO2 = 800 + random * 50;
    if (newCO2 > 1300) newCO2 = 1300 - random * 50;

    // Mettre à jour les données des capteurs
    _lastSensorData = SensorData(
      temperature: double.parse(newTemp.toStringAsFixed(1)),
      humidity: double.parse(newHumidity.toStringAsFixed(1)),
      smoke: double.parse(newSmoke.toStringAsFixed(1)),
      co2: double.parse(newCO2.toStringAsFixed(1)),
      isAlarmActive:
          newSmoke > 50 || newTemp > 50 || newHumidity > 65 || newCO2 > 1200,
    );

    // Vérifier si une alerte doit être générée
    _checkAlertConditions();

    // Enregistrer les données et les envoyer aux écouteurs
    _saveSensorData();
    _sensorDataStreamController.add(_lastSensorData);
  }

  // Vérifier si une alerte doit être générée
  void _checkAlertConditions() {
    final now = DateTime.now();

    // Alerte de fumée
    if (_lastSensorData.smoke > 50) {
      _addAlert(
        Alert(
          id: 'smoke_${now.millisecondsSinceEpoch}',
          title: 'Détection de fumée',
          description:
              'Niveau de fumée détecté: ${_lastSensorData.smoke.toStringAsFixed(1)}%',
          timestamp: now,
          type: AlertType.smoke,
        ),
      );
    }

    // Alerte de CO2
    if (_lastSensorData.co2 > 1200) {
      _addAlert(
        Alert(
          id: 'co2_${now.millisecondsSinceEpoch}',
          title: 'Niveau de CO2 élevé',
          description:
              'Niveau de CO2: ${_lastSensorData.co2.toStringAsFixed(1)} ppm',
          timestamp: now,
          type: AlertType.co2,
        ),
      );
    }

    // Alerte de température
    if (_lastSensorData.temperature > 50) {
      _addAlert(
        Alert(
          id: 'temp_${now.millisecondsSinceEpoch}',
          title: 'Température très élevée',
          description:
              'Température: ${_lastSensorData.temperature.toStringAsFixed(1)}°C',
          timestamp: now,
          type:
              AlertType
                  .temperature, // Utilisation du type existant le plus proche
        ),
      );
    }

    // Alerte d'humidité
    if (_lastSensorData.humidity > 65) {
      _addAlert(
        Alert(
          id: 'humidity_${now.millisecondsSinceEpoch}',
          title: 'Humidité élevée',
          description:
              'Niveau d\'humidité: ${_lastSensorData.humidity.toStringAsFixed(1)}%',
          timestamp: now,
          type:
              AlertType.humidity, // Utilisation du type existant le plus proche
        ),
      );
    }
  }

  // Ajouter une alerte à la liste
  void _addAlert(Alert alert) {
    _alerts.insert(0, alert);

    // Limiter le nombre d'alertes stockées
    if (_alerts.length > 50) {
      _alerts = _alerts.sublist(0, 50);
    }

    _saveAlerts();
    _alertsStreamController.add(_alerts);
  }

  // Marquer une alerte comme lue
  Future<void> markAlertAsRead(String alertId) async {
    final alertIndex = _alerts.indexWhere((alert) => alert.id == alertId);
    if (alertIndex != -1) {
      final updatedAlert = Alert(
        id: _alerts[alertIndex].id,
        title: _alerts[alertIndex].title,
        description: _alerts[alertIndex].description,
        timestamp: _alerts[alertIndex].timestamp,
        type: _alerts[alertIndex].type,
        isRead: true,
      );

      _alerts[alertIndex] = updatedAlert;
      await _saveAlerts();
      _alertsStreamController.add(_alerts);
    }
  }

  // Effacer toutes les alertes
  Future<void> clearAllAlerts() async {
    _alerts = [];
    await _saveAlerts();
    _alertsStreamController.add(_alerts);
  }

  // Obtenir la dernière données des capteurs
  SensorData getLastSensorData() {
    return _lastSensorData;
  }

  // Obtenir la liste des alertes
  List<Alert> getAlerts() {
    return List.from(_alerts);
  }

  // Effectuer un test du système
  Future<void> runSystemTest() async {
    final now = DateTime.now();

    // Ajouter une alerte de test
    _addAlert(
      Alert(
        id: 'test_${now.millisecondsSinceEpoch}',
        title: 'Test du système',
        description:
            'Test de routine du système de détection d\'incendie complété avec succès.',
        timestamp: now,
        type: AlertType.test,
      ),
    );

    // Retourner après un délai pour simuler le test
    return Future.delayed(const Duration(seconds: 2));
  }

  // Disposer des ressources
  void dispose() {
    _updateTimer?.cancel();
    _sensorDataStreamController.close();
    _alertsStreamController.close();
  }
}
