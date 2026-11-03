import '../entities/motor_data.dart';

class OilSchedule {
  const OilSchedule({required this.nextOdometer, required this.distanceRemaining});

  final int nextOdometer;
  final int distanceRemaining;

  bool get isDue => distanceRemaining <= 0;
}

class OilScheduleCalculator {
  const OilScheduleCalculator();

  OilSchedule calculate(MotorData data) {
    final nextOdometer = data.lastOilOdometer + data.oilInterval;
    return OilSchedule(
      nextOdometer: nextOdometer,
      distanceRemaining: nextOdometer - data.currentOdometer,
    );
  }
}
