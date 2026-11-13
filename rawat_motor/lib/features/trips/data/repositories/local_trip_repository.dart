import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';

class LocalTripRepository implements TripRepository {
  LocalTripRepository({Future<Directory> Function()? documentsDirectory})
    : _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _documentsDirectory;

  Future<File> _file(String vehicleId) async {
    final dir = await _documentsDirectory();
    final trips = Directory('${dir.path}${Platform.pathSeparator}trips');
    await trips.create(recursive: true);
    final safeId = vehicleId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return File('${trips.path}${Platform.pathSeparator}$safeId.json');
  }

  @override
  Future<List<Trip>> load(String vehicleId) async {
    final file = await _file(vehicleId);
    if (!await file.exists()) return [];
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return [];
      final version = decoded['schemaVersion'];
      if (version != 1) return [];
      final rawTrips = decoded['trips'];
      if (rawTrips is! List) return [];
      return rawTrips
          .map((item) => Trip.fromJson(Map<String, dynamic>.from(item as Map)))
          .where((trip) => trip.vehicleId == vehicleId)
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  @override
  Future<void> save(Trip trip) async {
    final file = await _file(trip.vehicleId);
    final trips = await load(trip.vehicleId);
    final updated = [trip, ...trips.where((item) => item.id != trip.id)];
    await file.writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'trips': updated.map((item) => item.toJson()).toList(),
      }),
      flush: true,
    );
  }

  @override
  Future<void> delete(String vehicleId, String tripId) async {
    final file = await _file(vehicleId);
    final remaining = (await load(vehicleId))
        .where((trip) => trip.id != tripId);
    await file.writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'trips': remaining.map((item) => item.toJson()).toList(),
      }),
      flush: true,
    );
  }

  /// Menghapus arsip perjalanan lokal milik kendaraan yang dihapus.
  Future<void> deleteVehicleTrips(String vehicleId) async {
    final file = await _file(vehicleId);
    if (await file.exists()) await file.delete();
  }
}
