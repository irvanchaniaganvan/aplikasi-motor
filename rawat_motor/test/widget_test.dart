import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawat_motor/features/maintenance/domain/entities/motor_data.dart';
import 'package:rawat_motor/features/maintenance/domain/repositories/motor_data_repository.dart';
import 'package:rawat_motor/features/maintenance/domain/services/oil_schedule_calculator.dart';
import 'package:rawat_motor/features/maintenance/domain/use_cases/load_motor_data.dart';
import 'package:rawat_motor/features/maintenance/domain/use_cases/save_motor_data.dart';
import 'package:rawat_motor/features/maintenance/presentation/pages/oil_reminder_page.dart';
import 'package:rawat_motor/features/profile/domain/entities/driver_motor_profile.dart';
import 'package:rawat_motor/features/profile/presentation/pages/profile_setup_page.dart';

class _MemoryMotorDataRepository implements MotorDataRepository {
  MotorData? data;

  @override
  Future<void> clear() async => data = null;

  @override
  Future<MotorData?> load() async => data;

  @override
  Future<void> save(MotorData value) async => data = value;
}

void main() {
  testWidgets('meminta biodata pengendara dan detail motor', (tester) async {
    DriverMotorProfile? saved;
    await tester.pumpWidget(MaterialApp(
      home: ProfileSetupPage(onSave: (profile) async => saved = profile),
    ));

    await tester.enterText(find.byType(TextFormField).at(0), 'Irvan');
    await tester.enterText(find.byType(TextFormField).at(1), 'Yamaha');
    await tester.enterText(find.byType(TextFormField).at(2), 'Gear 125');
    await tester.enterText(find.byType(TextFormField).at(3), '2024');
    await tester.ensureVisible(find.text('Simpan dan lanjutkan'));
    await tester.tap(find.text('Simpan dan lanjutkan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(saved?.driverName, 'Irvan');
    expect(saved?.brand, 'Yamaha');
    expect(saved?.model, 'Gear 125');
    expect(saved?.year, 2024);
  });

  test('menghitung jadwal oli tanpa bergantung pada antarmuka', () {
    final result = const OilScheduleCalculator().calculate(
      const MotorData(currentOdometer: 11500, lastOilOdometer: 10000, oilInterval: 2000),
    );

    expect(result.nextOdometer, 12000);
    expect(result.distanceRemaining, 500);
    expect(result.isDue, isFalse);
  });

  testWidgets('menghitung jadwal dan mencatat ganti oli', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _MemoryMotorDataRepository();
    await tester.pumpWidget(MaterialApp(
      home: OilReminderPage(
        loadMotorData: LoadMotorData(repository),
        saveMotorData: SaveMotorData(repository),
      ),
    ));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '11500');
    await tester.enterText(fields.at(1), '10000');
    await tester.enterText(fields.at(2), '2000');
    await tester.ensureVisible(find.text('Simpan data motor'));
    await tester.tap(find.text('Simpan data motor'));
    await tester.pumpAndSettle();

    expect(find.text('500 km lagi'), findsOneWidget);
    expect(find.text('12.000 km'), findsOneWidget);

    await tester.ensureVisible(find.text('Catat ganti oli'));
    await tester.tap(find.text('Catat ganti oli'));
    await tester.pumpAndSettle();

    expect(find.text('2.000 km lagi'), findsOneWidget);
    expect(find.text('13.500 km'), findsOneWidget);
  });

  testWidgets('menolak kilometer servis yang melebihi odometer saat ini', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _MemoryMotorDataRepository();
    await tester.pumpWidget(MaterialApp(
      home: OilReminderPage(
        loadMotorData: LoadMotorData(repository),
        saveMotorData: SaveMotorData(repository),
      ),
    ));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '10000');
    await tester.enterText(fields.at(1), '12000');
    await tester.ensureVisible(find.text('Simpan data motor'));
    await tester.tap(find.text('Simpan data motor'));
    await tester.pumpAndSettle();

    expect(
      find.text('Angka ini tidak boleh melebihi kilometer saat ini.'),
      findsOneWidget,
    );
  });
}
