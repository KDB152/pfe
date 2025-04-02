// models/fire_detection_model.dart
class FireDetectionResult {
  final bool isFireDetected;
  final double confidence;
  final DateTime timestamp;
  final String? imageUrl;

  FireDetectionResult({
    required this.isFireDetected,
    required this.confidence,
    required this.timestamp,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'isFireDetected': isFireDetected,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }

  factory FireDetectionResult.fromJson(Map<String, dynamic> json) {
    return FireDetectionResult(
      isFireDetected: json['isFireDetected'],
      confidence: json['confidence'],
      timestamp: DateTime.parse(json['timestamp']),
      imageUrl: json['imageUrl'],
    );
  }
}
