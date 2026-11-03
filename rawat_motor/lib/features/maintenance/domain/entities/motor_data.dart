import 'odometer_entry.dart';
import 'service_record.dart';

class MotorData {
  const MotorData({
    required this.currentOdometer,
    required this.lastOilOdometer,
    required this.oilInterval,
    this.lastOilChangeDate,
    this.oilIntervalMonths,
    this.odometerLogs = const [],
    this.serviceHistory = const [],
  });

  final int currentOdometer;
  final int lastOilOdometer;
  final int oilInterval;
  final DateTime? lastOilChangeDate;
  final int? oilIntervalMonths;
  final List<OdometerEntry> odometerLogs;
  final List<ServiceRecord> serviceHistory;

  Map<String, Object> toJson() => {
        'currentOdometer': currentOdometer,
        'lastOilOdometer': lastOilOdometer,
        'oilInterval': oilInterval,
        if (lastOilChangeDate case final date?)
          'lastOilChangeDate': date.toIso8601String(),
        'oilIntervalMonths': ?oilIntervalMonths,
        'odometerLogs': odometerLogs.map((entry) => entry.toJson()).toList(),
        'serviceHistory': serviceHistory.map((entry) => entry.toJson()).toList(),
      };

  factory MotorData.fromJson(Map<String, dynamic> json) {
    final current = json['currentOdometer'];
    final last = json['lastOilOdometer'];
    final interval = json['oilInterval'];
    final rawDate = json['lastOilChangeDate'];
    final intervalMonths = json['oilIntervalMonths'];
    final rawLogs = json['odometerLogs'];
    final rawServices = json['serviceHistory'];
    if (current is! int || last is! int || interval is! int ||
        current < last || last < 0 || interval <= 0 ||
        (intervalMonths != null && (intervalMonths is! int || intervalMonths <= 0))) {
      throw const FormatException('Data motor tidak valid.');
    }
    final parsedDate = rawDate is String ? DateTime.tryParse(rawDate) : null;
    return MotorData(
      currentOdometer: current,
      lastOilOdometer: last,
      oilInterval: interval,
      lastOilChangeDate: parsedDate,
      oilIntervalMonths: intervalMonths == null ? null : intervalMonths as int,
      odometerLogs: rawLogs == null
          ? const []
          : (rawLogs as List).map((entry) => OdometerEntry.fromJson(Map<String, dynamic>.from(entry as Map))).toList(),
      serviceHistory: rawServices == null
          ? const []
          : (rawServices as List).map((entry) => ServiceRecord.fromJson(Map<String, dynamic>.from(entry as Map))).toList(),
    );
  }

  MotorData copyWith({int? currentOdometer, int? lastOilOdometer, int? oilInterval, DateTime? lastOilChangeDate, int? oilIntervalMonths, List<OdometerEntry>? odometerLogs, List<ServiceRecord>? serviceHistory}) {
    return MotorData(
      currentOdometer: currentOdometer ?? this.currentOdometer,
      lastOilOdometer: lastOilOdometer ?? this.lastOilOdometer,
      oilInterval: oilInterval ?? this.oilInterval,
      lastOilChangeDate: lastOilChangeDate ?? this.lastOilChangeDate,
      oilIntervalMonths: oilIntervalMonths ?? this.oilIntervalMonths,
      odometerLogs: odometerLogs ?? this.odometerLogs,
      serviceHistory: serviceHistory ?? this.serviceHistory,
    );
  }
}
