import '../../domain/services/oil_specification_service.dart';
import 'http_oil_specification_service.dart';

abstract final class OilSpecificationServiceFactory {
  /// URL dasar katalog spesifikasi oli, contoh:
  /// `--dart-define=OIL_SPEC_BACKEND_URL=https://api.example.com`
  static const backendUrl = String.fromEnvironment(
    'OIL_SPEC_BACKEND_URL',
    defaultValue: '',
  );

  static OilSpecificationService createDefault() =>
      HttpOilSpecificationService(baseUrl: backendUrl);
}
