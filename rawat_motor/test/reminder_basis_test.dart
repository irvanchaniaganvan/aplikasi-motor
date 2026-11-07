import 'package:flutter_test/flutter_test.dart';
import 'package:rawatin/features/maintenance/domain/entities/motor_data.dart';
import 'package:rawatin/features/maintenance/domain/services/oil_schedule_calculator.dart';

void main() {
  final today = DateTime(2026, 11, 7);

  MotorData data({required int current, required ReminderBasis basis}) =>
      MotorData(
        currentOdometer: current,
        lastOilOdometer: 10000,
        oilInterval: 3000,
        oilIntervalMonths: 3,
        lastOilChangeDate: DateTime(2026, 8, 7),
        reminderBasis: basis,
      );

  test('basis jarak hanya memakai kilometer', () {
    final schedule = const OilScheduleCalculator().calculate(
      data(current: 13000, basis: ReminderBasis.distance),
      today: today,
    );
    expect(schedule.status, OilScheduleStatus.due);
    expect(schedule.nextDate, isNull);
    expect(schedule.daysRemaining, isNull);
  });

  test('basis waktu hanya memakai tanggal servis', () {
    final schedule = const OilScheduleCalculator().calculate(
      data(current: 10001, basis: ReminderBasis.time),
      today: today,
    );
    expect(schedule.status, OilScheduleStatus.due);
    expect(schedule.nextDate, DateTime(2026, 11, 7));
    expect(schedule.distanceRemaining, 2999);
  });

  test('mana yang lebih dulu mempertahankan perilaku gabungan', () {
    final schedule = const OilScheduleCalculator().calculate(
      data(current: 12000, basis: ReminderBasis.whicheverFirst),
      today: today,
    );
    expect(schedule.status, OilScheduleStatus.due);
  });

  test(
    'data lama tanpa pilihan memakai default gabungan dan dapat diserialisasi',
    () {
      final oldData = MotorData.fromJson({
        'currentOdometer': 11500,
        'lastOilOdometer': 10000,
        'oilInterval': 3000,
      });
      expect(oldData.reminderBasis, ReminderBasis.whicheverFirst);
      expect(
        MotorData.fromJson(oldData.toJson()).reminderBasis,
        ReminderBasis.whicheverFirst,
      );
    },
  );
}
