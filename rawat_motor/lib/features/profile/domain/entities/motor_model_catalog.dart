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
    this.aliases = const [],
    this.notes,
  });

  final String name;
  final String motorType;
  final String cooling;
  final String source;
  final String? generation;
  final List<String> aliases;
  final String? notes;

  String get searchLabel {
    final details = <String>[
      if (generation != null && generation!.isNotEmpty) generation!,
      if (aliases.isNotEmpty) aliases.join(', '),
    ];
    return details.isEmpty ? name : '$name (${details.join('; ')})';
  }

  factory MotorModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final motorType = json['jenis'];
    final cooling = json['pendingin'];
    final source = json['sumber'];
    final generation = json['generasi'];
    final aliases = json['alias'] ?? const <dynamic>[];
    final notes = json['catatan'];
    if (name is! String ||
        motorType is! String ||
        cooling is! String ||
        source is! String ||
        (generation != null && generation is! String) ||
        (notes != null && notes is! String) ||
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
      aliases: aliases.cast<String>(),
      notes: notes as String?,
    );
  }
}
