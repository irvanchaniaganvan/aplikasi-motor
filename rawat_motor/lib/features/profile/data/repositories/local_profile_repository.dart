import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/driver_motor_profile.dart';

class LocalProfileRepository {
  LocalProfileRepository(this._preferences);
  final SharedPreferencesAsync _preferences;
  static const _profilesKey = 'rawatin.profiles.v1';
  static const _selectedProfileKey = 'rawatin.selected_profile.v1';

  Future<List<DriverMotorProfile>> loadAll() async {
    final encoded = await _preferences.getString(_profilesKey);
    if (encoded != null) {
      try {
        final decoded = jsonDecode(encoded) as List;
        return decoded
            .map(
              (item) =>
                  _profileFromJson(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      } on Object {
        // Fall through to the legacy single-profile record for safe migration.
      }
    }
    final legacy = await load();
    if (legacy == null) return const [];
    final migrated = _withId(
      legacy,
      legacy.id.isEmpty ? 'vehicle-1' : legacy.id,
    );
    await saveAll([migrated]);
    await setSelectedProfileId(migrated.id);
    return [migrated];
  }

  Future<String?> loadSelectedProfileId() =>
      _preferences.getString(_selectedProfileKey);

  Future<void> setSelectedProfileId(String id) =>
      _preferences.setString(_selectedProfileKey, id);

  Future<void> saveAll(List<DriverMotorProfile> profiles) =>
      _preferences.setString(
        _profilesKey,
        jsonEncode(profiles.map(_profileToJson).toList()),
      );

  Future<void> saveVehicle(DriverMotorProfile profile) async {
    final vehicles = await loadAll();
    final normalized = _withId(
      profile,
      profile.id.isEmpty
          ? DateTime.now().microsecondsSinceEpoch.toString()
          : profile.id,
    );
    final index = vehicles.indexWhere((item) => item.id == normalized.id);
    if (index < 0) {
      vehicles.add(normalized);
    } else {
      vehicles[index] = normalized;
    }
    await saveAll(vehicles);
    await setSelectedProfileId(normalized.id);
    await _saveLegacyProfile(normalized);
  }

  Future<void> deleteVehicle(String id) async {
    final vehicles = await loadAll();
    vehicles.removeWhere((item) => item.id == id);
    await saveAll(vehicles);
    await _preferences.remove('rawatin.motor_data.v1.vehicle.$id');
    if (id == 'vehicle-1') {
      await _preferences.remove('rawatin.motor_data.v1');
      await _preferences.remove('rawat_motor.motor_data.v1');
      await _preferences.remove('rawat_motor.motor_data');
    }
    if (await loadSelectedProfileId() == id && vehicles.isNotEmpty) {
      await setSelectedProfileId(vehicles.first.id);
      await _saveLegacyProfile(vehicles.first);
    } else if (await loadSelectedProfileId() == id) {
      await _preferences.remove(_selectedProfileKey);
      await clearProfile();
    }
  }

  Future<String?> loadAccountEmail() => _preferences.getString('account.email');

  Future<String?> loadAccountPassword() =>
      _preferences.getString('account.password');

  Future<bool> isSignedIn() async {
    final signedIn = await _preferences.getBool('account.signed_in');
    if (signedIn != null) return signedIn;
    // Data lama belum punya penanda sesi; anggap sudah masuk jika email ada.
    return (await loadAccountEmail()) != null;
  }

  Future<void> setSignedIn(bool value) =>
      _preferences.setBool('account.signed_in', value);

  Future<void> saveAccountCredentials(String email, String password) async {
    await _preferences.setString('account.email', email.trim().toLowerCase());
    await _preferences.setString('account.password', password);
    await setSignedIn(true);
  }

  Future<void> saveAccountPassword(String password) =>
      _preferences.setString('account.password', password);

  Future<void> clearProfile() async {
    await _preferences.remove('profile.driver_name');
    await _preferences.remove('profile.motor_brand');
    await _preferences.remove('profile.motor_model');
    await _preferences.remove('profile.motor_year');
    await _preferences.remove('profile.motor_type');
    await _preferences.remove('profile.cooling');
    await _preferences.remove('profile.front_brake');
  }

  Future<void> clearAccount() async {
    await _preferences.remove('account.email');
    await _preferences.remove('account.password');
    await _preferences.remove('account.signed_in');
  }

  Future<DriverMotorProfile?> load() async {
    final name = await _preferences.getString('profile.driver_name');
    final brand = await _preferences.getString('profile.motor_brand');
    final model = await _preferences.getString('profile.motor_model');
    final year = await _preferences.getInt('profile.motor_year');
    if (name == null || brand == null || model == null || year == null) {
      return null;
    }
    return DriverMotorProfile(
      driverName: name,
      brand: brand,
      model: model,
      year: year,
      motorType: await _preferences.getString('profile.motor_type'),
      cooling: await _preferences.getString('profile.cooling'),
      frontBrake: await _preferences.getString('profile.front_brake'),
    );
  }

  Future<void> save(DriverMotorProfile profile) async {
    await _saveLegacyProfile(profile);
    await saveVehicle(profile);
  }

  Future<void> _saveLegacyProfile(DriverMotorProfile profile) async {
    await _preferences.setString('profile.driver_name', profile.driverName);
    await _preferences.setString('profile.motor_brand', profile.brand);
    await _preferences.setString('profile.motor_model', profile.model);
    await _preferences.setInt('profile.motor_year', profile.year);
    await _saveOptional('profile.motor_type', profile.motorType);
    await _saveOptional('profile.cooling', profile.cooling);
    await _saveOptional('profile.front_brake', profile.frontBrake);
  }

  Future<void> _saveOptional(String key, String? value) async {
    if (value == null) {
      await _preferences.remove(key);
      return;
    }
    await _preferences.setString(key, value);
  }

  DriverMotorProfile _withId(DriverMotorProfile p, String id) =>
      DriverMotorProfile(
        id: id,
        driverName: p.driverName,
        brand: p.brand,
        model: p.model,
        year: p.year,
        motorType: p.motorType,
        cooling: p.cooling,
        frontBrake: p.frontBrake,
        maintenanceMotorId: p.maintenanceMotorId,
        transmission: p.transmission,
      );

  Map<String, Object?> _profileToJson(DriverMotorProfile p) => {
    'id': p.id,
    'driverName': p.driverName,
    'brand': p.brand,
    'model': p.model,
    'year': p.year,
    'motorType': p.motorType,
    'cooling': p.cooling,
    'frontBrake': p.frontBrake,
    'maintenanceMotorId': p.maintenanceMotorId,
    'transmission': p.transmission,
  };

  DriverMotorProfile _profileFromJson(Map<String, dynamic> json) =>
      DriverMotorProfile(
        id: json['id'] as String? ?? '',
        driverName: json['driverName'] as String,
        brand: json['brand'] as String,
        model: json['model'] as String,
        year: json['year'] as int,
        motorType: json['motorType'] as String?,
        cooling: json['cooling'] as String?,
        frontBrake: json['frontBrake'] as String?,
        maintenanceMotorId: json['maintenanceMotorId'] as String?,
        transmission: json['transmission'] as String?,
      );
}
