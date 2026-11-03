class MotorData {
  const MotorData({
    required this.currentOdometer,
    required this.lastOilOdometer,
    required this.oilInterval,
    this.lastOilChangeDate,
  });

  final int currentOdometer;
  final int lastOilOdometer;
  final int oilInterval;
  final DateTime? lastOilChangeDate;

  Map<String, Object> toJson() => {
        'currentOdometer': currentOdometer,
        'lastOilOdometer': lastOilOdometer,
        'oilInterval': oilInterval,
        if (lastOilChangeDate != null)
          'lastOilChangeDate': lastOilChangeDate!.toIso8601String(),
      };

  factory MotorData.fromJson(Map<String, dynamic> json) {
    final current = json['currentOdometer'];
    final last = json['lastOilOdometer'];
    final interval = json['oilInterval'];
    final rawDate = json['lastOilChangeDate'];
    if (current is! int || last is! int || interval is! int ||
        current < last || last < 0 || interval <= 0) {
      throw const FormatException('Data motor tidak valid.');
    }
    final parsedDate = rawDate is String ? DateTime.tryParse(rawDate) : null;
    return MotorData(
      currentOdometer: current,
      lastOilOdometer: last,
      oilInterval: interval,
      lastOilChangeDate: parsedDate,
    );
  }

  MotorData copyWith({int? currentOdometer, int? lastOilOdometer, int? oilInterval, DateTime? lastOilChangeDate}) {
    return MotorData(
      currentOdometer: currentOdometer ?? this.currentOdometer,
      lastOilOdometer: lastOilOdometer ?? this.lastOilOdometer,
      oilInterval: oilInterval ?? this.oilInterval,
      lastOilChangeDate: lastOilChangeDate ?? this.lastOilChangeDate,
    );
  }
}
