import '../entities/trip.dart';

abstract interface class TripRepository {
  Future<List<Trip>> load(String vehicleId);
  Future<void> save(Trip trip);
  Future<void> delete(String vehicleId, String tripId);
}
