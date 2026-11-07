class DriverMotorProfile {
  const DriverMotorProfile({
    this.id = '',
    required this.driverName,
    required this.brand,
    required this.model,
    required this.year,
    this.motorType,
    this.cooling,
    this.frontBrake,
    this.rearBrake,
    this.brakeSystem,
    this.motorVariant,
    this.maintenanceMotorId,
    this.transmission,
    this.nickname,
    this.photoPath,
    this.purchaseDate,
  });

  final String id;
  final String driverName;
  final String brand;
  final String model;
  final int year;
  final String? motorVariant;

  /// Jenis motor: `matic`, `bebek`, atau `sport`.
  final String? motorType;

  /// Sistem pendingin: `udara` atau `cair`.
  final String? cooling;

  /// Rem depan: `cakram` atau `tromol`.
  final String? frontBrake;

  /// Rem belakang: `cakram` atau `tromol`, jika diketahui.
  final String? rearBrake;

  /// Sistem pengereman seperti `CBS`, `ABS`, atau `UBS`.
  final String? brakeSystem;
  final String? maintenanceMotorId;
  final String? transmission;

  /// Nama panggilan kendaraan (opsional, maks 40 karakter, contoh: "Si Merah").
  final String? nickname;

  /// Path foto kendaraan di penyimpanan lokal dokumen aplikasi.
  final String? photoPath;

  /// Tanggal beli kendaraan (opsional, tidak boleh di masa depan).
  final DateTime? purchaseDate;

  DriverMotorProfile copyWith({
    String? id,
    String? driverName,
    String? brand,
    String? model,
    int? year,
    String? motorVariant,
    String? motorType,
    String? cooling,
    String? frontBrake,
    String? rearBrake,
    String? brakeSystem,
    String? maintenanceMotorId,
    String? transmission,
    String? nickname,
    String? photoPath,
    DateTime? purchaseDate,
    bool clearPhoto = false,
    bool clearPurchaseDate = false,
    bool clearNickname = false,
    bool clearFrontBrake = false,
    bool clearRearBrake = false,
    bool clearBrakeSystem = false,
  }) => DriverMotorProfile(
    id: id ?? this.id,
    driverName: driverName ?? this.driverName,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    year: year ?? this.year,
    motorVariant: motorVariant ?? this.motorVariant,
    motorType: motorType ?? this.motorType,
    cooling: cooling ?? this.cooling,
    frontBrake: clearFrontBrake ? null : (frontBrake ?? this.frontBrake),
    rearBrake: clearRearBrake ? null : (rearBrake ?? this.rearBrake),
    brakeSystem: clearBrakeSystem ? null : (brakeSystem ?? this.brakeSystem),
    maintenanceMotorId: maintenanceMotorId ?? this.maintenanceMotorId,
    transmission: transmission ?? this.transmission,
    nickname: clearNickname ? null : (nickname ?? this.nickname),
    photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    purchaseDate: clearPurchaseDate
        ? null
        : (purchaseDate ?? this.purchaseDate),
  );
}
