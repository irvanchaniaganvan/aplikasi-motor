import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/trip_point.dart';
import '../../domain/services/location_service.dart';

class FakeLocationService implements LocationService {
  FakeLocationService({this.interval = const Duration(seconds: 1)});

  final Duration interval;
  final _controller = StreamController<TripPoint>.broadcast();
  Timer? _timer;
  List<TripPoint> _sample = [];
  int _index = 0;
  DateTime? _sampleStartedAt;

  @override
  Stream<TripPoint> get positions => _controller.stream;

  @override
  Future<bool> requestWhenInUsePermission() async => true;

  @override
  Future<void> start() async {
    if (_timer != null) return;
    if (_sample.isEmpty) {
      final raw = jsonDecode(
        await rootBundle.loadString('data/sample_trip.json'),
      ) as List;
      _sample = raw
          .map(
            (item) =>
                TripPoint.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    }
    _sampleStartedAt ??= DateTime.now();
    _timer = Timer.periodic(interval, (_) {
      if (_sample.isEmpty || _index >= _sample.length) {
        _timer?.cancel();
        _timer = null;
        return;
      }
      final source = _sample[_index];
      final shiftedTime = _sampleStartedAt!.add(Duration(seconds: 6 * _index));
      _index++;
      _controller.add(
        TripPoint(
          latitude: source.latitude,
          longitude: source.longitude,
          timestamp: shiftedTime,
          accuracyMeters: source.accuracyMeters,
        ),
      );
    });
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() => _controller.close();
}
