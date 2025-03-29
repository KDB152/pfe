class SensorData {
  final double temperature;
  final double humidity;
  final double smoke;
  final double co2; // Renommé de gas à co2
  final bool isAlarmActive;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.smoke,
    required this.co2, // Renommé de gas à co2
    required this.isAlarmActive,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      smoke: (json['smoke'] as num).toDouble(),
      co2: (json['co2'] as num).toDouble(),
      isAlarmActive: json['isAlarmActive'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'smoke': smoke,
      'co2': co2, // Renommé de gas à co2
      'isAlarmActive': isAlarmActive,
    };
  }
}

class Alert {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final AlertType type;
  final bool isRead;

  Alert({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      type: AlertType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => AlertType.info,
      ),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type.toString().split('.').last,
      'isRead': isRead,
    };
  }
}

enum AlertType {
  smoke,
  co2,
  temperature,
  humidity,
  test,
  falseAlarm,
  systemFailure,
  info,
}  // Renommé de gas à co2