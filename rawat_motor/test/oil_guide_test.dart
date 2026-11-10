import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:rawatin/features/maintenance/domain/entities/maintenance_motor_catalog.dart';
import 'package:rawatin/features/maintenance/domain/entities/maintenance_component.dart';
import 'package:rawatin/features/maintenance/domain/entities/maintenance_catalog.dart';
import 'package:rawatin/features/maintenance/domain/entities/motor_data.dart';
import 'package:rawatin/features/maintenance/domain/entities/oil_specification.dart';
import 'package:rawatin/features/maintenance/domain/repositories/motor_data_repository.dart';
import 'package:rawatin/features/maintenance/domain/use_cases/load_motor_data.dart';
import 'package:rawatin/features/maintenance/domain/use_cases/save_motor_data.dart';
import 'package:rawatin/features/maintenance/domain/services/ai_service.dart';
import 'package:rawatin/features/maintenance/data/services/fake_ai_service.dart';
import 'package:rawatin/features/maintenance/data/services/ai_consent_storage.dart';
import 'package:rawatin/features/maintenance/data/services/http_oil_specification_service.dart';
import 'package:rawatin/features/maintenance/domain/services/oil_specification_service.dart';
import 'package:rawatin/features/maintenance/presentation/pages/oil_guide_page.dart';
import 'package:rawatin/features/maintenance/presentation/pages/oil_reminder_page.dart';
import 'package:rawatin/features/maintenance/presentation/content/oil_guide_content.dart';
import 'package:rawatin/features/profile/domain/entities/motor_model_catalog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper: repositori data motor di memori
// ─────────────────────────────────────────────────────────────────────────────
class _MemoryMotorDataRepository implements MotorDataRepository {
  MotorData? data;

  @override
  Future<void> clear() async => data = null;

  @override
  Future<MotorData?> load() async => data;

  @override
  Future<void> save(MotorData value) async => data = value;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: consent yang langsung menyetujui tanpa dialog (untuk tes UI)
// ─────────────────────────────────────────────────────────────────────────────
class _AutoConsentStorage implements AiConsentStorage {
  @override
  Future<bool> hasConsent() async => true;

  @override
  Future<void> setConsent(bool consent) async {}

  @override
  Future<String> getOrCreateInstallId() async => 'test-install-id';
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: consent yang belum pernah menyetujui
// ─────────────────────────────────────────────────────────────────────────────
class _NoConsentStorage implements AiConsentStorage {
  @override
  Future<bool> hasConsent() async => false;

  @override
  Future<void> setConsent(bool consent) async {}

  @override
  Future<String> getOrCreateInstallId() async => 'test-install-id';
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: AI service yang merekam apakah dipanggil
// ─────────────────────────────────────────────────────────────────────────────
class _SpyAiService implements AiService {
  int callCount = 0;

  @override
  Future<AiOilResponse> askOilGuide(AiOilRequest request) async {
    callCount++;
    return const AiOilResponse(answer: 'Jawaban spy AI.');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: AI service yang selalu melempar galat dengan kode tertentu
// ─────────────────────────────────────────────────────────────────────────────
class _ThrowingAiService implements AiService {
  const _ThrowingAiService(this.code, this.message);

  final String code;
  final String message;

  @override
  Future<AiOilResponse> askOilGuide(AiOilRequest request) async {
    throw AiServiceException(code: code, message: message);
  }
}

Widget _buildPage({
  MaintenanceMotor? motor,
  AiService? aiService,
  AiConsentStorage? consentStorage,
  VoidCallback? onRecord,
}) => MaterialApp(
  home: OilGuidePage(
    motor: motor,
    aiService: aiService ?? const FakeAiService(),
    consentStorage: consentStorage ?? _AutoConsentStorage(),
    onRecordOilService: onRecord,
  ),
);

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  // ─── 1. Konten & Tampilan ─────────────────────────────────────────────────

  group('OilGuideContent – konten panduan', () {
    test('memiliki tepat 8 bagian panduan', () {
      expect(OilGuideContent.sections, hasLength(8));
    });

    test('fullReferenceText mengandung semua judul bagian', () {
      final text = OilGuideContent.fullReferenceText;
      for (final section in OilGuideContent.sections) {
        expect(text, contains(section.title));
      }
    });
  });

  group('OilGuidePage – tampilan layar', () {
    testWidgets('menampilkan 8 judul accordion', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pumpAndSettle();

      for (final section in OilGuideContent.sections) {
        expect(find.text(section.title), findsOneWidget);
      }
    });

    testWidgets('bagian pertama terbuka secara default', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pumpAndSettle();

      expect(find.text(OilGuideContent.sections.first.content), findsOneWidget);
    });

    testWidgets('menampilkan banner disclaimer', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pumpAndSettle();

      expect(find.text(OilGuideContent.banner), findsOneWidget);
    });

    testWidgets('tombol Catat ganti oli ada di action bar', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Catat ganti oli'), findsOneWidget);
    });
  });

  // ─── 2. Spesifikasi Motor ─────────────────────────────────────────────────

  group('OilGuidePage – spesifikasi motor', () {
    final motorVerified = MaintenanceMotor(
      id: 'test-verified',
      name: 'Vario 125 Test',
      transmission: 'matic',
      cooling: 'udara',
      parts: const ['oli-mesin'],
      oilSpec: const OilSpecification(
        sae: '10W-30',
        jaso: 'JASO MB',
        volume: '0.8 L',
        verified: true,
      ),
    );

    final motorUnverified = MaintenanceMotor(
      id: 'test-unverified',
      name: 'Beat Test',
      transmission: 'matic',
      cooling: 'udara',
      parts: const ['oli-mesin'],
    );

    testWidgets('menampilkan SAE, JASO, volume jika motor verified', (
      tester,
    ) async {
      await tester.pumpWidget(_buildPage(motor: motorVerified));
      await tester.pumpAndSettle();

      expect(find.text('10W-30'), findsOneWidget);
      expect(find.text('JASO MB'), findsOneWidget);
      expect(find.text('0.8 L'), findsOneWidget);
      expect(find.text('Terverifikasi'), findsOneWidget);
    });

    testWidgets(
      'TIDAK menampilkan angka spesifikasi jika motor belum verified',
      (tester) async {
        await tester.pumpWidget(_buildPage(motor: motorUnverified));
        await tester.pumpAndSettle();

        expect(find.text(OilGuideContent.unverifiedWarning), findsOneWidget);
        expect(find.text('10W-30'), findsNothing);
      },
    );

    testWidgets('menampilkan peringatan unverified jika motor null', (
      tester,
    ) async {
      await tester.pumpWidget(_buildPage());
      await tester.pumpAndSettle();

      expect(find.text(OilGuideContent.unverifiedWarning), findsOneWidget);
    });
  });

  // ─── 3. Backward Compatibility Data Motor ────────────────────────────────

  group('OilSpecification – backward compatibility', () {
    test('MotorModel lama tanpa oil_spec tetap dapat di-parse', () {
      final json = {
        'name': 'Beat',
        'jenis': 'matic',
        'pendingin': 'udara',
        'sumber': 'tes',
      };
      final model = MotorModel.fromJson(json);
      expect(model.oilSpec, isNull);
    });

    test('MaintenanceMotor lama tanpa oil_spec tetap dapat di-parse', () {
      final json = {
        'id': 'honda-beat',
        'nama': 'Beat',
        'transmisi': 'matic',
        'pendingin': 'udara',
        'parts': <String>['oli-mesin'],
      };
      final motor = MaintenanceMotor.fromJson(json);
      expect(motor.oilSpec, isNull);
    });

    test('MaintenanceMotor dengan spesifikasi_oli dapat di-parse', () {
      final json = {
        'id': 'honda-vario',
        'nama': 'Vario 125',
        'transmisi': 'matic',
        'pendingin': 'udara',
        'parts': <String>['oli-mesin'],
        'spesifikasi_oli': {
          'sae': '10W-30',
          'jaso': 'JASO MB',
          'volume': '0.8 L',
          'verified': true,
        },
      };
      final motor = MaintenanceMotor.fromJson(json);
      expect(motor.oilSpec, isNotNull);
      expect(motor.oilSpec!.sae, '10W-30');
      expect(motor.oilSpec!.verified, isTrue);
    });

    test('OilSpecification dengan verified=false tetap dapat di-parse', () {
      final spec = OilSpecification.fromJson({
        'sae': '10W-40',
        'jaso': 'JASO MA2',
        'volume': '1.0 L',
        'verified': false,
      });
      expect(spec.verified, isFalse);
    });
  });

  group('HttpOilSpecificationService – online dan cache', () {
    test('memakai spesifikasi online dan menyimpannya ke cache', () async {
      final service = HttpOilSpecificationService(
        baseUrl: 'https://oil.example.test',
        fetcher: (uri) async => {
          'oil_spec': {
            'sae': '10W-30',
            'jaso': 'JASO MB',
            'volume': '0.8 L',
            'verified': true,
            'source': 'Buku pedoman resmi',
            'updated_at': '2026-11-10T00:00:00.000Z',
          },
        },
      );
      final result = await service.load(
        motorId: 'honda-vario-160',
        motorName: 'Honda Vario 160',
        year: 2024,
      );

      expect(result.sourceType, OilSpecificationSourceType.online);
      expect(result.specification?.sae, '10W-30');
      expect(result.specification?.source, 'Buku pedoman resmi');
    });

    test('memakai cache terakhir ketika endpoint offline', () async {
      final firstService = HttpOilSpecificationService(
        baseUrl: 'https://oil.example.test',
        fetcher: (uri) async => {
          'sae': '10W-40',
          'jaso': 'JASO MB',
          'volume': '0.8 L',
          'verified': true,
        },
      );
      final first = await firstService.load(
        motorId: 'honda-beat',
        motorName: 'Honda Beat',
        year: 2024,
      );
      final cachedService = HttpOilSpecificationService(
        baseUrl: 'https://oil.example.test',
        fetcher: (uri) async => null,
      );
      final cached = await cachedService.load(
        motorId: 'honda-beat',
        motorName: 'Honda Beat',
        year: 2024,
      );

      expect(first.sourceType, OilSpecificationSourceType.online);
      expect(cached.sourceType, OilSpecificationSourceType.cache);
      expect(cached.specification?.sae, '10W-40');
    });

    test('fallback ke katalog lokal tanpa URL backend', () async {
      const local = OilSpecification(
        sae: '10W-30',
        jaso: 'JASO MB',
        volume: '0.8 L',
        verified: true,
      );
      final result = await HttpOilSpecificationService(baseUrl: '').load(
        motorId: 'honda-beat',
        motorName: 'Honda Beat',
        year: 2024,
        localSpecification: local,
      );

      expect(result.sourceType, OilSpecificationSourceType.local);
      expect(result.specification, local);
    });
  });

  // ─── 4. FakeAiService ─────────────────────────────────────────────────────

  group('FakeAiService – perilaku asisten AI', () {
    test('menjawab pertanyaan SAE dengan jawaban bermakna', () async {
      const service = FakeAiService();
      final response = await service.askOilGuide(
        AiOilRequest(
          installId: 'test-id',
          question: 'Bedanya 10W-30 dan 10W-40?',
          motor: AiMotorContext(id: 'test', name: 'Motor Test'),
          reference: OilGuideContent.fullReferenceText,
        ),
      );
      expect(response.answer, isNotEmpty);
      expect(response.refused, isFalse);
    });

    test('menolak pertanyaan di luar topik dengan refused=true', () async {
      const service = FakeAiService();
      final response = await service.askOilGuide(
        AiOilRequest(
          installId: 'test-id',
          question: 'Siapa presiden Indonesia?',
          motor: AiMotorContext(id: 'test', name: 'Motor Test'),
          reference: OilGuideContent.fullReferenceText,
        ),
      );
      expect(response.refused, isTrue);
    });

    test(
      'melempar AiServiceException code=too_long jika > 500 karakter',
      () async {
        const service = FakeAiService();
        final longQuestion = 'a' * 501;
        expect(
          () => service.askOilGuide(
            AiOilRequest(
              installId: 'test-id',
              question: longQuestion,
              motor: AiMotorContext(id: 'test', name: 'Motor Test'),
              reference: 'ref',
            ),
          ),
          throwsA(
            isA<AiServiceException>().having((e) => e.code, 'code', 'too_long'),
          ),
        );
      },
    );

    test('simulasi __test_rate_limit__ menghasilkan AiServiceException', () {
      const service = FakeAiService();
      expect(
        () => service.askOilGuide(
          AiOilRequest(
            installId: 'test-id',
            question: '__test_rate_limit__',
            motor: AiMotorContext(id: 'test', name: 'Motor Test'),
            reference: 'ref',
          ),
        ),
        throwsA(
          isA<AiServiceException>().having(
            (e) => e.code,
            'code',
            'rate_limited',
          ),
        ),
      );
    });

    test(
      'menyertakan spesifikasi motor dalam jawaban jika verified=true',
      () async {
        const service = FakeAiService();
        final response = await service.askOilGuide(
          AiOilRequest(
            installId: 'test-id',
            question: 'Oli apa yang cocok untuk motorku?',
            motor: AiMotorContext(
              id: 'honda-vario',
              name: 'Vario 125',
              oilSpec: const AiOilSpecContext(
                sae: '10W-30',
                jaso: 'JASO MB',
                volume: '0.8 L',
              ),
            ),
            reference: OilGuideContent.fullReferenceText,
          ),
        );
        expect(response.answer, contains('10W-30'));
      },
    );

    test('tidak menyebut merek oli dalam jawaban', () async {
      const service = FakeAiService();
      final response = await service.askOilGuide(
        AiOilRequest(
          installId: 'test-id',
          question: 'kapan ganti oli untuk kondisi macet?',
          motor: AiMotorContext(id: 'test', name: 'Motor Test'),
          reference: OilGuideContent.fullReferenceText,
        ),
      );
      final lower = response.answer.toLowerCase();
      expect(lower, isNot(contains('motul')));
      expect(lower, isNot(contains('castrol')));
      expect(lower, isNot(contains('shell')));
    });

    test('request tanpa oilSpec mengirim null (belum verified)', () {
      final request = AiOilRequest(
        installId: 'test-id',
        question: 'Oli apa yang cocok?',
        motor: AiMotorContext(id: 'unverified-motor', name: 'Motor Test'),
        reference: OilGuideContent.fullReferenceText,
      );
      expect(request.motor.oilSpec, isNull);
    });
  });

  // ─── 5. UI Widget AI ─────────────────────────────────────────────────────

  group('OilGuidePage – UI asisten AI', () {
    testWidgets('menampilkan header asisten AI', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pumpAndSettle();

      // Cari dengan descendant finder agar tidak ambigu dengan banyak scrollable
      expect(find.text('TANYA PANDUAN OLI'), findsOneWidget);
    });

    testWidgets('menampilkan chip pertanyaan contoh', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Bedanya 10W-30 dan 10W-40?'), findsOneWidget);
      expect(
        find.text('Kalau tiap hari macet, oli lebih cepat diganti?'),
        findsOneWidget,
      );
    });

    testWidgets('tanpa persetujuan tidak ada panggilan layanan AI', (
      tester,
    ) async {
      final spyService = _SpyAiService();

      await tester.pumpWidget(
        _buildPage(aiService: spyService, consentStorage: _NoConsentStorage()),
      );
      await tester.pumpAndSettle();

      // Ketik di input paling bawah (satu-satunya TextField)
      final inputField = find.byType(TextField);
      expect(inputField, findsOneWidget);

      await tester.enterText(inputField, 'tanya sesuatu?');
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Kirim pertanyaan'));
      await tester.pumpAndSettle();

      // Dialog consent muncul; AI belum dipanggil
      expect(spyService.callCount, 0);
    });

    testWidgets('jawaban muncul setelah pertanyaan dikirim', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pumpAndSettle();

      final inputField = find.byType(TextField);
      expect(inputField, findsOneWidget);

      await tester.enterText(inputField, 'kapan ganti oli?');
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Kirim pertanyaan'));
      await tester.pumpAndSettle();

      // Pertanyaan pengguna tampil di chat history
      expect(find.text('kapan ganti oli?'), findsOneWidget);
    });

    testWidgets('pesan rate limit tampil dengan tombol Coba lagi', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildPage(
          aiService: const _ThrowingAiService(
            'rate_limited',
            'Terlalu banyak pertanyaan. Mohon tunggu sebentar.',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'kapan ganti oli?');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Kirim pertanyaan'));
      await tester.pumpAndSettle();

      expect(
        find.text('Terlalu banyak pertanyaan. Mohon tunggu sebentar.'),
        findsOneWidget,
      );
      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets('pesan galat jaringan tampil dengan tombol Coba lagi', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildPage(
          aiService: const _ThrowingAiService(
            'network_error',
            'Tidak dapat terhubung ke server. Periksa koneksi internet.',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'kapan ganti oli?');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Kirim pertanyaan'));
      await tester.pumpAndSettle();

      expect(
        find.text('Tidak dapat terhubung ke server. Periksa koneksi internet.'),
        findsOneWidget,
      );
      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets('AI belum dikonfigurasi menampilkan Segera hadir', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildPage(
          aiService: const _ThrowingAiService(
            'ai_unconfigured',
            'Layanan AI belum dikonfigurasi.',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'kapan ganti oli?');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Kirim pertanyaan'));
      await tester.pumpAndSettle();

      expect(find.text('Segera hadir'), findsOneWidget);
      expect(find.text('TANYA PANDUAN OLI'), findsOneWidget);
    });
  });

  // ─── 6. Navigasi dari kartu Oli mesin & Oli gardan ───────────────────────

  group('OilReminderPage – pintu masuk Panduan oli', () {
    Widget buildReminderPage({
      required MaintenanceCatalog catalog,
      required MotorData data,
    }) {
      final repository = _MemoryMotorDataRepository()..data = data;
      return MaterialApp(
        home: OilReminderPage(
          loadMotorData: LoadMotorData(repository),
          saveMotorData: SaveMotorData(repository),
          catalog: catalog,
        ),
      );
    }

    testWidgets('membuka panduan dari kartu Oli mesin', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const catalog = MaintenanceCatalog(
        source: 'uji',
        components: [
          MaintenanceComponent(
            name: 'Oli mesin',
            action: 'ganti',
            intervalKm: 3000,
          ),
        ],
      );
      final data = MotorData(
        currentOdometer: 10000,
        lastOilOdometer: 6000,
        oilInterval: 3000,
        componentStates: [
          ComponentMaintenanceState(
            componentName: 'Oli mesin',
            lastServicedKm: 6000,
            intervalKmOverride: 3000,
          ),
        ],
      );

      await tester.pumpWidget(buildReminderPage(catalog: catalog, data: data));
      await tester.pumpAndSettle();

      // Tap judul kartu Oli mesin untuk membuka detail
      await tester.ensureVisible(find.text('Oli mesin').first);
      await tester.tap(find.text('Oli mesin').first);
      await tester.pumpAndSettle();

      expect(find.text('Panduan oli'), findsOneWidget);

      await tester.tap(find.text('Panduan oli'));
      await tester.pumpAndSettle();

      expect(find.text('TANYA PANDUAN OLI'), findsOneWidget);
      expect(find.text('Catat ganti oli'), findsOneWidget);
    });

    testWidgets('membuka panduan dari kartu Oli gardan', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const catalog = MaintenanceCatalog(
        source: 'uji',
        components: [
          MaintenanceComponent(
            name: 'Oli gardan',
            action: 'ganti',
            intervalKm: 6000,
          ),
        ],
      );
      final data = MotorData(
        currentOdometer: 10000,
        lastOilOdometer: 8000,
        oilInterval: 3000,
        componentStates: [
          ComponentMaintenanceState(
            componentName: 'Oli gardan',
            lastServicedKm: 3000,
            intervalKmOverride: 6000,
          ),
        ],
      );

      await tester.pumpWidget(buildReminderPage(catalog: catalog, data: data));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Oli gardan').first);
      await tester.tap(find.text('Oli gardan').first);
      await tester.pumpAndSettle();

      expect(find.text('Panduan oli'), findsOneWidget);

      await tester.tap(find.text('Panduan oli'));
      await tester.pumpAndSettle();

      expect(find.text('TANYA PANDUAN OLI'), findsOneWidget);
      expect(find.text('Catat ganti oli'), findsOneWidget);
    });

    testWidgets('kartu komponen lain tidak menampilkan tautan Panduan oli', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const catalog = MaintenanceCatalog(
        source: 'uji',
        components: [
          MaintenanceComponent(name: 'Busi', action: 'ganti', intervalKm: 8000),
        ],
      );
      final data = MotorData(
        currentOdometer: 10000,
        lastOilOdometer: 8000,
        oilInterval: 3000,
        componentStates: [
          ComponentMaintenanceState(
            componentName: 'Busi',
            lastServicedKm: 1000,
            intervalKmOverride: 8000,
          ),
        ],
      );

      await tester.pumpWidget(buildReminderPage(catalog: catalog, data: data));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Busi').first);
      await tester.tap(find.text('Busi').first);
      await tester.pumpAndSettle();

      expect(find.text('Panduan oli'), findsNothing);
    });
  });
}
