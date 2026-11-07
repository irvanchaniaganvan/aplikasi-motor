import 'package:flutter_test/flutter_test.dart';
import 'package:rawatin/features/trips/domain/entities/trip_point.dart';
import 'package:rawatin/features/trips/domain/services/route_math.dart';

TripPoint point(double lat, double lon, int second, {double accuracy = 5}) =>
    TripPoint(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime.utc(2026, 1, 1).add(Duration(seconds: second)),
      accuracyMeters: accuracy,
    );

void main() {
  group('route math', () {
    test('menghitung jarak Haversine antartitik', () {
      final distance = haversineMeters(point(0, 0, 0), point(0, 0.01, 1));
      expect(distance, closeTo(1112, 2));
    });

    test('menolak akurasi buruk, jitter, timestamp terbalik, dan lonjakan', () {
      final start = point(-6, 106, 0);
      expect(
        isAcceptablePoint(point(-6.001, 106, 1, accuracy: 51), start),
        isFalse,
      );
      expect(isAcceptablePoint(point(-5.999999, 106, 1), start), isFalse);
      expect(isAcceptablePoint(point(-6.001, 106, -1), start), isFalse);
      expect(isAcceptablePoint(point(-5.99, 106, 1), start), isFalse);
    });

    test(
      'Douglas-Peucker mempertahankan ujung dan menghapus titik segaris',
      () {
        final route = [
          point(0, 0, 0),
          point(0, 0.001, 1),
          point(0, 0.002, 2),
          point(0, 0.003, 3),
        ];
        final simplified = simplifyRoute(route, toleranceMeters: 2);
        expect(simplified, [route.first, route.last]);
      },
    );
  });
}
