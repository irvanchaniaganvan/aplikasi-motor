enum ComponentScheduleStatus { safe, soon, due, needsCheck }

class ComponentSchedule {
  const ComponentSchedule({
    required this.targetKm,
    required this.remainingKm,
    required this.status,
    this.daysRemaining,
  });

  final int targetKm;
  final int remainingKm;
  final ComponentScheduleStatus status;
  final int? daysRemaining;
}

class ComponentScheduleCalculator {
  const ComponentScheduleCalculator();

  /// Menghitung jadwal dari kilometer servis terakhir.
  ///
  /// Mengembalikan `null` jika komponen belum pernah dicatat, supaya aplikasi
  /// tidak mengarang status jatuh tempo untuk motor dengan odometer tinggi.
  ComponentSchedule? calculate({
    required int currentOdometer,
    required int intervalKm,
    int? lastServicedKm,
    int? intervalMonths,
    DateTime? lastServicedAt,
    DateTime? today,
    int soonThresholdKm = 500,
    int soonThresholdDays = 14,
  }) {
    if (lastServicedKm == null && lastServicedAt == null) {
      return const ComponentSchedule(
        targetKm: 0,
        remainingKm: 0,
        status: ComponentScheduleStatus.needsCheck,
      );
    }
    if (intervalKm <= 0 && (intervalMonths == null || intervalMonths <= 0)) {
      return null;
    }

    final targetKm = lastServicedKm == null || intervalKm <= 0
        ? 0
        : lastServicedKm + intervalKm;
    final remainingKm = targetKm == 0 ? null : targetKm - currentOdometer;
    final nextDate = lastServicedAt != null && intervalMonths != null
        ? _addMonths(lastServicedAt, intervalMonths)
        : null;
    final date = today ?? DateTime.now();
    final daysRemaining = nextDate == null
        ? null
        : DateTime(
            nextDate.year,
            nextDate.month,
            nextDate.day,
          ).difference(DateTime(date.year, date.month, date.day)).inDays;
    final due =
        (remainingKm != null && remainingKm <= 0) ||
        (daysRemaining != null && daysRemaining <= 0);
    final soon =
        !due &&
        ((remainingKm != null && remainingKm <= soonThresholdKm) ||
            (daysRemaining != null && daysRemaining <= soonThresholdDays));
    final status = due
        ? ComponentScheduleStatus.due
        : soon
        ? ComponentScheduleStatus.soon
        : ComponentScheduleStatus.safe;

    return ComponentSchedule(
      targetKm: targetKm,
      remainingKm: remainingKm ?? 0,
      status: status,
      daysRemaining: daysRemaining,
    );
  }

  DateTime _addMonths(DateTime date, int months) {
    final monthIndex = date.month - 1 + months;
    final year = date.year + monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, date.day.clamp(1, lastDay));
  }
}
