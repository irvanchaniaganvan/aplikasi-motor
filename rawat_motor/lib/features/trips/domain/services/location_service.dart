import '../entities/trip_point.dart';

abstract interface class LocationService {
  Stream<TripPoint> get positions;
  Future<bool> requestWhenInUsePermission();
  Future<void> start();
  Future<void> stop();
}
