import '../entities/oil_specification.dart';

/// Hasil pemuatan spesifikasi oli beserta asal data yang ditampilkan.
class OilSpecificationResult {
  const OilSpecificationResult({
    required this.specification,
    required this.sourceType,
  });

  final OilSpecification? specification;
  final OilSpecificationSourceType sourceType;

  bool get hasSpecification => specification != null;
}

enum OilSpecificationSourceType { online, cache, local, unavailable }

/// Kontrak sumber data spesifikasi oli sesuai model motor.
abstract interface class OilSpecificationService {
  Future<OilSpecificationResult> load({
    required String motorId,
    required String motorName,
    required int year,
    OilSpecification? localSpecification,
    bool refresh = false,
  });
}
