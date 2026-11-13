import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawatin/core/services/vehicle_photo_service.dart';
import 'package:rawatin/core/theme/app_theme.dart';
import 'package:rawatin/core/utils/vehicle_age.dart';
import 'package:rawatin/features/maintenance/domain/entities/motor_data.dart';
import 'package:rawatin/features/maintenance/domain/repositories/motor_data_repository.dart';
import 'package:rawatin/features/maintenance/domain/use_cases/load_motor_data.dart';
import 'package:rawatin/features/maintenance/domain/use_cases/save_motor_data.dart';
import 'package:rawatin/features/maintenance/presentation/pages/oil_reminder_page.dart';
import 'package:rawatin/features/maintenance/presentation/widgets/dashboard_widgets.dart';
import 'package:rawatin/features/profile/data/repositories/local_profile_repository.dart';
import 'package:rawatin/features/profile/domain/entities/driver_motor_profile.dart';
import 'package:rawatin/features/profile/domain/entities/motor_model_catalog.dart';
import 'package:rawatin/features/profile/presentation/pages/profile_setup_page.dart';
import 'package:rawatin/features/profile/presentation/widgets/vehicle_avatar.dart';
import 'package:rawatin/features/profile/presentation/widgets/vehicle_photo_crop_page.dart';
import 'package:rawatin/features/profile/presentation/widgets/vehicle_photo_viewer.dart';
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
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
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
  group('Perhitungan umur kendaraan (VehicleAge)', () {
    test('menolak tanggal beli di masa depan', () {
      final now = DateTime(2026, 11, 7);
      final futureDate = DateTime(2026, 11, 8);
      expect(calculateVehicleAge(futureDate, now), isNull);
      expect(formatVehicleAge(futureDate, now), isNull);
    });

    test('kurang dari 1 bulan', () {
      final now = DateTime(2026, 11, 7);
      final purchaseDate = DateTime(2026, 10, 20);
      final age = calculateVehicleAge(purchaseDate, now);
      expect(age, isNotNull);
      expect(age!.years, 0);
      expect(age.months, 0);
      expect(age.label, 'Kurang dari 1 bulan');
      expect(age.fullText, 'Umur kendaraan: Kurang dari 1 bulan');
    });

    test('tepat dalam hitungan bulan tanpa tahun', () {
      final now = DateTime(2026, 11, 7);
      final purchaseDate = DateTime(2026, 5, 7);
      final age = calculateVehicleAge(purchaseDate, now);
      expect(age, isNotNull);
      expect(age!.years, 0);
      expect(age.months, 6);
      expect(age.label, '6 bulan');
      expect(age.fullText, 'Umur kendaraan: 6 bulan');
    });

    test('tepat dalam hitungan tahun genap', () {
      final now = DateTime(2026, 11, 7);
      final purchaseDate = DateTime(2024, 11, 7);
      final age = calculateVehicleAge(purchaseDate, now);
      expect(age, isNotNull);
      expect(age!.years, 2);
      expect(age.months, 0);
      expect(age.label, '2 tahun');
      expect(age.fullText, 'Umur kendaraan: 2 tahun');
    });

    test('kombinasi tahun dan bulan', () {
      final now = DateTime(2026, 11, 7);
      final purchaseDate = DateTime(2024, 8, 5);
      final age = calculateVehicleAge(purchaseDate, now);
      expect(age, isNotNull);
      expect(age!.years, 2);
      expect(age.months, 3);
      expect(age.label, '2 tahun 3 bulan');
      expect(age.fullText, 'Umur kendaraan: 2 tahun 3 bulan');
    });

    test('perhitungan batas akhir bulan (31 Jan ke 28 Feb)', () {
      final now = DateTime(2026, 2, 28);
      final purchaseDate = DateTime(2026, 1, 31);
      final age = calculateVehicleAge(purchaseDate, now);
      expect(age, isNotNull);
      expect(age!.years, 0);
      // Karena 28 < 31, belum genap 1 bulan penuh
      expect(age.months, 0);
      expect(age.label, 'Kurang dari 1 bulan');
    });

    test('perhitungan melewati pergantian tahun', () {
      final now = DateTime(2026, 2, 10);
      final purchaseDate = DateTime(2025, 11, 10);
      final age = calculateVehicleAge(purchaseDate, now);
      expect(age, isNotNull);
      expect(age!.years, 0);
      expect(age.months, 3);
      expect(age.label, '3 bulan');
    });
  });

  group('Migrasi dan repositori profil lokal (LocalProfileRepository)', () {
    test(
      'data profil lama tanpa field baru tetap terbaca normal sebagai null',
      () async {
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({
              'rawatin.profiles.v1': '[{"id":"v1","driverName":"Budi","brand":"Yamaha","model":"NMAX","year":2022,"motorType":"matic"}]',
            });

        final repo = LocalProfileRepository(SharedPreferencesAsync());
        final profiles = await repo.loadAll();

        expect(profiles, hasLength(1));
        final profile = profiles.first;
        expect(profile.id, 'v1');
        expect(profile.driverName, 'Budi');
        expect(profile.brand, 'Yamaha');
        expect(profile.model, 'NMAX');
        expect(profile.year, 2022);
        expect(profile.nickname, isNull);
        expect(profile.photoPath, isNull);
        expect(profile.purchaseDate, isNull);
      },
    );

    test('data profil legacy single record tetap terbaca normal', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            'profile.driver_name': 'Siti',
            'profile.motor_brand': 'Honda',
            'profile.motor_model': 'Beat',
            'profile.motor_year': 2021,
          });

      final repo = LocalProfileRepository(SharedPreferencesAsync());
      final profile = await repo.load();

      expect(profile, isNotNull);
      expect(profile!.driverName, 'Siti');
      expect(profile.brand, 'Honda');
      expect(profile.model, 'Beat');
      expect(profile.year, 2021);
      expect(profile.nickname, isNull);
      expect(profile.photoPath, isNull);
      expect(profile.purchaseDate, isNull);
    });

    test('menyimpan dan memuat profil baru lengkap dengan nickname, photoPath, dan purchaseDate', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final repo = LocalProfileRepository(SharedPreferencesAsync());

      final purchase = DateTime(2023, 4, 15);
      const newProfile = DriverMotorProfile(
        id: 'motor-1',
        driverName: 'Irvan',
        brand: 'Yamaha',
        model: 'Gear 125',
        year: 2024,
        nickname: 'Si Gesit',
        photoPath: '/data/user/0/com.rawatin/photos/gear.jpg',
        purchaseDate: null,
      );
      final profileWithDate = newProfile.copyWith(purchaseDate: purchase);

      await repo.save(profileWithDate);

      final loaded = await repo.load();
      expect(loaded, isNotNull);
      expect(loaded!.nickname, 'Si Gesit');
      expect(loaded.photoPath, '/data/user/0/com.rawatin/photos/gear.jpg');
      expect(loaded.purchaseDate, purchase);

      final all = await repo.loadAll();
      expect(all, hasLength(1));
      expect(all.first.nickname, 'Si Gesit');
      expect(all.first.photoPath, '/data/user/0/com.rawatin/photos/gear.jpg');
      expect(all.first.purchaseDate, purchase);
    });

    test('menghapus kendaraan dan memilih kendaraan tersisa jika yang aktif dihapus', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final repo = LocalProfileRepository(SharedPreferencesAsync());
      final first = DriverMotorProfile(
        id: 'vehicle-a',
        driverName: 'Irvan',
        brand: 'Honda',
        model: 'BeAT',
        year: 2024,
      );
      final second = DriverMotorProfile(
        id: 'vehicle-b',
        driverName: 'Irvan',
        brand: 'Yamaha',
        model: 'Fazzio',
        year: 2025,
      );
      await repo.saveVehicle(first);
      await repo.saveVehicle(second);

      final deleted = await repo.deleteVehicle(second.id);

      expect(deleted?.id, second.id);
      expect((await repo.loadAll()).map((item) => item.id), [first.id]);
      expect(await repo.loadSelectedProfileId(), first.id);
      expect((await repo.load())?.model, first.model);
    });

    test(
      'menghapus satu-satunya kendaraan membersihkan profil legacy',
      () async {
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.empty();
        final repo = LocalProfileRepository(SharedPreferencesAsync());
        final profile = DriverMotorProfile(
          id: 'vehicle-a',
          driverName: 'Irvan',
          brand: 'Honda',
          model: 'BeAT',
          year: 2024,
        );
        await repo.saveVehicle(profile);

        expect(await repo.deleteVehicle(profile.id), isNotNull);

        expect(await repo.loadAll(), isEmpty);
        expect(await repo.loadSelectedProfileId(), isNull);
        expect(await repo.load(), isNull);
      },
    );

    test('copyWith dengan flag penghapusan eksplisit bekerja dengan benar', () {
      final profile = DriverMotorProfile(
        driverName: 'Irvan',
        brand: 'Yamaha',
        model: 'Gear 125',
        year: 2024,
        nickname: 'Si Merah',
        photoPath: '/path/to/pic.jpg',
        purchaseDate: DateTime(2023, 1, 1),
      );

      final cleared = profile.copyWith(
        clearNickname: true,
        clearPhoto: true,
        clearPurchaseDate: true,
      );

      expect(cleared.nickname, isNull);
      expect(cleared.photoPath, isNull);
      expect(cleared.purchaseDate, isNull);
      expect(cleared.driverName, 'Irvan');
    });
  });

  group('Pesan error VehiclePhotoService', () {
    test('pesan ramah saat izin ditolak', () {
      final error = Exception('Camera permission denied by user');
      final msg = VehiclePhotoService.resolveErrorMessage(error);
      expect(msg, contains('Izin akses kamera atau galeri ditolak'));
      expect(msg, contains('Pengaturan'));
    });

    test('pesan ramah saat format file tidak valid', () {
      final error = Exception('Unsupported format');
      final msg = VehiclePhotoService.resolveErrorMessage(error);
      expect(msg, contains('Gagal memuat foto'));
    });
  });

  group('Widget VehicleAvatar', () {
    testWidgets('menampilkan fallback ikon motor saat photoPath null', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(body: VehicleAvatar(photoPath: null, size: 48)),
        ),
      );

      expect(find.byIcon(AppIcons.vehicle), findsOneWidget);
    });

    testWidgets('placeholder netral foto tidak menampilkan ikon motor', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: VehicleAvatar(
              photoPath: null,
              size: 48,
              useNeutralPlaceholder: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
      expect(find.byIcon(AppIcons.vehicle), findsNothing);
    });

    testWidgets(
      'menampilkan fallback ikon motor saat file gambar lokal tidak ada',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: const Scaffold(
              body: VehicleAvatar(
                photoPath: '/non/existent/path/image.jpg',
                size: 48,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(AppIcons.vehicle), findsOneWidget);
      },
    );

    testWidgets('area ketuk memenuhi minimal 48dp', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: VehicleAvatar(size: 36, onTap: () => tapped = true),
          ),
        ),
      );

      final renderBox = tester.renderObject<RenderBox>(
        find.byType(VehicleAvatar),
      );
      expect(renderBox.size.width, greaterThanOrEqualTo(48.0));
      expect(renderBox.size.height, greaterThanOrEqualTo(48.0));

      await tester.tap(find.byType(VehicleAvatar));
      expect(tapped, isTrue);
    });
  });

  group('Widget foto kendaraan', () {
    testWidgets('editor crop menampilkan kontrol sesuaikan dan simpan', (
      tester,
    ) async {
      Uint8List? savedBytes;
      final imageBytes = (await rootBundle.load(
        'assets/brand/rawatin_icon.png',
      )).buffer.asUint8List();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  savedBytes = await Navigator.of(context).push<Uint8List>(
                    MaterialPageRoute(
                      builder: (_) => VehiclePhotoCropPage(bytes: imageBytes),
                    ),
                  );
                },
                child: const Text('Buka editor'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka editor'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Sesuaikan foto'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(savedBytes, isNull);
    });

    testWidgets('viewer fullscreen menyediakan zoom dan fallback file gagal', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VehiclePhotoViewer(photoPath: '/file/tidak-ada.jpg'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('Foto kendaraan'), findsOneWidget);
      expect(find.text('Foto tidak dapat dibuka.'), findsOneWidget);
    });
  });

  group('Widget ProfileSetupPage – Bagian Kendaraanku', () {
    testWidgets('dapat mengisi nama panggilan motor dan menyimpannya', (
      tester,
    ) async {
      DriverMotorProfile? saved;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: ProfileSetupPage(
            catalog: const MotorModelCatalog(brands: []),
            onSave: (profile) async => saved = profile,
          ),
        ),
      );

      // Pastikan bagian "Kendaraanku" ada
      expect(find.text('Kendaraanku'), findsOneWidget);
      expect(find.text('Nama panggilan motor'), findsOneWidget);

      // Isi form dasar
      await tester.enterText(find.byType(TextFormField).at(0), 'Irvan');
      await tester.enterText(find.byType(TextFormField).at(1), 'Yamaha');
      await tester.enterText(find.byType(TextFormField).at(2), 'Gear 125');
      await tester.enterText(find.byType(TextFormField).at(3), '2024');

      // Scroll ke bagian nama panggilan & isi
      final nicknameField = find.widgetWithText(
        TextFormField,
        'Nama panggilan motor',
      );
      await tester.ensureVisible(nicknameField);
      await tester.enterText(nicknameField, 'Si Gesit');

      // Pilih dropdown yang wajib
      await _selectDropdown(tester, 'Pilih jenis motor', 'Matic');
      await _selectDropdown(tester, 'Pilih pendingin', 'Udara');
      await tester.ensureVisible(find.text('Simpan dan lanjutkan'));
      await tester.tap(find.text('Simpan dan lanjutkan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(saved?.nickname, 'Si Gesit');
      expect(saved?.driverName, 'Irvan');
      expect(saved?.model, 'Gear 125');
    });

    testWidgets(
      'menampilkan model motor sebagai keterangan di bawah nama panggilan',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: ProfileSetupPage(
              initialProfile: const DriverMotorProfile(
                driverName: 'Irvan',
                brand: 'Yamaha',
                model: 'Gear 125',
                year: 2024,
                nickname: 'Si Merah',
              ),
              onSave: (_) async {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Model: Yamaha Gear 125'), findsOneWidget);
        expect(find.text('Si Merah'), findsOneWidget);
      },
    );

    testWidgets(
      'menampilkan umur kendaraan saat initialProfile memiliki purchaseDate',
      (tester) async {
        // 2 tahun lalu
        final twoYearsAgo = DateTime(
          DateTime.now().year - 2,
          DateTime.now().month,
          DateTime.now().day,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: ProfileSetupPage(
              initialProfile: DriverMotorProfile(
                driverName: 'Irvan',
                brand: 'Yamaha',
                model: 'Gear 125',
                year: 2024,
                purchaseDate: twoYearsAgo,
              ),
              onSave: (_) async {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Umur kendaraan: 2 tahun'), findsOneWidget);

        // Scroll dan hapus tanggal beli dengan tombol hapus
        final clearButton = find.byTooltip('Hapus tanggal beli');
        await tester.ensureVisible(clearButton);
        await tester.pumpAndSettle();
        await tester.tap(clearButton);
        await tester.pumpAndSettle();

        expect(find.textContaining('Umur kendaraan:'), findsNothing);
        expect(find.text('Pilih tanggal beli'), findsOneWidget);
      },
    );

    testWidgets('nama panggilan dibatasi maksimal 40 karakter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: ProfileSetupPage(
            catalog: const MotorModelCatalog(brands: []),
            onSave: (_) async {},
          ),
        ),
      );

      final nicknameField = find.widgetWithText(
        TextFormField,
        'Nama panggilan motor',
      );
      await tester.ensureVisible(nicknameField);
      // Masukkan teks 50 karakter
      const longText =
          'Nama Motor Yang Sangat Panjang Sekali Melebihi Batas Maksimal';
      await tester.enterText(nicknameField, longText);
      await tester.pumpAndSettle();

      final editable = tester.widget<EditableText>(
        find.descendant(of: nicknameField, matching: find.byType(EditableText)),
      );
      // Harus terpotong tepat pada 40 karakter
      expect(editable.controller.text.length, lessThanOrEqualTo(40));
    });

    testWidgets(
      'membuka pemilih tanggal beli dan menampilkan umur kendaraan setelah dipilih',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: ProfileSetupPage(
              catalog: const MotorModelCatalog(brands: []),
              onSave: (_) async {},
            ),
          ),
        );

        final datePickerTile = find.text('Pilih tanggal beli');
        await tester.ensureVisible(datePickerTile);
        await tester.pumpAndSettle();
        await tester.tap(datePickerTile);
        await tester.pumpAndSettle();

        // Dialog date picker muncul
        expect(find.text('PILIH TANGGAL BELI MOTOR'), findsOneWidget);
        // Konfirmasi pemilihan tanggal (hari ini)
        await tester.tap(find.text('PILIH'));
        await tester.pumpAndSettle();

        // Teks umur kendaraan muncul di form
        expect(find.textContaining('Umur kendaraan:'), findsOneWidget);
      },
    );
  });

  group('Header Beranda dan Kartu Profil Kendaraan', () {
    testWidgets(
      'DashboardHeader menampilkan sapaan tanpa mengulang identitas motor',
      (tester) async {
        const profile = DriverMotorProfile(
          driverName: 'Irvan',
          brand: 'Yamaha',
          model: 'Gear 125',
          year: 2024,
          nickname: 'Si Merah',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: const Scaffold(body: DashboardHeader(profile: profile)),
          ),
        );

        expect(find.text('Hai, Irvan!'), findsOneWidget);
        expect(find.byType(VehicleAvatar), findsNothing);
        expect(
          find.text('Jadwal dan catatan perawatan dalam satu tempat.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Kartu profil menampilkan foto, nama panggilan, model, dan umur kendaraan',
      (tester) async {
        final repo = _MemoryMotorDataRepository();
        final oneYearAgo = DateTime(
          DateTime.now().year - 1,
          DateTime.now().month,
          DateTime.now().day,
        );

        final profile = DriverMotorProfile(
          driverName: 'Irvan',
          brand: 'Honda',
          model: 'Scoopy',
          year: 2023,
          motorType: 'matic',
          nickname: 'Si Imut',
          purchaseDate: oneYearAgo,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: OilReminderPage(
              loadMotorData: LoadMotorData(repo),
              saveMotorData: SaveMotorData(repo),
              profile: profile,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Nama panggilan ditampilkan sekali pada kartu identitas motor.
        expect(find.text('Hai, Irvan!'), findsOneWidget);
        expect(find.text('Si Imut'), findsOneWidget);
        // Model tetap tampil sebagai keterangan di bawah nama panggilan
        expect(find.textContaining('Honda Scoopy · 2023'), findsOneWidget);
        // Umur kendaraan tampil
        expect(find.textContaining('Umur kendaraan: 1 tahun'), findsOneWidget);
        // Foto kendaraan tampil dengan VehicleAvatar
        expect(find.byType(VehicleAvatar), findsWidgets);
      },
    );

    testWidgets('kartu tanpa nama panggilan memakai model sebagai judul', (
      tester,
    ) async {
      final repo = _MemoryMotorDataRepository();
      var editProfileTapped = false;
      const profile = DriverMotorProfile(
        driverName: 'Irvan',
        brand: 'Yamaha',
        model: 'Gear 125',
        year: 2024,
        motorType: 'matic',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: OilReminderPage(
            loadMotorData: LoadMotorData(repo),
            saveMotorData: SaveMotorData(repo),
            profile: profile,
            onEditProfile: () => editProfileTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hai, Irvan!'), findsOneWidget);
      expect(find.text('Yamaha Gear 125'), findsWidgets);
      expect(find.text('2024 · Matic'), findsOneWidget);
      expect(find.text('Tambahkan foto motor di profil'), findsOneWidget);
      expect(find.byIcon(AppIcons.vehicle), findsNothing);

      await tester.tap(find.text('Tambahkan foto motor di profil'));
      expect(editProfileTapped, isTrue);
    });
  });
}
