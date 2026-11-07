/// Helper untuk menghitung dan memformat umur kendaraan berdasarkan tanggal beli.
class VehicleAge {
  const VehicleAge({required this.years, required this.months});

  final int years;
  final int months;

  /// Memformat umur kendaraan secara ringkas dalam bahasa Indonesia.
  /// Contoh: "1 tahun 6 bulan", "2 tahun", "8 bulan", atau "Kurang dari 1 bulan".
  String get label {
    if (years <= 0 && months <= 0) {
      return 'Kurang dari 1 bulan';
    }
    if (years <= 0) {
      return '$months bulan';
    }
    if (months <= 0) {
      return '$years tahun';
    }
    return '$years tahun $months bulan';
  }

  /// Teks lengkap dengan awalan "Umur kendaraan: ".
  String get fullText => 'Umur kendaraan: $label';
}

/// Menghitung umur kendaraan dari [purchaseDate] relatif terhadap [relativeTo]
/// (default: [DateTime.now]).
///
/// Mengembalikan `null` jika [purchaseDate] berada di masa depan.
VehicleAge? calculateVehicleAge(DateTime purchaseDate, [DateTime? relativeTo]) {
  final now = relativeTo ?? DateTime.now();
  if (purchaseDate.isAfter(now)) {
    return null;
  }

  var years = now.year - purchaseDate.year;
  var months = now.month - purchaseDate.month;

  if (now.day < purchaseDate.day) {
    months--;
  }

  if (months < 0) {
    years--;
    months += 12;
  }

  if (years < 0) {
    return null;
  }

  return VehicleAge(years: years, months: months);
}

/// Menghasilkan string `"Umur kendaraan: X tahun Y bulan"` atau `null` jika tidak valid.
String? formatVehicleAge(DateTime? purchaseDate, [DateTime? relativeTo]) {
  if (purchaseDate == null) return null;
  final age = calculateVehicleAge(purchaseDate, relativeTo);
  return age?.fullText;
}
