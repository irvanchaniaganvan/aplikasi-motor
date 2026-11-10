import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rawatin/features/maintenance/data/services/ai_consent_storage.dart';
import 'package:rawatin/features/maintenance/domain/entities/maintenance_motor_catalog.dart';
import 'package:rawatin/features/maintenance/domain/services/ai_service.dart';
import 'package:rawatin/features/maintenance/presentation/content/motor_care_content.dart';
import 'package:rawatin/features/maintenance/presentation/pages/ai_assistant_page.dart';

class _FakeConsentStorage implements AiConsentStorage {
  _FakeConsentStorage({this.hasConsentValue = true});

  final bool hasConsentValue;
  bool? lastSetConsent;

  @override
  Future<bool> hasConsent() async => hasConsentValue;

  @override
  Future<void> setConsent(bool consent) async {
    lastSetConsent = consent;
  }

  @override
  Future<String> getOrCreateInstallId() async => 'test-install-id';
}

class _CountingAiService implements AiService {
  _CountingAiService({this.response, this.exception});

  final AiOilResponse? response;
  final AiServiceException? exception;
  int callCount = 0;

  @override
  Future<AiOilResponse> askOilGuide(AiOilRequest request) async {
    callCount++;
    if (exception != null) {
      throw exception!;
    }
    return response ?? const AiOilResponse(answer: 'Jawaban dari AI uji.');
  }
}

Widget _buildPage({
  AiService? aiService,
  AiConsentStorage? consentStorage,
  MaintenanceMotor? motor,
}) {
  return MaterialApp(
    home: AiAssistantPage(
      motor: motor,
      aiService: aiService,
      consentStorage: consentStorage,
    ),
  );
}

void main() {
  // ─── 1. Tampilan awal ─────────────────────────────────────────────────────

  group('AiAssistantPage – tampilan awal', () {
    testWidgets('menampilkan header asisten AI', (tester) async {
      await tester.pumpWidget(_buildPage(aiService: _CountingAiService()));
      await tester.pumpAndSettle();

      // Nama muncul di AppBar dan di header halaman.
      expect(find.text('TANYA RAWATIN'), findsNWidgets(2));
      expect(find.text('Asisten Perawatan Motor'), findsNWidgets(2));
    });

    testWidgets('menampilkan chip pertanyaan contoh', (tester) async {
      await tester.pumpWidget(_buildPage(aiService: _CountingAiService()));
      await tester.pumpAndSettle();

      for (final question in MotorCareContent.sampleQuestions) {
        expect(find.text(question), findsOneWidget);
      }
    });

    testWidgets('menampilkan intro pertanyaan saat belum ada chat', (
      tester,
    ) async {
      await tester.pumpWidget(_buildPage(aiService: _CountingAiService()));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Tanya seputar perawatan motor, oli, rem, ban, CVT, aki, atau hal lain yang kamu butuhkan.',
        ),
        findsOneWidget,
      );
    });
  });

  // ─── 2. Alur pertanyaan ───────────────────────────────────────────────────

  group('AiAssistantPage – alur pertanyaan', () {
    testWidgets(
      'tanpa persetujuan AI tidak dipanggil dan dialog muncul',
      (tester) async {
        final service = _CountingAiService();
        final consent = _FakeConsentStorage(hasConsentValue: false);

        await tester.pumpWidget(_buildPage(aiService: service, consentStorage: consent));
        await tester.pumpAndSettle();

        await tester.tap(find.text(MotorCareContent.sampleQuestions.first));
        await tester.pumpAndSettle();

        // Dialog persetujuan muncul; AI belum dipanggil.
        expect(find.text('Setuju & Tanya'), findsOneWidget);
        expect(service.callCount, 0);

        await tester.tap(find.text('Setuju & Tanya'));
        await tester.pumpAndSettle();

        expect(service.callCount, 1);
        expect(find.text(MotorCareContent.sampleQuestions.first), findsOneWidget);
      },
    );

    testWidgets('setelah persetujuan menjawab pertanyaan', (tester) async {
      final service = _CountingAiService(
        response: const AiOilResponse(answer: 'Ini jawaban uji dari AI.', refused: false),
      );

      await tester.pumpWidget(
        _buildPage(aiService: service, consentStorage: _FakeConsentStorage()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(MotorCareContent.sampleQuestions.first));
      await tester.pumpAndSettle();

      expect(service.callCount, 1);
      expect(find.text('Ini jawaban uji dari AI.'), findsOneWidget);
      expect(find.text(MotorCareContent.sampleQuestions.first), findsOneWidget);
    });
  });

  // ─── 3. Kondisi error dan konfigurasi ─────────────────────────────────────

  group('AiAssistantPage – kondisi error dan konfigurasi', () {
    testWidgets('pesan error menampilkan tombol Coba lagi', (tester) async {
      final service = _CountingAiService(
        exception: const AiServiceException(
          code: 'rate_limited',
          message: 'Terlalu banyak pertanyaan dari perangkat ini. Silakan coba lagi nanti.',
        ),
      );

      await tester.pumpWidget(_buildPage(aiService: service, consentStorage: _FakeConsentStorage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text(MotorCareContent.sampleQuestions.first));
      await tester.pumpAndSettle();

      expect(
        find.text('Terlalu banyak pertanyaan dari perangkat ini. Silakan coba lagi nanti.'),
        findsOneWidget,
      );
      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets('AI belum dikonfigurasi menampilkan state kosong', (tester) async {
      final service = _CountingAiService(
        exception: const AiServiceException(
          code: 'ai_unconfigured',
          message: 'Layanan AI belum dikonfigurasi.',
        ),
      );

      await tester.pumpWidget(_buildPage(aiService: service, consentStorage: _FakeConsentStorage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text(MotorCareContent.sampleQuestions.first));
      await tester.pumpAndSettle();

      expect(find.text('Asisten AI belum dikonfigurasi.'), findsOneWidget);
      expect(find.byTooltip('Kirim pertanyaan'), findsNothing);
    });
  });
}
