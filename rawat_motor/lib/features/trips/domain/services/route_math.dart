import 'dart:math' as math;

import '../entities/trip_point.dart';

abstract final class TripThresholds {
  static const maxAccuracyMeters = 50.0;
  static const maxSpeedKmh = 200.0;
  static const stationaryJitterMeters = 8.0;
  static const movingSpeedKmh = 3.0;
  static const maxPoints = 2000;
  static const simplifyToleranceMeters = 8.0;
}

double haversineMeters(TripPoint a, TripPoint b) {
  const earthRadius = 6371000.0;
  final lat1 = _radians(a.latitude);
  final lat2 = _radians(b.latitude);
  final deltaLat = _radians(b.latitude - a.latitude);
  final deltaLon = _radians(b.longitude - a.longitude);
  final h =
      math.pow(math.sin(deltaLat / 2), 2) +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(deltaLon / 2), 2);
  return 2 * earthRadius * math.asin(math.sqrt(h.clamp(0.0, 1.0)));
}

double _radians(double degrees) => degrees * math.pi / 180;

bool isAcceptablePoint(TripPoint point, TripPoint? previous) {
  if (point.accuracyMeters > TripThresholds.maxAccuracyMeters) return false;
  if (previous == null) return true;
  final seconds =
      point.timestamp.difference(previous.timestamp).inMilliseconds / 1000;
  if (seconds <= 0) return false;
  final distance = haversineMeters(previous, point);
  if (distance < TripThresholds.stationaryJitterMeters) return false;
  return distance / seconds * 3.6 <= TripThresholds.maxSpeedKmh;
}

List<TripPoint> simplifyRoute(
  List<TripPoint> points, {
  double toleranceMeters = TripThresholds.simplifyToleranceMeters,
}) {
  if (points.length <= 2) return List.unmodifiable(points);
  final keep = List<bool>.filled(points.length, false)..first = true;
  keep[points.length - 1] = true;
  final stack = <(int, int)>[(0, points.length - 1)];
  while (stack.isNotEmpty) {
    final (start, end) = stack.removeLast();
    var maxDistance = 0.0;
    var maxIndex = -1;
    for (var i = start + 1; i < end; i++) {
      final distance = _perpendicularMeters(
        points[i],
        points[start],
        points[end],
      );
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }
    if (maxDistance > toleranceMeters && maxIndex >= 0) {
      keep[maxIndex] = true;
      stack
        ..add((start, maxIndex))
        ..add((maxIndex, end));
    }
  }
  return List.unmodifiable([
    for (var i = 0; i < points.length; i++)
      if (keep[i]) points[i],
  ]);
}

double _perpendicularMeters(TripPoint p, TripPoint a, TripPoint b) {
  final meanLat = _radians((a.latitude + b.latitude + p.latitude) / 3);
  double x(TripPoint point) =>
      _radians(point.longitude) * math.cos(meanLat) * 6371000;
  double y(TripPoint point) => _radians(point.latitude) * 6371000;
  final ax = x(a), ay = y(a), bx = x(b), by = y(b), px = x(p), py = y(p);
  final dx = bx - ax, dy = by - ay;
  if (dx == 0 && dy == 0)
    return math.sqrt(math.pow(px - ax, 2) + math.pow(py - ay, 2));
  final t = (((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)).clamp(
    0.0,
    1.0,
  );
  final ex = px - (ax + t * dx), ey = py - (ay + t * dy);
  return math.sqrt(ex * ex + ey * ey);
}
