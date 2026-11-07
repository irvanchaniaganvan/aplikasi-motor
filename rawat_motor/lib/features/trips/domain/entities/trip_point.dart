class TripPoint {
  const TripPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracyMeters;

  Map<String, Object> toJson() => {
    'lat': latitude,
    'lon': longitude,
    'at': timestamp.toIso8601String(),
    'accuracy': accuracyMeters,
  };

  factory TripPoint.fromJson(Map<String, dynamic> json) {
    final lat = json['lat'];
    final lon = json['lon'];
    final at = json['at'];
    final accuracy = json['accuracy'];
    final time = at is String ? DateTime.tryParse(at) : null;
    if (lat is! num || lon is! num || time == null || accuracy is! num) {
      throw const FormatException('Titik perjalanan tidak valid.');
    }
    return TripPoint(
      latitude: lat.toDouble(),
      longitude: lon.toDouble(),
      timestamp: time,
      accuracyMeters: accuracy.toDouble(),
    );
  }
}
