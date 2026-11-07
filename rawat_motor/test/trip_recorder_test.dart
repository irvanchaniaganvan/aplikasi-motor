import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rawatin/features/trips/domain/entities/trip.dart';
import 'package:rawatin/features/trips/domain/entities/trip_point.dart';
import 'package:rawatin/features/trips/domain/services/location_service.dart';
import 'package:rawatin/features/trips/domain/services/trip_recorder.dart';

class _LocationService implements LocationService {
  final controller = StreamController<TripPoint>.broadcast();
  bool permitted = true;
  int starts = 0;
  int stops = 0;

  @override
  Stream<TripPoint> get positions => controller.stream;
  @override
  Future<bool> requestWhenInUsePermission() async => permitted;
  @override
  Future<void> start() async => starts++;
  @override
  Future<void> stop() async => stops++;
}

TripPoint _point(double longitude, int second) => TripPoint(
  latitude: 0,
  longitude: longitude,
  timestamp: DateTime.utc(2026).add(Duration(seconds: second)),
  accuracyMeters: 4,
);

void main() {
  test('start, pause, resume, finish menyimpan rute dan mengabaikan titik saat jeda', () async {
    final service = _LocationService();
    final recorder = TripRecorder(service);
    final start = DateTime.utc(2026);
    await recorder.start(id: 'trip-1', vehicleId: 'bike-1', now: start);
    recorder.addPoint(_point(0, 0));
    recorder.addPoint(_point(0.001, 10));
    final distanceBeforePause = recorder.distanceMeters;

    await recorder.pause();
    recorder.addPoint(_point(0.01, 20));
    expect(recorder.distanceMeters, distanceBeforePause);
    expect(recorder.current?.status, TripStatus.paused);

    await recorder.resume();
    recorder.addPoint(_point(0.0015, 20));
    recorder.addPoint(_point(0.002, 30));
    final trip = await recorder.finish(start.add(const Duration(minutes: 1)));
    expect(trip.status, TripStatus.completed);
    expect(trip.finishedAt, start.add(const Duration(minutes: 1)));
    // Rute final disederhanakan; titik tengah yang segaris boleh dihapus.
    expect(trip.route, hasLength(2));
    expect(trip.distanceMeters, greaterThan(distanceBeforePause));
    expect(service.starts, 2);
    expect(service.stops, 2);
    expect(recorder.current, isNull);
  });

  test('menolak memulai rekaman tanpa izin lokasi', () async {
    final service = _LocationService()..permitted = false;
    final recorder = TripRecorder(service);
    await expectLater(
      recorder.start(id: 'trip', vehicleId: 'bike', now: DateTime.utc(2026)),
      throwsA(isA<StateError>()),
    );
    expect(service.starts, 0);
  });
}
