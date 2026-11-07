import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../domain/entities/trip_point.dart';
import '../../domain/services/location_service.dart';

class GeolocatorLocationService implements LocationService {
  final _controller = StreamController<TripPoint>.broadcast();
  StreamSubscription<Position>? _subscription;
  @override
  Stream<TripPoint> get positions => _controller.stream;

  @override
  Future<bool> requestWhenInUsePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  @override
  Future<void> start() async {
    if (_subscription != null) return;
    _subscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
          ),
        ).listen(
          (position) => _controller.add(
            TripPoint(
              latitude: position.latitude,
              longitude: position.longitude,
              timestamp: position.timestamp,
              accuracyMeters: position.accuracy,
            ),
          ),
          onError: _controller.addError,
        );
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
