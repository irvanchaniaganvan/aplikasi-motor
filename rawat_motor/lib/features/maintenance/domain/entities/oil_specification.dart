/// Spesifikasi oli motor yang telah diverifikasi dari sumber terpercaya
/// seperti buku pedoman resmi pabrikan.
class OilSpecification {
  const OilSpecification({
    required this.sae,
    required this.jaso,
    required this.volume,
    this.verified = false,
  });

  /// Derajat kekentalan SAE, misalnya `10W-30` atau `10W-40`.
  final String sae;

  /// Standar friksi JASO, misalnya `JASO MB` untuk matic atau `JASO MA2` untuk kopling basah.
  final String jaso;

  /// Takaran kapasitas oli saat penggantian berkala, misalnya `0.8 L` atau `800 ml`.
  final String volume;

  /// Status verifikasi terhadap buku manual resmi. Jika `false`, spesifikasi tidak
  /// boleh ditampilkan sebagai acuan resmi.
  final bool verified;

  factory OilSpecification.fromJson(Map<String, dynamic> json) =>
      OilSpecification(
        sae: json['sae'] as String? ?? '',
        jaso: json['jaso'] as String? ?? '',
        volume: json['volume'] as String? ?? '',
        verified: json['verified'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
    'sae': sae,
    'jaso': jaso,
    'volume': volume,
    'verified': verified,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OilSpecification &&
          runtimeType == other.runtimeType &&
          sae == other.sae &&
          jaso == other.jaso &&
          volume == other.volume &&
          verified == other.verified;

  @override
  int get hashCode => Object.hash(sae, jaso, volume, verified);
}
