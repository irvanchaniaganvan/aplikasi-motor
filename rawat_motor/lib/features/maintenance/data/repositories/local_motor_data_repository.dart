import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/motor_data.dart';
import '../../domain/repositories/motor_data_repository.dart';

class LocalMotorDataRepository implements MotorDataRepository {
  LocalMotorDataRepository(this._preferences, {this.vehicleId});

  static const _storageKey = 'rawatin.motor_data.v1';
  // Kunci lama dibaca sekali agar data pengguna yang sudah ada tetap terbawa.
  static const _legacyKeys = [
    'rawat_motor.motor_data.v1',
    'rawat_motor.motor_data',
  ];
  final SharedPreferencesAsync _preferences;
  final String? vehicleId;
  String get _scopedKey =>
      vehicleId == null ? _storageKey : '$_storageKey.vehicle.$vehicleId';

  @override
  Future<MotorData?> load() async {
    var value = await _preferences.getString(_scopedKey);
    if (value == null && (vehicleId == null || vehicleId == 'vehicle-1')) {
      for (final key in _legacyKeys) {
        value = await _preferences.getString(key);
        if (value != null) break;
      }
      if (value == null) return null;
    }
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) return null;
      final data = MotorData.fromJson(decoded);
      if (!await _preferences.containsKey(_scopedKey)) {
        await _preferences.setString(_scopedKey, jsonEncode(data.toJson()));
      }
      return data;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> save(MotorData data) async {
    await _preferences.setString(_scopedKey, jsonEncode(data.toJson()));
  }

  @override
  Future<void> clear() => _preferences.remove(_scopedKey);
}
