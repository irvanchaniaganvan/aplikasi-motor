import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Antarmuka untuk penyimpanan persetujuan AI dan install ID.
/// Dapat di-implementasikan oleh versi in-memory untuk pengujian.
abstract interface class AiConsentStorage {
  Future<bool> hasConsent();
  Future<void> setConsent(bool consent);
  Future<String> getOrCreateInstallId();
}

/// Implementasi produksi berbasis SharedPreferencesAsync, selaras dengan
/// `LocalProfileRepository`.
class LocalAiConsentStorage implements AiConsentStorage {
  const LocalAiConsentStorage();

  static const _consentKey = 'ai_oil_guide_consent';
  static const _installIdKey = 'rawatin_install_id';

  SharedPreferencesAsync get _preferences => SharedPreferencesAsync();

  @override
  Future<bool> hasConsent() async {
    return await _preferences.getBool(_consentKey) ?? false;
  }

  @override
  Future<void> setConsent(bool consent) async {
    await _preferences.setBool(_consentKey, consent);
  }

  @override
  Future<String> getOrCreateInstallId() async {
    final existing = await _preferences.getString(_installIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final newId = _generateUuidV4();
    await _preferences.setString(_installIdKey, newId);
    return newId;
  }

  /// Menghasilkan RFC 4122 UUID v4 acak tanpa dependensi eksternal.
  static String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // versi 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // varian RFC 4122
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}
