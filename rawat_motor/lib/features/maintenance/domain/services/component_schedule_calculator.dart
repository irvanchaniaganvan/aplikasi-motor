enum ComponentScheduleStatus { safe, soon, due }

class ComponentSchedule {
  const ComponentSchedule({
    required this.targetKm,
    required this.remainingKm,
    required this.status,
  });

  final int targetKm;
  final int remainingKm;
  final ComponentScheduleStatus status;
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
    int soonThresholdKm = 500,
  }) {
    if (lastServicedKm == null || intervalKm <= 0) return null;

    final targetKm = lastServicedKm + intervalKm;
    final remainingKm = targetKm - currentOdometer;
    final status = remainingKm <= 0
        ? ComponentScheduleStatus.due
        : remainingKm <= soonThresholdKm
            ? ComponentScheduleStatus.soon
            : ComponentScheduleStatus.safe;

    return ComponentSchedule(
      targetKm: targetKm,
      remainingKm: remainingKm,
      status: status,
    );
  }
}
