import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/oil_specification.dart';
import '../../domain/services/oil_specification_service.dart';

/// Sumber spesifikasi oli online dengan cache lokal dan fallback katalog.
///
/// Endpoint backend yang diharapkan:
/// `GET {baseUrl}/oil-specifications/{motorId}?year=2024`
///
/// Respon dapat berupa objek spesifikasi langsung atau objek yang memiliki
/// field `oil_spec`. Contoh objek spesifikasi:
/// `{sae, jaso, volume, verified, source, source_url, updated_at}`.
class HttpOilSpecificationService implements OilSpecificationService {
  HttpOilSpecificationService({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 12),
    HttpClient? client,
    SharedPreferencesAsync? preferences,
    this.fetcher,
  }) : _client = client ?? HttpClient(),
       _preferences = preferences ?? SharedPreferencesAsync();

  final String baseUrl;
  final Duration timeout;
  final HttpClient _client;
  final SharedPreferencesAsync _preferences;

  /// Transport opsional untuk test tanpa jaringan nyata.
  final Future<Map<String, dynamic>?> Function(Uri uri)? fetcher;

  static const _cachePrefix = 'rawatin.oil_specification.cache.';

  @override
  Future<OilSpecificationResult> load({
    required String motorId,
    required String motorName,
    required int year,
    OilSpecification? localSpecification,
    bool refresh = false,
  }) async {
    final cacheKey = _cacheKey(motorId: motorId, year: year);
    final online = await _fetch(
      motorId: motorId,
      motorName: motorName,
      year: year,
    );
    if (online != null) {
      await _writeCache(cacheKey, online);
      return OilSpecificationResult(
        specification: online,
        sourceType: OilSpecificationSourceType.online,
      );
    }

    final cached = await _readCache(cacheKey);
    if (cached != null) {
      return OilSpecificationResult(
        specification: cached,
        sourceType: OilSpecificationSourceType.cache,
      );
    }

    if (localSpecification != null) {
      return OilSpecificationResult(
        specification: localSpecification,
        sourceType: OilSpecificationSourceType.local,
      );
    }
    return const OilSpecificationResult(
      specification: null,
      sourceType: OilSpecificationSourceType.unavailable,
    );
  }

  Future<OilSpecification?> _fetch({
    required String motorId,
    required String motorName,
    required int year,
  }) async {
    if (baseUrl.trim().isEmpty) return null;
    try {
      final endpoint = _endpoint(
        motorId: motorId,
        motorName: motorName,
        year: year,
      );
      if (fetcher != null) {
        return _parseSpecification(await fetcher!(endpoint));
      }
      final request = await _client.getUrl(endpoint).timeout(timeout);
      request.headers.add(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) return null;
      final body = await utf8.decodeStream(response);
      final decoded = jsonDecode(body);
      return _parseSpecification(decoded);
    } on SocketException {
      return null;
    } on TimeoutException {
      return null;
    } on FormatException {
      return null;
    } catch (_) {
      return null;
    }
  }

  OilSpecification? _parseSpecification(Object? decoded) {
    if (decoded is! Map) return null;
    final rawSpec =
        decoded['oil_spec'] ?? decoded['spesifikasi_oli'] ?? decoded;
    if (rawSpec is! Map) return null;
    final spec = OilSpecification.fromJson(Map<String, dynamic>.from(rawSpec));
    if (spec.sae.isEmpty || spec.jaso.isEmpty || spec.volume.isEmpty) {
      return null;
    }
    return spec;
  }

  Uri _endpoint({
    required String motorId,
    required String motorName,
    required int year,
  }) {
    final clean = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final base = Uri.parse(clean);
    final path =
        '${base.path}/oil-specifications/${Uri.encodeComponent(motorId)}';
    return base.replace(
      path: path,
      queryParameters: {'year': '$year', 'motor_name': motorName},
    );
  }

  String _cacheKey({required String motorId, required int year}) =>
      '$_cachePrefix${Uri.encodeComponent(motorId)}.$year';

  Future<OilSpecification?> _readCache(String key) async {
    final raw = await _preferences.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final spec = OilSpecification.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      return spec.sae.isEmpty || spec.jaso.isEmpty || spec.volume.isEmpty
          ? null
          : spec;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String key, OilSpecification specification) async {
    try {
      await _preferences.setString(key, jsonEncode(specification.toJson()));
    } catch (_) {
      // Cache bersifat tambahan; kegagalannya tidak boleh menggagalkan panduan.
    }
  }
}
