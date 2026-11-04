import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/driver_motor_profile.dart';

class LocalProfileRepository {
  LocalProfileRepository(this._preferences);
  final SharedPreferencesAsync _preferences;

  Future<String?> loadAccountEmail() => _preferences.getString('account.email');

  Future<String?> loadAccountPassword() => _preferences.getString('account.password');

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
    if (name == null || brand == null || model == null || year == null) return null;
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
}
