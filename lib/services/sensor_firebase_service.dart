import 'dart:async';
import '../models/sensor_data_model.dart';
import 'firebase_database_service.dart';

class SensorFirebaseService {
  // Singleton pattern
  static final SensorFirebaseService _instance =
      SensorFirebaseService._internal();
  factory SensorFirebaseService() => _instance;
  SensorFirebaseService._internal();

  // Instance du service Firebase
  final FirebaseDatabaseService _firebaseService = FirebaseDatabaseService();

  // Stream controllers
  final _sensorDataStreamController = StreamController<SensorData>.broadcast();
  Stream<SensorData> get sensorDataStream => _sensorDataStreamController.stream;

  final _alertsStreamController = StreamController<List<Alert>>.broadcast();
  Stream<List<Alert>> get alertsStream => _alertsStreamController.stream;

  // Timer pour simuler les mises à jour des capteurs
  Timer? _updateTimer;

  // Dernières valeurs de capteurs
  SensorData _lastSensorData = SensorData(
    temperature: 22.0,
    humidity: 45.0,
    smoke: 0.0,
    co2: 850.0,
    isAlarmActive: false,
  );

  // Liste des alertes
  List<Alert> _alerts = [];

  // Abonnements aux streams Firebase
  StreamSubscription? _sensorDataSubscription;
  StreamSubscription? _alertsSubscription;

  // Initialiser le service
  Future<void> initialize() async {
    // Charger les données initiales depuis Firebase
    _lastSensorData = await _firebaseService.getSensorData();
    _alerts = await _firebaseService.getAlerts();

    // S'abonner aux changements de données
    _sensorDataSubscription = _firebaseService.getSensorDataStream().listen((
      data,
    ) {
      _lastSensorData = data;
      _sensorDataStreamController.add(data);
    });

    _alertsSubscription = _firebaseService.getAlertsStream().listen((alerts) {
      _alerts = alerts;
      _alertsStreamController.add(alerts);
    });

    // Démarrer le timer pour simuler les mises à jour des capteurs
    _startUpdateTimer();
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

    // Enregistrer les données dans Firebase
    _firebaseService.saveSensorData(_lastSensorData);
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
          type: AlertType.temperature,
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
          type: AlertType.humidity,
        ),
      );
    }
  }

  // Ajouter une alerte à la liste
  void _addAlert(Alert alert) {
    // Sauvegarder l'alerte dans Firebase
    _firebaseService.saveAlert(alert);
  }

  // Marquer une alerte comme lue
  Future<void> markAlertAsRead(String alertId) async {
    await _firebaseService.markAlertAsRead(alertId);
  }

  // Effacer toutes les alertes
  Future<void> clearAllAlerts() async {
    await _firebaseService.clearAllAlerts();
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
    _sensorDataSubscription?.cancel();
    _alertsSubscription?.cancel();
    _sensorDataStreamController.close();
    _alertsStreamController.close();
  }
}
