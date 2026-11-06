import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/services/ai_service.dart';

/// Implementasi layanan AI yang memanggil endpoint backend serverless milik pengguna.
///
/// Menggunakan `dart:io` `HttpClient` tanpa library HTTP eksternal.
class HttpAiService implements AiService {
  HttpAiService({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 15),
    HttpClient? client,
  }) : _client = client ?? HttpClient();

  final String baseUrl;
  final Duration timeout;
  final HttpClient _client;

  Uri get _endpoint {
    final clean = baseUrl.trim();
    if (clean.endsWith('/ask-oil')) {
      return Uri.parse(clean);
    }
    if (clean.endsWith('/')) {
      return Uri.parse('${clean}ask-oil');
    }
    return Uri.parse('$clean/ask-oil');
  }

  @override
  Future<AiOilResponse> askOilGuide(AiOilRequest request) async {
    if (baseUrl.trim().isEmpty) {
      throw const AiServiceException(
        code: 'ai_unconfigured',
        message: 'Layanan AI belum dikonfigurasi.',
      );
    }

    if (request.question.trim().length > 500) {
      throw const AiServiceException(
        code: 'too_long',
        message: 'Pertanyaan melebihi batas maksimal 500 karakter.',
      );
    }

    try {
      final httpRequest = await _client.postUrl(_endpoint).timeout(timeout);
      httpRequest.headers.contentType = ContentType.json;
      final payload = jsonEncode(request.toJson());
      httpRequest.write(payload);

      final httpResponse = await httpRequest.close().timeout(timeout);
      final responseBody = await utf8.decodeStream(httpResponse);

      if (httpResponse.statusCode == 200) {
        final decoded = jsonDecode(responseBody);
        if (decoded is! Map<String, dynamic>) {
          throw const AiServiceException(
            code: 'server_error',
            message: 'Format respon server tidak valid.',
          );
        }
        return AiOilResponse.fromJson(decoded);
      }

      if (httpResponse.statusCode == 429) {
        throw const AiServiceException(
          code: 'rate_limited',
          message: 'Terlalu banyak permintaan dalam waktu singkat. Mohon tunggu sebentar.',
        );
      }

      if (httpResponse.statusCode == 400) {
        String? errorCode;
        try {
          final decoded = jsonDecode(responseBody);
          if (decoded is Map<String, dynamic>) {
            errorCode = decoded['code'] as String?;
          }
        } catch (_) {}

        if (errorCode == 'too_long') {
          throw const AiServiceException(
            code: 'too_long',
            message: 'Pertanyaan melebihi batas maksimal 500 karakter.',
          );
        }

        throw const AiServiceException(
          code: 'bad_request',
          message: 'Permintaan tidak dapat diproses oleh server.',
        );
      }

      throw AiServiceException(
        code: 'server_error',
        message:
            'Server AI mengalami gangguan (Status: ${httpResponse.statusCode}).',
      );
    } on SocketException {
      throw const AiServiceException(
        code: 'network_error',
        message: 'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    } on TimeoutException {
      throw const AiServiceException(
        code: 'network_error',
        message: 'Waktu permintaan habis. Silakan coba lagi.',
      );
    } on AiServiceException {
      rethrow;
    } catch (e) {
      throw AiServiceException(
        code: 'server_error',
        message: 'Terjadi kesalahan: $e',
      );
    }
  }
}
