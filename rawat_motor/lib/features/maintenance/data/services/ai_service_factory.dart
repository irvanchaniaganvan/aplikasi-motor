import '../../domain/services/ai_service.dart';
import 'fake_ai_service.dart';
import 'http_ai_service.dart';

abstract final class AiServiceFactory {
  /// URL dasar backend yang bisa diinjeksi saat build via:
  /// `--dart-define=AI_BACKEND_URL=https://my-backend.domain.com`
  static const String backendUrl = String.fromEnvironment(
    'AI_BACKEND_URL',
    defaultValue: '',
  );

  /// Set `--dart-define=AI_FEATURE=off` untuk menyembunyikan bagian AI
  /// sepenuhnya, misalnya saat backend belum siap.
  static const bool featureEnabled = bool.fromEnvironment(
    'AI_FEATURE',
    defaultValue: true,
  );

  /// Membuat instance [AiService] aktif.
  ///
  /// Menggunakan [FakeAiService] secara default jika URL backend kosong,
  /// sehingga aplikasi tetap dapat berjalan penuh tanpa dependensi backend.
  static AiService createDefault() {
    if (backendUrl.trim().isNotEmpty) {
      return HttpAiService(baseUrl: backendUrl.trim());
    }
    return const FakeAiService();
  }
}
