class OdometerEntry {
  const OdometerEntry({required this.kilometers, required this.date, required this.source});

  final int kilometers;
  final DateTime date;
  final String source;

  Map<String, Object> toJson() => {
        'kilometers': kilometers,
        'date': date.toIso8601String(),
        'source': source,
      };

  factory OdometerEntry.fromJson(Map<String, dynamic> json) {
    final km = json['kilometers'];
    final date = json['date'];
    final source = json['source'];
    if (km is! int || km < 0 || date is! String || source is! String) {
      throw const FormatException('Log odometer tidak valid.');
    }
    final parsedDate = DateTime.tryParse(date);
    if (parsedDate == null) throw const FormatException('Tanggal odometer tidak valid.');
    return OdometerEntry(kilometers: km, date: parsedDate, source: source);
  }
}
