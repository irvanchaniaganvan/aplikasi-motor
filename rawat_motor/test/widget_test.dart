import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rawatin/features/maintenance/domain/entities/maintenance_component.dart';
import 'package:rawatin/features/maintenance/domain/entities/maintenance_catalog.dart';
import 'package:rawatin/features/maintenance/domain/entities/motor_data.dart';
import 'package:rawatin/features/maintenance/domain/entities/maintenance_motor_catalog.dart';
import 'package:rawatin/features/maintenance/domain/services/component_schedule_calculator.dart';
import 'package:rawatin/features/maintenance/domain/services/component_filter.dart';
import 'package:rawatin/features/maintenance/domain/repositories/motor_data_repository.dart';
import 'package:rawatin/features/maintenance/data/repositories/default_interval_repository.dart';
import 'package:rawatin/features/maintenance/domain/services/oil_schedule_calculator.dart';
import 'package:rawatin/features/maintenance/domain/services/record_component_service.dart';
import 'package:rawatin/features/maintenance/domain/use_cases/load_motor_data.dart';
import 'package:rawatin/features/maintenance/domain/use_cases/save_motor_data.dart';
import 'package:rawatin/features/maintenance/presentation/pages/oil_reminder_page.dart';
import 'package:rawatin/features/profile/domain/entities/driver_motor_profile.dart';
import 'package:rawatin/features/profile/domain/entities/motor_model_catalog.dart';
import 'package:rawatin/features/profile/presentation/pages/local_account_page.dart';
import 'package:rawatin/features/profile/presentation/pages/profile_setup_page.dart';
import 'package:rawatin/features/profile/data/repositories/local_profile_repository.dart';
import 'package:rawatin/features/maintenance/data/repositories/local_motor_data_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Future<void> _selectDropdown(
  WidgetTester tester,
  String hint,
  String option,
) async {
  final index = switch (hint) {
    'Pilih jenis motor' => 0,
    'Pilih pendingin' => 1,
    'Pilih rem depan' => 2,
    _ => throw ArgumentError('Dropdown tidak dikenal: $hint'),
  };
  final dropdown = find.byType(DropdownButtonFormField<String>).at(index);
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
  test('profil lama dimigrasikan ke koleksi kendaraan', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          'profile.driver_name': 'Irvan',
          'profile.motor_brand': 'Honda',
          'profile.motor_model': 'BeAT',
          'profile.motor_year': 2024,
          'profile.motor_type': 'matic',
        });
    final repository = LocalProfileRepository(SharedPreferencesAsync());
    final vehicles = await repository.loadAll();
    expect(vehicles, hasLength(1));
    expect(vehicles.single.id, isNotEmpty);
    expect(vehicles.single.model, 'BeAT');
    expect(await repository.loadSelectedProfileId(), vehicles.single.id);

    await repository.saveVehicle(
      const DriverMotorProfile(
        id: 'vehicle-2',
        driverName: 'Irvan',
        brand: 'Yamaha',
        model: 'Gear 125',
        year: 2025,
        motorType: 'matic',
        cooling: 'udara',
      ),
    );
    final savedVehicles = await repository.loadAll();
    expect(savedVehicles, hasLength(2));
    expect(
      savedVehicles.map((vehicle) => vehicle.model),
      containsAll(['BeAT', 'Gear 125']),
    );
    expect(await repository.loadSelectedProfileId(), 'vehicle-2');
  });

  test('data servis tersimpan terpisah untuk setiap kendaraan', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final first = LocalMotorDataRepository(
      SharedPreferencesAsync(),
      vehicleId: 'one',
    );
    final second = LocalMotorDataRepository(
      SharedPreferencesAsync(),
      vehicleId: 'two',
    );
    await first.save(
      const MotorData(
        currentOdometer: 1000,
        lastOilOdometer: 500,
        oilInterval: 3000,
      ),
    );
    expect((await second.load()), isNull);
    await second.save(
      const MotorData(
        currentOdometer: 9000,
        lastOilOdometer: 8500,
        oilInterval: 4000,
      ),
    );
    expect((await first.load())?.currentOdometer, 1000);
    expect((await second.load())?.currentOdometer, 9000);
  });

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
    expect(schedule?.status, ComponentScheduleStatus.needsCheck);
  });

  test(
    'jadwal part memakai tanggal dan kilometer yang lebih dulu jatuh tempo',
    () {
      final schedule = const ComponentScheduleCalculator().calculate(
        currentOdometer: 2000,
        intervalKm: 5000,
        lastServicedKm: 1000,
        intervalMonths: 1,
        lastServicedAt: DateTime(2026, 1, 1),
        today: DateTime(2026, 2, 1),
      );
      expect(schedule?.status, ComponentScheduleStatus.due);
      expect(schedule?.daysRemaining, 0);
    },
  );

  test(
    'migrasi menjaga jadwal oli lama dan memetakannya sebagai oli mesin',
    () {
      final data = MotorData.fromJson({
        'currentOdometer': 12000,
        'lastOilOdometer': 10000,
        'oilInterval': 3000,
        'oilIntervalMonths': 3,
        'lastOilChangeDate': '2026-01-10T00:00:00.000',
      });
      expect(data.lastOilOdometer, 10000);
      expect(data.oilInterval, 3000);
      expect(data.componentStates.single.componentId, 'oli-mesin');
      expect(data.componentStates.single.lastServicedKm, 10000);
    },
  );

  test(
    'servis part hanya reset part terpilih dan log odometer meningkat saja',
    () {
      const data = MotorData(
        currentOdometer: 5000,
        lastOilOdometer: 3000,
        oilInterval: 3000,
        componentStates: [
          ComponentMaintenanceState(
            componentId: 'oli-mesin',
            componentName: 'Oli mesin',
            lastServicedKm: 3000,
          ),
          ComponentMaintenanceState(
            componentId: 'busi',
            componentName: 'Busi',
            lastServicedKm: 1000,
          ),
        ],
      );
      const part = MaintenanceComponent(
        id: 'busi',
        name: 'Busi',
        action: 'ganti',
        intervalKm: 8000,
      );
      final result = const RecordComponentService().record(
        data: data,
        component: part,
        odometer: 4500,
        date: DateTime(2026, 3, 1),
      );
      expect(
        result.componentStates
            .firstWhere((state) => state.componentId == 'oli-mesin')
            .lastServicedKm,
        3000,
      );
      expect(
        result.componentStates
            .firstWhere((state) => state.componentId == 'busi')
            .lastServicedKm,
        4500,
      );
      expect(result.odometerLogs, isEmpty);
      expect(result.serviceHistory.single.item, 'Busi');
    },
  );

  test('filter model menentukan part dari transmisi dan pendingin', () {
    final decoded = MaintenanceMotorCatalog.fromJson(
      jsonDecode(
        File('data/motor/data/maintenance_motor_catalog.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>,
    );
    final parts = [
      const MaintenanceComponent(
        id: 'v-belt',
        name: 'V-belt',
        action: 'ganti',
        intervalKm: 1,
      ),
      const MaintenanceComponent(
        id: 'roller',
        name: 'Roller',
        action: 'ganti',
        intervalKm: 1,
      ),
      const MaintenanceComponent(
        id: 'rantai-gear-set',
        name: 'Rantai/gear set',
        action: 'ganti',
        intervalKm: 1,
      ),
      const MaintenanceComponent(
        id: 'coolant',
        name: 'Coolant',
        action: 'ganti',
        intervalKm: 1,
      ),
    ];
    final maticCool = MaintenanceMotor(
      id: 'x',
      name: 'x',
      transmission: 'cvt_matic',
      cooling: 'cair',
      parts: parts.map((part) => part.id!).toList(),
    );
    final maticAir = MaintenanceMotor(
      id: 'x',
      name: 'x',
      transmission: 'cvt_matic',
      cooling: 'udara',
      parts: parts.map((part) => part.id!).toList(),
    );
    final manualCool = MaintenanceMotor(
      id: 'x',
      name: 'x',
      transmission: 'manual',
      cooling: 'cair',
      parts: parts.map((part) => part.id!).toList(),
    );
    expect(
      filterPartsForMotor(
        parts: parts,
        motor: maticCool,
      ).map((part) => part.id),
      containsAll(['v-belt', 'roller', 'coolant']),
    );
    expect(
      filterPartsForMotor(
        parts: parts,
        motor: maticCool,
      ).map((part) => part.id),
      isNot(contains('rantai-gear-set')),
    );
    expect(
      filterPartsForMotor(parts: parts, motor: maticAir).map((part) => part.id),
      isNot(contains('coolant')),
    );
    expect(
      filterPartsForMotor(
        parts: parts,
        motor: manualCool,
      ).map((part) => part.id),
      containsAll(['rantai-gear-set', 'coolant']),
    );
    expect(decoded.motors, hasLength(4));
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
      MaintenanceComponent(
        name: 'Oli mesin',
        action: 'ganti',
        intervalKm: 3000,
      ),
      MaintenanceComponent(
        name: 'Oli gardan',
        action: 'ganti',
        intervalKm: 6000,
        appliesTo: ['matic'],
      ),
      MaintenanceComponent(
        name: 'Rantai',
        action: 'ganti',
        intervalKm: 25000,
        appliesTo: ['bebek', 'sport'],
      ),
      MaintenanceComponent(name: 'Kampas rem', action: 'cek', intervalKm: 4000),
      MaintenanceComponent(
        name: 'Minyak rem',
        action: 'ganti',
        intervalKm: 24000,
        requirement: 'rem_cakram',
      ),
      MaintenanceComponent(
        name: 'Coolant',
        action: 'ganti',
        intervalKm: 12000,
        requirement: 'pendingin_cair',
      ),
    ];

    final matic = filterMaintenanceComponents(
      components: components,
      motorType: 'matic',
      cooling: 'cair',
      frontBrake: 'cakram',
    );
    expect(
      matic.map((component) => component.name),
      containsAll([
        'Oli mesin',
        'Oli gardan',
        'Kampas rem',
        'Minyak rem',
        'Coolant',
      ]),
    );
    expect(matic.map((component) => component.name), isNot(contains('Rantai')));

    final bebek = filterMaintenanceComponents(
      components: components,
      motorType: 'bebek',
      cooling: 'udara',
      frontBrake: 'tromol',
    );
    expect(
      bebek.map((component) => component.name),
      containsAll(['Oli mesin', 'Rantai', 'Kampas rem']),
    );
    expect(
      bebek.map((component) => component.name),
      isNot(contains('Oli gardan')),
    );
    expect(
      bebek.map((component) => component.name),
      isNot(contains('Minyak rem')),
    );
    expect(
      bebek.map((component) => component.name),
      isNot(contains('Coolant')),
    );
  });

  test('pendingin oli tidak memunculkan komponen coolant', () {
    const coolantOnly = [
      MaintenanceComponent(
        name: 'Coolant',
        action: 'ganti',
        intervalKm: 12000,
        requirement: 'pendingin_cair',
      ),
    ];
    expect(
      filterMaintenanceComponents(
        components: coolantOnly,
        motorType: 'sport',
        cooling: 'oli',
        frontBrake: null,
      ),
      isEmpty,
    );
    expect(
      filterMaintenanceComponents(
        components: coolantOnly,
        motorType: 'sport',
        cooling: 'cair',
        frontBrake: null,
      ),
      hasLength(1),
    );
    expect(
      filterMaintenanceComponents(
        components: coolantOnly,
        motorType: 'sport',
        cooling: null,
        frontBrake: null,
      ),
      isEmpty,
    );
  });

  test('komponen dengan aksi cek dikenali sebagai pemeriksaan', () {
    const component = MaintenanceComponent(
      name: 'Kampas rem',
      action: 'cek',
      intervalKm: 4000,
    );
    expect(component.isInspection, isTrue);
  });

  testWidgets('katalog interval default dapat dimuat dari asset', (
    tester,
  ) async {
    final catalog = await const DefaultIntervalRepository().load();
    expect(catalog.components, isNotEmpty);
    expect(
      catalog.components.any((component) => component.name == 'Oli mesin'),
      isTrue,
    );
    expect(
      catalog.components.any(
        (component) => component.requirement == 'rem_cakram',
      ),
      isTrue,
    );
  });

  testWidgets('halaman akun membedakan masuk dan buat akun', (tester) async {
    LocalAccountMode? submittedMode;
    await tester.pumpWidget(
      MaterialApp(
        home: LocalAccountPage(
          initialMode: LocalAccountMode.signIn,
          initialEmail: 'irvan@example.com',
          onSubmit: (mode, email, password) async {
            submittedMode = mode;
            return null;
          },
        ),
      ),
    );

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
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileSetupPage(
          catalog: const MotorModelCatalog(brands: []),
          onSave: (profile) async => saved = profile,
        ),
      ),
    );

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

  test('katalog model motor kosong dapat dibaca', () {
    expect(MotorModelCatalog.fromJson({'brands': []}).brands, isEmpty);
  });

  test('katalog Honda memiliki semua model dan alias yang diminta', () {
    final json = jsonDecode(
      File('data/model_motor.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final honda = MotorModelCatalog.fromJson(json).brands
        .singleWhere((brand) => brand.name == 'Honda');
    expect(honda.models, hasLength(23));
    final vario = honda.models.singleWhere(
      (model) => model.name == 'Vario 125',
    );
    expect(vario.aliases, ['KZR', 'Vario Techno 125']);
    expect(vario.cooling, 'cair');
    expect(
      honda.models.singleWhere((model) => model.name == 'CB150X').notes,
      'Pendingin disimpulkan',
    );
  });

  test('katalog Suzuki menerima pendingin oli', () {
    final model = MotorModel.fromJson({
      'name': 'Gixxer SF 250',
      'jenis': 'sport',
      'pendingin': 'oli',
      'sumber': 'media otomotif; cek situs resmi pabrikan',
    });
    expect(model.cooling, 'oli');
  });

  test('alias dan generasi model masuk dalam pencarian', () {
    final catalog = MotorModelCatalog.fromJson({
      'brands': [
        {
          'name': 'Honda',
          'models': [
            {
              'name': 'Vario 125',
              'generasi': 'Techno / FI 2012-2015',
              'alias': ['KZR', 'Vario Techno 125'],
              'jenis': 'matic',
              'pendingin': 'cair',
              'sumber': 'media otomotif; cek situs resmi pabrikan',
            },
          ],
        },
      ],
    });
    final model = catalog.brands.single.models.single;
    expect(model.searchLabel, contains('KZR'));
    expect(model.searchLabel, contains('Techno / FI 2012-2015'));
  });

  testWidgets('pencarian model menemukan alias KZR', (tester) async {
    const catalog = MotorModelCatalog(
      brands: [
        MotorBrand(
          name: 'Honda',
          models: [
            MotorModel(
              name: 'Vario 125',
              motorType: 'matic',
              cooling: 'cair',
              source: 'media otomotif; cek situs resmi pabrikan',
              generation: 'Techno / FI 2012-2015',
              aliases: ['KZR', 'Vario Techno 125'],
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileSetupPage(catalog: catalog, onSave: (_) async {}),
      ),
    );
    await tester.tap(find.text('Cari atau pilih merek'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Honda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cari atau pilih model'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'KZR');
    await tester.pumpAndSettle();
    expect(
      find.text('Vario 125 (Techno / FI 2012-2015; KZR, Vario Techno 125)'),
      findsOneWidget,
    );
  });

  testWidgets('model terpilih mengisi jenis dan pendingin otomatis', (
    tester,
  ) async {
    DriverMotorProfile? saved;
    const catalog = MotorModelCatalog(
      brands: [
        MotorBrand(
          name: 'Yamaha',
          models: [
            MotorModel(
              name: 'Gear 125',
              motorType: 'matic',
              cooling: 'udara',
              source: 'uji',
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileSetupPage(
          catalog: catalog,
          onSave: (profile) async => saved = profile,
        ),
      ),
    );
    await tester.tap(find.text('Cari atau pilih merek'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yamaha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cari atau pilih model'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gear 125'));
    await tester.pumpAndSettle();
    expect(find.text('Otomatis'), findsNWidgets(2));
    await tester.enterText(find.byType(TextFormField).at(0), 'Irvan');
    await tester.enterText(find.byType(TextFormField).at(1), '2024');
    await _selectDropdown(tester, 'Pilih rem depan', 'Cakram');
    await tester.ensureVisible(find.text('Simpan dan lanjutkan'));
    await tester.tap(find.text('Simpan dan lanjutkan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(saved?.brand, 'Yamaha');
    expect(saved?.model, 'Gear 125');
    expect(saved?.motorType, 'matic');
    expect(saved?.cooling, 'udara');
  });

  testWidgets('koreksi manual mengalahkan nilai otomatis untuk profil', (
    tester,
  ) async {
    DriverMotorProfile? saved;
    const catalog = MotorModelCatalog(
      brands: [
        MotorBrand(
          name: 'Yamaha',
          models: [
            MotorModel(
              name: 'Model uji',
              motorType: 'matic',
              cooling: 'udara',
              source: 'uji',
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileSetupPage(
          catalog: catalog,
          onSave: (profile) async => saved = profile,
        ),
      ),
    );
    await tester.tap(find.text('Cari atau pilih merek'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yamaha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cari atau pilih model'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Model uji'));
    await tester.pumpAndSettle();
    await _selectDropdown(tester, 'Pilih jenis motor', 'Sport');
    await _selectDropdown(tester, 'Pilih pendingin', 'Cair');
    expect(find.text('Manual'), findsNWidgets(2));
    await tester.enterText(find.byType(TextFormField).at(0), 'Irvan');
    await tester.enterText(find.byType(TextFormField).at(1), '2024');
    await _selectDropdown(tester, 'Pilih rem depan', 'Cakram');
    await tester.ensureVisible(find.text('Simpan dan lanjutkan'));
    await tester.tap(find.text('Simpan dan lanjutkan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(saved?.motorType, 'sport');
    expect(saved?.cooling, 'cair');
  });

  testWidgets('opsi Lainnya membuka isian manual', (tester) async {
    DriverMotorProfile? saved;
    const catalog = MotorModelCatalog(
      brands: [
        MotorBrand(
          name: 'Yamaha',
          models: [
            MotorModel(
              name: 'Model uji',
              motorType: 'matic',
              cooling: 'udara',
              source: 'uji',
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileSetupPage(
          catalog: catalog,
          onSave: (profile) async => saved = profile,
        ),
      ),
    );
    await tester.tap(find.text('Cari atau pilih merek'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lainnya'));
    await tester.pumpAndSettle();
    expect(find.text('Merek motor'), findsWidgets);
    await tester.enterText(find.byType(TextFormField).at(0), 'Irvan');
    await tester.enterText(find.byType(TextFormField).at(1), 'Honda');
    await tester.enterText(find.byType(TextFormField).at(2), 'Vario');
    await tester.enterText(find.byType(TextFormField).at(3), '2024');
    await _selectDropdown(tester, 'Pilih jenis motor', 'Matic');
    await _selectDropdown(tester, 'Pilih pendingin', 'Cair');
    await _selectDropdown(tester, 'Pilih rem depan', 'Cakram');
    await tester.ensureVisible(find.text('Simpan dan lanjutkan'));
    await tester.tap(find.text('Simpan dan lanjutkan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(saved?.brand, 'Honda');
    expect(saved?.model, 'Vario');
    expect(saved?.motorType, 'matic');
    expect(saved?.cooling, 'cair');
  });

  testWidgets(
    'halaman komponen menyaring sesuai profil dan menampilkan aksi cek',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = _MemoryMotorDataRepository()
        ..data = const MotorData(
          currentOdometer: 12000,
          lastOilOdometer: 10000,
          oilInterval: 3000,
          componentStates: [
            ComponentMaintenanceState(
              componentName: 'Oli mesin',
              lastServicedKm: 10000,
            ),
            ComponentMaintenanceState(
              componentName: 'Kampas rem',
              lastServicedKm: 8000,
            ),
          ],
        );
      const catalog = MaintenanceCatalog(
        source: 'uji',
        components: [
          MaintenanceComponent(
            name: 'Oli mesin',
            action: 'ganti',
            intervalKm: 3000,
          ),
          MaintenanceComponent(
            name: 'Oli gardan',
            action: 'ganti',
            intervalKm: 6000,
            appliesTo: ['matic'],
          ),
          MaintenanceComponent(
            name: 'V-belt',
            action: 'ganti',
            intervalKm: 20000,
            appliesTo: ['matic'],
          ),
          MaintenanceComponent(
            name: 'Air radiator/coolant',
            action: 'ganti',
            intervalKm: 12000,
            requirement: 'pendingin_cair',
          ),
          MaintenanceComponent(
            name: 'Minyak rem',
            action: 'ganti',
            intervalKm: 24000,
            requirement: 'rem_cakram',
          ),
          MaintenanceComponent(
            name: 'Rantai & gear set',
            action: 'ganti',
            intervalKm: 25000,
            appliesTo: ['bebek', 'sport'],
          ),
          MaintenanceComponent(
            name: 'Kampas rem',
            action: 'cek',
            intervalKm: 4000,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
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
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Komponen'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Interval adalah perkiraan umum'),
        findsOneWidget,
      );
      expect(find.text('Oli gardan'), findsOneWidget);
      expect(find.text('V-belt'), findsOneWidget);
      expect(find.text('Air radiator/coolant'), findsOneWidget);
      expect(find.text('Minyak rem'), findsOneWidget);
      expect(find.text('Rantai & gear set'), findsNothing);
      expect(find.text('Waktunya cek kondisi'), findsOneWidget);
    },
  );

  test('menghitung jadwal oli tanpa bergantung pada antarmuka', () {
    final result = const OilScheduleCalculator().calculate(
      const MotorData(
        currentOdometer: 11500,
        lastOilOdometer: 10000,
        oilInterval: 2000,
      ),
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
      const MotorData(
        currentOdometer: 11500,
        lastOilOdometer: 10000,
        oilInterval: 2000,
      ),
    );
    expect(result.status, OilScheduleStatus.soon);
  });

  test(
    'data motor lama tetap terbaca dan field baru bermigrasi sebagai kosong',
    () {
      final restored = MotorData.fromJson({
        'currentOdometer': 12500,
        'lastOilOdometer': 10000,
        'oilInterval': 2000,
      });
      expect(restored.currentOdometer, 12500);
      expect(restored.oilIntervalMonths, isNull);
      expect(restored.odometerLogs, isEmpty);
      expect(restored.serviceHistory, isEmpty);
    },
  );

  testWidgets('menghitung jadwal dan mencatat ganti oli', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _MemoryMotorDataRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: OilReminderPage(
          loadMotorData: LoadMotorData(repository),
          saveMotorData: SaveMotorData(repository),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Ubah interval'));
    await tester.tap(find.text('Ubah interval'));
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
    await tester.pumpWidget(
      MaterialApp(
        home: OilReminderPage(
          loadMotorData: LoadMotorData(repository),
          saveMotorData: SaveMotorData(repository),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Ubah interval'));
    await tester.tap(find.text('Ubah interval'));
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
