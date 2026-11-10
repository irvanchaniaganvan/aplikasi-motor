import 'trip_point.dart';

enum TripStatus { recording, paused, completed }

class Trip {
  const Trip({
    required this.id,
    required this.vehicleId,
    required this.startedAt,
    this.finishedAt,
    this.distanceMeters = 0,
    this.movingDurationSeconds = 0,
    this.averageSpeedKmh = 0,
    this.maximumSpeedKmh = 0,
    this.status = TripStatus.recording,
    this.route = const [],
  });

  final String id;
  final String vehicleId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final double distanceMeters;
  final int movingDurationSeconds;
  final double averageSpeedKmh;
  final double maximumSpeedKmh;
  final TripStatus status;
  final List<TripPoint> route;

  Duration get duration => (finishedAt ?? DateTime.now()).difference(startedAt);

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'id': id,
    'vehicleId': vehicleId,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt?.toIso8601String(),
    'distanceMeters': distanceMeters,
    'movingDurationSeconds': movingDurationSeconds,
    'averageSpeedKmh': averageSpeedKmh,
    'maximumSpeedKmh': maximumSpeedKmh,
    'status': status.name,
    'route': route.map((point) => point.toJson()).toList(),
  };

  factory Trip.fromJson(Map<String, dynamic> json) {
    final started = DateTime.tryParse(json['startedAt'] as String? ?? '');
    final finishedRaw = json['finishedAt'];
    final finished = finishedRaw is String
        ? DateTime.tryParse(finishedRaw)
        : null;
    final routeRaw = json['route'];
    final statusName = json['status'];
    if (started == null || routeRaw is! List || statusName is! String) {
      throw const FormatException('Perjalanan tersimpan tidak valid.');
    }
    final status = TripStatus.values
        .where((item) => item.name == statusName)
        .firstOrNull;
    if (status == null) {
      throw const FormatException('Status perjalanan tidak valid.');
    }
    return Trip(
      id: json['id'] as String? ?? '',
      vehicleId: json['vehicleId'] as String? ?? '',
      startedAt: started,
      finishedAt: finished,
      distanceMeters: (json['distanceMeters'] as num? ?? 0).toDouble(),
      movingDurationSeconds: json['movingDurationSeconds'] as int? ?? 0,
      averageSpeedKmh: (json['averageSpeedKmh'] as num? ?? 0).toDouble(),
      maximumSpeedKmh: (json['maximumSpeedKmh'] as num? ?? 0).toDouble(),
      status: status,
      route: routeRaw
          .map(
            (item) =>
                TripPoint.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }
}
