import '../../../maintenance/domain/entities/oil_specification.dart';

class MotorModelCatalog {
  const MotorModelCatalog({required this.brands});

  final List<MotorBrand> brands;

  factory MotorModelCatalog.fromJson(Map<String, dynamic> json) {
    final rawBrands = json['brands'];
    if (rawBrands is! List) {
      throw const FormatException(
        'Katalog motor harus memiliki daftar brands.',
      );
    }
    return MotorModelCatalog(
      brands: rawBrands
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Data merek motor tidak valid.');
            }
            return MotorBrand.fromJson(item);
          })
          .toList(growable: false),
    );
  }
}

class MotorBrand {
  const MotorBrand({required this.name, required this.models});

  final String name;
  final List<MotorModel> models;

  factory MotorBrand.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final models = json['models'];
    if (name is! String || models is! List) {
      throw const FormatException('Merek harus memiliki name dan models.');
    }
    return MotorBrand(
      name: name,
      models: models
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Data model motor tidak valid.');
            }
            return MotorModel.fromJson(item);
          })
          .toList(growable: false),
    );
  }
}

class MotorModel {
  const MotorModel({
    required this.name,
    required this.motorType,
    required this.cooling,
    required this.source,
    this.generation,
    this.variant,
    this.aliases = const [],
    this.notes,
    this.oilSpec,
    this.frontBrake,
    this.rearBrake,
    this.brakeSystem,
    this.brakeVerified = false,
  });

  final String name;
  final String motorType;
  final String cooling;
  final String source;
  final String? generation;
  final String? variant;
  final List<String> aliases;
  final String? notes;
  final OilSpecification? oilSpec;
  final String? frontBrake;
  final String? rearBrake;
  final String? brakeSystem;
  final bool brakeVerified;

  String get searchLabel {
    final details = <String>[
      if (generation != null && generation!.isNotEmpty) generation!,
      if (variant != null && variant!.isNotEmpty) variant!,
      if (aliases.isNotEmpty) aliases.join(', '),
    ];
    return details.isEmpty ? name : '$name (${details.join('; ')})';
  }

  /// Label ringkas untuk ditampilkan; alias tetap dipakai untuk pencarian.
  String get displayLabel {
    final details = <String>[
      if (generation != null && generation!.isNotEmpty) generation!,
      if (variant != null && variant!.isNotEmpty) variant!,
    ];
    return details.isEmpty ? name : '$name (${details.join('; ')})';
  }

  factory MotorModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final motorType = json['jenis'];
    final cooling = json['pendingin'];
    final source = json['sumber'];
    final generation = json['generasi'];
    final variant = json['varian'];
    final aliases = json['alias'] ?? const <dynamic>[];
    final notes = json['catatan'];
    final frontBrake = json['rem_depan'];
    final rearBrake = json['rem_belakang'];
    final brakeSystem = json['sistem_rem'];
    final brakeVerified = json['rem_terverifikasi'] ?? false;
    OilSpecification? oilSpec;
    final rawOil = json['spesifikasi_oli'] ?? json['oil_spec'];
    if (rawOil is Map<String, dynamic>) {
      oilSpec = OilSpecification.fromJson(rawOil);
    } else if (rawOil is Map) {
      oilSpec = OilSpecification.fromJson(Map<String, dynamic>.from(rawOil));
    }
    if (name is! String ||
        motorType is! String ||
        cooling is! String ||
        !const {'matic', 'bebek', 'sport'}.contains(motorType) ||
        (!const {'udara', 'oli', 'cair', 'TODO_VERIFY'}.contains(cooling)) ||
        source is! String ||
        (generation != null && generation is! String) ||
        (variant != null && variant is! String) ||
        (notes != null && notes is! String) ||
        (frontBrake != null &&
            (frontBrake is! String ||
                !const {'cakram', 'tromol'}.contains(frontBrake))) ||
        (rearBrake != null &&
            (rearBrake is! String ||
                !const {'cakram', 'tromol'}.contains(rearBrake))) ||
        (brakeSystem != null && brakeSystem is! String) ||
        brakeVerified is! bool ||
        aliases is! List ||
        aliases.any((alias) => alias is! String)) {
      throw const FormatException(
        'Model harus memiliki name, jenis, pendingin, sumber, generasi opsional, dan daftar alias.',
      );
    }
    return MotorModel(
      name: name,
      motorType: motorType,
      cooling: cooling,
      source: source,
      generation: generation as String?,
      variant: variant as String?,
      aliases: aliases.cast<String>(),
      notes: notes as String?,
      oilSpec: oilSpec,
      frontBrake: frontBrake as String?,
      rearBrake: rearBrake as String?,
      brakeSystem: brakeSystem as String?,
      brakeVerified: brakeVerified,
    );
  }
}
