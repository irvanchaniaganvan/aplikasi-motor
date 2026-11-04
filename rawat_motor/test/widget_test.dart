import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawatin/features/maintenance/domain/entities/maintenance_component.dart';
import 'package:rawatin/features/maintenance/domain/entities/maintenance_catalog.dart';
import 'package:rawatin/features/maintenance/domain/entities/motor_data.dart';
import 'package:rawatin/features/maintenance/domain/services/component_schedule_calculator.dart';
import 'package:rawatin/features/maintenance/domain/services/component_filter.dart';
import 'package:rawatin/features/maintenance/domain/repositories/motor_data_repository.dart';
import 'package:rawatin/features/maintenance/data/repositories/default_interval_repository.dart';
import 'package:rawatin/features/maintenance/domain/services/oil_schedule_calculator.dart';
import 'package:rawatin/features/maintenance/domain/use_cases/load_motor_data.dart';
import 'package:rawatin/features/maintenance/domain/use_cases/save_motor_data.dart';
import 'package:rawatin/features/maintenance/presentation/pages/oil_reminder_page.dart';
import 'package:rawatin/features/profile/domain/entities/driver_motor_profile.dart';
import 'package:rawatin/features/profile/presentation/pages/local_account_page.dart';
import 'package:rawatin/features/profile/presentation/pages/profile_setup_page.dart';

Future<void> _selectDropdown(WidgetTester tester, String hint, String option) async {
  final dropdown = find.ancestor(
    of: find.text(hint),
    matching: find.byType(DropdownButtonFormField<String>),
  );
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

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
  test('jadwal komponen dihitung dari kilometer servis terakhir', () {
    final schedule = const ComponentScheduleCalculator().calculate(
      currentOdometer: 3500,
      intervalKm: 3000,
      lastServicedKm: 1000,
    );
    expect(schedule?.targetKm, 4000);
    expect(schedule?.remainingKm, 500);
    expect(schedule?.status, ComponentScheduleStatus.soon);
  });

  test('komponen tanpa catatan belum punya status jadwal', () {
    final schedule = const ComponentScheduleCalculator().calculate(
      currentOdometer: 5000,
      intervalKm: 3000,
    );
    expect(schedule, isNull);
  });

  test('override interval memakai nilai pengguna', () {
    final schedule = const ComponentScheduleCalculator().calculate(
      currentOdometer: 4500,
      intervalKm: 4000,
      lastServicedKm: 1000,
    );
    expect(schedule?.targetKm, 5000);
    expect(schedule?.remainingKm, 500);
    expect(schedule?.status, ComponentScheduleStatus.soon);
  });

  test('penyaringan komponen mengikuti jenis motor dan kondisi motor', () {
    const components = [
      MaintenanceComponent(name: 'Oli mesin', action: 'ganti', intervalKm: 3000),
      MaintenanceComponent(name: 'Oli gardan', action: 'ganti', intervalKm: 6000, appliesTo: ['matic']),
      MaintenanceComponent(name: 'Rantai', action: 'ganti', intervalKm: 25000, appliesTo: ['bebek', 'sport']),
      MaintenanceComponent(name: 'Kampas rem', action: 'cek', intervalKm: 4000),
      MaintenanceComponent(name: 'Minyak rem', action: 'ganti', intervalKm: 24000, requirement: 'rem_cakram'),
      MaintenanceComponent(name: 'Coolant', action: 'ganti', intervalKm: 12000, requirement: 'pendingin_cair'),
    ];

    final matic = filterMaintenanceComponents(
      components: components,
      motorType: 'matic',
      cooling: 'cair',
      frontBrake: 'cakram',
    );
    expect(matic.map((component) => component.name), containsAll(['Oli mesin', 'Oli gardan', 'Kampas rem', 'Minyak rem', 'Coolant']));
    expect(matic.map((component) => component.name), isNot(contains('Rantai')));

    final bebek = filterMaintenanceComponents(
      components: components,
      motorType: 'bebek',
      cooling: 'udara',
      frontBrake: 'tromol',
    );
    expect(bebek.map((component) => component.name), containsAll(['Oli mesin', 'Rantai', 'Kampas rem']));
    expect(bebek.map((component) => component.name), isNot(contains('Oli gardan')));
    expect(bebek.map((component) => component.name), isNot(contains('Minyak rem')));
    expect(bebek.map((component) => component.name), isNot(contains('Coolant')));
  });

  test('komponen dengan aksi cek dikenali sebagai pemeriksaan', () {
    const component = MaintenanceComponent(name: 'Kampas rem', action: 'cek', intervalKm: 4000);
    expect(component.isInspection, isTrue);
  });

  testWidgets('katalog interval default dapat dimuat dari asset', (tester) async {
    final catalog = await const DefaultIntervalRepository().load();
    expect(catalog.components, isNotEmpty);
    expect(catalog.components.any((component) => component.name == 'Oli mesin'), isTrue);
    expect(catalog.components.any((component) => component.requirement == 'rem_cakram'), isTrue);
  });

  testWidgets('halaman akun membedakan masuk dan buat akun', (tester) async {
    LocalAccountMode? submittedMode;
    await tester.pumpWidget(MaterialApp(
      home: LocalAccountPage(
        initialMode: LocalAccountMode.signIn,
        initialEmail: 'irvan@example.com',
        onSubmit: (mode, email, password) async {
          submittedMode = mode;
          return null;
        },
      ),
    ));

    expect(find.text('Selamat datang kembali.'), findsOneWidget);
    expect(find.text('Masuk'), findsWidgets);

    await tester.tap(find.text('Buat akun').first);
    await tester.pumpAndSettle();
    expect(find.text('Buat akun baru.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), '1234');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Buat akun'));
    await tester.tap(find.widgetWithText(FilledButton, 'Buat akun'));
    await tester.pumpAndSettle();

    expect(submittedMode, LocalAccountMode.create);
  });

  testWidgets('meminta biodata pengendara dan detail motor', (tester) async {
    DriverMotorProfile? saved;
    await tester.pumpWidget(MaterialApp(
      home: ProfileSetupPage(onSave: (profile) async => saved = profile),
    ));

    await tester.enterText(find.byType(TextFormField).at(0), 'Irvan');
    await tester.enterText(find.byType(TextFormField).at(1), 'Yamaha');
    await tester.enterText(find.byType(TextFormField).at(2), 'Gear 125');
    await tester.enterText(find.byType(TextFormField).at(3), '2024');
    await _selectDropdown(tester, 'Pilih jenis motor', 'Matic');
    await _selectDropdown(tester, 'Pilih pendingin', 'Udara');
    await _selectDropdown(tester, 'Pilih rem depan', 'Tromol');
    await tester.ensureVisible(find.text('Simpan dan lanjutkan'));
    await tester.tap(find.text('Simpan dan lanjutkan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(saved?.driverName, 'Irvan');
    expect(saved?.brand, 'Yamaha');
    expect(saved?.model, 'Gear 125');
    expect(saved?.year, 2024);
    expect(saved?.motorType, 'matic');
    expect(saved?.cooling, 'udara');
    expect(saved?.frontBrake, 'tromol');
  });

  testWidgets('halaman komponen menyaring sesuai profil dan menampilkan aksi cek', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _MemoryMotorDataRepository()
      ..data = const MotorData(
        currentOdometer: 12000,
        lastOilOdometer: 10000,
        oilInterval: 3000,
        componentStates: [
          ComponentMaintenanceState(componentName: 'Oli mesin', lastServicedKm: 10000),
          ComponentMaintenanceState(componentName: 'Kampas rem', lastServicedKm: 8000),
        ],
      );
    const catalog = MaintenanceCatalog(source: 'uji', components: [
      MaintenanceComponent(name: 'Oli mesin', action: 'ganti', intervalKm: 3000),
      MaintenanceComponent(name: 'Oli gardan', action: 'ganti', intervalKm: 6000, appliesTo: ['matic']),
      MaintenanceComponent(name: 'V-belt', action: 'ganti', intervalKm: 20000, appliesTo: ['matic']),
      MaintenanceComponent(name: 'Air radiator/coolant', action: 'ganti', intervalKm: 12000, requirement: 'pendingin_cair'),
      MaintenanceComponent(name: 'Minyak rem', action: 'ganti', intervalKm: 24000, requirement: 'rem_cakram'),
      MaintenanceComponent(name: 'Rantai & gear set', action: 'ganti', intervalKm: 25000, appliesTo: ['bebek', 'sport']),
      MaintenanceComponent(name: 'Kampas rem', action: 'cek', intervalKm: 4000),
    ]);

    await tester.pumpWidget(MaterialApp(
      home: OilReminderPage(
        loadMotorData: LoadMotorData(repository),
        saveMotorData: SaveMotorData(repository),
        catalog: catalog,
        profile: const DriverMotorProfile(
          driverName: 'Irvan',
          brand: 'Honda',
          model: 'Scoopy',
          year: 2024,
          motorType: 'matic',
          cooling: 'cair',
          frontBrake: 'cakram',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Komponen'));
    await tester.pumpAndSettle();

    expect(find.text('Perkiraan umum, ikuti buku servis motormu.'), findsOneWidget);
    expect(find.text('Oli gardan'), findsOneWidget);
    expect(find.text('V-belt'), findsOneWidget);
    expect(find.text('Air radiator/coolant'), findsOneWidget);
    expect(find.text('Minyak rem'), findsOneWidget);
    expect(find.text('Rantai & gear set'), findsNothing);
    expect(find.text('Waktunya cek kondisi'), findsOneWidget);
  });

  test('menghitung jadwal oli tanpa bergantung pada antarmuka', () {
    final result = const OilScheduleCalculator().calculate(
      const MotorData(currentOdometer: 11500, lastOilOdometer: 10000, oilInterval: 2000),
    );

    expect(result.nextOdometer, 12000);
    expect(result.distanceRemaining, 500);
    expect(result.isDue, isFalse);
  });

  test('jadwal jatuh tempo jika batas waktu tercapai lebih dulu', () {
    final result = const OilScheduleCalculator().calculate(
      MotorData(
        currentOdometer: 10000,
        lastOilOdometer: 9500,
        oilInterval: 2000,
        lastOilChangeDate: DateTime(2026, 1, 1),
        oilIntervalMonths: 3,
      ),
      today: DateTime(2026, 4, 1),
    );

    expect(result.status, OilScheduleStatus.due);
    expect(result.daysRemaining, 0);
  });

  test('status segera saat jarak servis berada dalam ambang', () {
    final result = const OilScheduleCalculator().calculate(
      const MotorData(currentOdometer: 11500, lastOilOdometer: 10000, oilInterval: 2000),
    );
    expect(result.status, OilScheduleStatus.soon);
  });

  test('data motor lama tetap terbaca dan field baru bermigrasi sebagai kosong', () {
    final restored = MotorData.fromJson({
      'currentOdometer': 12500,
      'lastOilOdometer': 10000,
      'oilInterval': 2000,
    });
    expect(restored.currentOdometer, 12500);
    expect(restored.oilIntervalMonths, isNull);
    expect(restored.odometerLogs, isEmpty);
    expect(restored.serviceHistory, isEmpty);
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
