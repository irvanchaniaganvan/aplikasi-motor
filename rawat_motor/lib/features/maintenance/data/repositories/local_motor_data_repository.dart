import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/motor_data.dart';
import '../../domain/repositories/motor_data_repository.dart';

class LocalMotorDataRepository implements MotorDataRepository {
  LocalMotorDataRepository(this._preferences);

  static const _storageKey = 'rawat_motor.motor_data.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<MotorData?> load() async {
    var value = await _preferences.getString(_storageKey);
    if (value == null) {
      // Migrasi: versi lama pernah menyimpan data pada key tanpa suffix versi.
      final legacy = await _preferences.getString('rawat_motor.motor_data');
      if (legacy == null) return null;
      value = legacy;
    }
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) return null;
      final data = MotorData.fromJson(decoded);
      if (!await _preferences.containsKey(_storageKey)) {
        await _preferences.setString(_storageKey, jsonEncode(data.toJson()));
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
    await _preferences.setString(_storageKey, jsonEncode(data.toJson()));
  }

  @override
  Future<void> clear() => _preferences.remove(_storageKey);
}
