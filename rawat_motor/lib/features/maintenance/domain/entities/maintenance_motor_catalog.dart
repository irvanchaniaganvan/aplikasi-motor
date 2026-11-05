class MaintenanceMotorCatalog {
  const MaintenanceMotorCatalog({required this.motors});

  final List<MaintenanceMotor> motors;

  factory MaintenanceMotorCatalog.fromJson(Map<String, dynamic> json) {
    final raw = json['motors'];
    if (raw is! List) {
      throw const FormatException('Katalog model motor tidak valid.');
    }
    return MaintenanceMotorCatalog(
      motors: raw
          .map(
            (entry) => MaintenanceMotor.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

class MaintenanceMotor {
  const MaintenanceMotor({
    required this.id,
    required this.name,
    required this.transmission,
    required this.cooling,
    required this.parts,
  });

  final String id;
  final String name;
  final String transmission;
  final String cooling;
  final List<String> parts;

  factory MaintenanceMotor.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['nama'];
    final transmission = json['transmisi'];
    final cooling = json['pendingin'];
    final parts = json['parts'];
    if (id is! String ||
        name is! String ||
        transmission is! String ||
        cooling is! String ||
        parts is! List ||
        parts.any((part) => part is! String)) {
      throw const FormatException('Data model motor tidak valid.');
    }
    return MaintenanceMotor(
      id: id,
      name: name,
      transmission: transmission,
      cooling: cooling,
      parts: parts.cast<String>(),
    );
  }
}
