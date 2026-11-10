/// Spesifikasi oli motor yang telah diverifikasi dari sumber terpercaya
/// seperti buku pedoman resmi pabrikan.
class OilSpecification {
  const OilSpecification({
    required this.sae,
    required this.jaso,
    required this.volume,
    this.verified = false,
    this.source,
    this.sourceUrl,
    this.updatedAt,
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

  /// Nama sumber spesifikasi, misalnya buku pedoman pemilik pabrikan.
  final String? source;

  /// Tautan sumber jika backend menyediakannya.
  final String? sourceUrl;

  /// Waktu terakhir data ini diverifikasi atau diperbarui oleh sumber.
  final DateTime? updatedAt;

  factory OilSpecification.fromJson(Map<String, dynamic> json) {
    final rawUpdatedAt = json['updated_at'] ?? json['updatedAt'];
    return OilSpecification(
      sae: json['sae'] as String? ?? '',
      jaso: json['jaso'] as String? ?? '',
      volume: json['volume'] as String? ?? '',
      verified: json['verified'] as bool? ?? false,
      source: json['source'] as String? ?? json['sumber'] as String?,
      sourceUrl: json['source_url'] as String? ?? json['sourceUrl'] as String?,
      updatedAt: rawUpdatedAt is String
          ? DateTime.tryParse(rawUpdatedAt)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'sae': sae,
    'jaso': jaso,
    'volume': volume,
    'verified': verified,
    if (source != null) 'source': source,
    if (sourceUrl != null) 'source_url': sourceUrl,
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OilSpecification &&
          runtimeType == other.runtimeType &&
          sae == other.sae &&
          jaso == other.jaso &&
          volume == other.volume &&
          verified == other.verified &&
          source == other.source &&
          sourceUrl == other.sourceUrl &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      Object.hash(sae, jaso, volume, verified, source, sourceUrl, updatedAt);
}
