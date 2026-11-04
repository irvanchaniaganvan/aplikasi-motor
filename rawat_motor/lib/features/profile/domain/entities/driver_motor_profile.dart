class DriverMotorProfile {
  const DriverMotorProfile({
    required this.driverName,
    required this.brand,
    required this.model,
    required this.year,
    this.motorType,
    this.cooling,
    this.frontBrake,
  });

  final String driverName;
  final String brand;
  final String model;
  final int year;

  /// Jenis motor: `matic`, `bebek`, atau `sport`.
  final String? motorType;

  /// Sistem pendingin: `udara` atau `cair`.
  final String? cooling;

  /// Rem depan: `cakram` atau `tromol`.
  final String? frontBrake;
}
