class ServiceRecord {
  const ServiceRecord({
    required this.date,
    required this.odometer,
    required this.item,
    this.workshop = '',
    this.cost = 0,
    this.notes = '',
    this.receiptPath,
  });

  final DateTime date;
  final int odometer;
  final String item;
  final String workshop;
  final int cost;
  final String notes;
  final String? receiptPath;

  Map<String, Object?> toJson() => {
    'date': date.toIso8601String(),
    'odometer': odometer,
    'item': item,
    'workshop': workshop,
    'cost': cost,
    'notes': notes,
    'receiptPath': receiptPath,
  };

  factory ServiceRecord.fromJson(Map<String, dynamic> json) {
    final dateValue = json['date'];
    final date = dateValue is String ? DateTime.tryParse(dateValue) : null;
    final odometer = json['odometer'];
    final item = json['item'];
    final workshop = json['workshop'] ?? '';
    final cost = json['cost'] ?? 0;
    final notes = json['notes'] ?? '';
    final receiptPath = json['receiptPath'];
    if (date == null ||
        odometer is! int ||
        odometer < 0 ||
        item is! String ||
        workshop is! String ||
        cost is! int ||
        cost < 0 ||
        notes is! String ||
        (receiptPath != null && receiptPath is! String)) {
      throw const FormatException('Riwayat servis tidak valid.');
    }
    return ServiceRecord(
      date: date,
      odometer: odometer,
      item: item,
      workshop: workshop,
      cost: cost,
      notes: notes,
      receiptPath: receiptPath as String?,
    );
  }
}
