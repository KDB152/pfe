class SensorData {
  final double temperature;
  final double humidity;
  final double smoke;
  final double co2;
  final bool isAlarmActive;
  final DateTime timestamp;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.smoke,
    required this.co2,
    required this.isAlarmActive,
    required this.timestamp,
  });

  SensorData copyWith({
    double? temperature,
    double? humidity,
    double? smoke,
    double? co2,
    bool? isAlarmActive,
    DateTime? timestamp,
  }) {
    return SensorData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      smoke: smoke ?? this.smoke,
      co2: co2 ?? this.co2,
      isAlarmActive: isAlarmActive ?? this.isAlarmActive,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: json['temperature']?.toDouble() ?? 0.0,
      humidity: json['humidity']?.toDouble() ?? 0.0,
      smoke: json['smoke']?.toDouble() ?? 0.0,
      co2: json['co2']?.toDouble() ?? 0.0,
      isAlarmActive: json['isAlarmActive'] ?? false,
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'smoke': smoke,
      'co2': co2,
      'isAlarmActive': isAlarmActive,
      'DateTime': timestamp.toIso8601String(),
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
  final String? commentId;
  final String? adminResponse;

  Alert({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.commentId,
    this.adminResponse,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      type: AlertType.values.firstWhere(
        (e) => e.toString() == 'AlertType.${json['type']}',
        orElse: () => AlertType.info,
      ),
      isRead: json['isRead'] ?? false,
      commentId: json['commentId'],
      adminResponse: json['adminResponse'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'isRead': isRead,
      'commentId': commentId,
      'adminResponse': adminResponse,
    };
  }
}

enum AlertType {
  smoke,
  co2,
  test,
  humidity,
  temperature,
  falseAlarm,
  systemFailure,
  info,
  adminResponse,
}
