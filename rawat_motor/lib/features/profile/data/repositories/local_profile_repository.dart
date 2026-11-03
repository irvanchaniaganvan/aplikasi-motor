import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/driver_motor_profile.dart';

class LocalProfileRepository {
  LocalProfileRepository(this._preferences);
  final SharedPreferencesAsync _preferences;

  Future<String?> loadAccountEmail() => _preferences.getString('account.email');

  Future<void> saveAccountEmail(String email) =>
      _preferences.setString('account.email', email);

  Future<void> clearProfile() async {
    await _preferences.remove('profile.driver_name');
    await _preferences.remove('profile.motor_brand');
    await _preferences.remove('profile.motor_model');
    await _preferences.remove('profile.motor_year');
  }

  Future<void> clearAccount() => _preferences.remove('account.email');

  Future<DriverMotorProfile?> load() async {
    final name = await _preferences.getString('profile.driver_name');
    final brand = await _preferences.getString('profile.motor_brand');
    final model = await _preferences.getString('profile.motor_model');
    final year = await _preferences.getInt('profile.motor_year');
    if (name == null || brand == null || model == null || year == null) return null;
    return DriverMotorProfile(driverName: name, brand: brand, model: model, year: year);
  }

  Future<void> save(DriverMotorProfile profile) async {
    await _preferences.setString('profile.driver_name', profile.driverName);
    await _preferences.setString('profile.motor_brand', profile.brand);
    await _preferences.setString('profile.motor_model', profile.model);
    await _preferences.setInt('profile.motor_year', profile.year);
  }
}
