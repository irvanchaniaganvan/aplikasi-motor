import 'dart:math' as math;

import '../entities/motor_data.dart';

class OilSchedule {
  const OilSchedule({
    required this.nextOdometer,
    required this.distanceRemaining,
    required this.nextDate,
    required this.daysRemaining,
    required this.status,
  });

  final int nextOdometer;
  final int distanceRemaining;
  final DateTime? nextDate;
  final int? daysRemaining;
  final OilScheduleStatus status;

  bool get isDue => status == OilScheduleStatus.due;
}

enum OilScheduleStatus { safe, soon, due }

class OilScheduleCalculator {
  const OilScheduleCalculator();

  OilSchedule calculate(MotorData data, {DateTime? today, int soonThresholdKm = 500, int soonThresholdDays = 14}) {
    final nextOdometer = data.lastOilOdometer + data.oilInterval;
    final nextDate = data.lastOilChangeDate != null && data.oilIntervalMonths != null
        ? _addMonths(data.lastOilChangeDate!, data.oilIntervalMonths!)
        : null;
    final currentDate = today ?? DateTime.now();
    final daysRemaining = nextDate == null
        ? null
        : DateTime(nextDate.year, nextDate.month, nextDate.day)
            .difference(DateTime(currentDate.year, currentDate.month, currentDate.day))
            .inDays;
    final due = nextOdometer <= data.currentOdometer || (daysRemaining != null && daysRemaining <= 0);
    final soon = !due && (nextOdometer - data.currentOdometer <= soonThresholdKm || (daysRemaining != null && daysRemaining <= soonThresholdDays));
    return OilSchedule(
      nextOdometer: nextOdometer,
      distanceRemaining: nextOdometer - data.currentOdometer,
      nextDate: nextDate,
      daysRemaining: daysRemaining,
      status: due ? OilScheduleStatus.due : soon ? OilScheduleStatus.soon : OilScheduleStatus.safe,
    );
  }

  DateTime _addMonths(DateTime date, int months) {
    final monthIndex = date.month - 1 + months;
    final year = date.year + monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, math.min(date.day, lastDay));
  }
}
