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
    final value = await _preferences.getString(_storageKey);
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) return null;
      return MotorData.fromJson(decoded);
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
