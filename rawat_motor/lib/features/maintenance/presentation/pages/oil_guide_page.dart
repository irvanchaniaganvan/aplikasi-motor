import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../profile/domain/entities/driver_motor_profile.dart';
import '../../data/services/ai_consent_storage.dart';
import '../../data/services/ai_service_factory.dart';
import '../../data/services/oil_specification_service_factory.dart';
import '../../domain/entities/maintenance_motor_catalog.dart';
import '../../domain/entities/oil_specification.dart';
import '../../domain/services/ai_service.dart';
import '../../domain/services/oil_specification_service.dart';
import '../content/oil_guide_content.dart';
import '../widgets/oil_guide_widgets.dart';

/// Halaman panduan edukasi oli motor dengan spesifikasi terverifikasi
/// dan asisten AI "Tanya Panduan Oli".
class OilGuidePage extends StatefulWidget {
  const OilGuidePage({
    super.key,
    this.motor,
    this.profile,
    this.onRecordOilService,
    this.aiService,
    this.consentStorage,
  });

  final MaintenanceMotor? motor;
  final DriverMotorProfile? profile;
  final VoidCallback? onRecordOilService;
  final AiService? aiService;
  final AiConsentStorage? consentStorage;

  @override
  State<OilGuidePage> createState() => _OilGuidePageState();
}

class _OilGuidePageState extends State<OilGuidePage> {
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();

  late final AiService _aiService;
  late final AiConsentStorage _consentStorage;
  late final OilSpecificationService _oilSpecificationService;

  final List<AiChatMessage> _chatHistory = [];
  bool _isLoading = false;
  bool _aiUnavailable = false;
  String? _errorMessage;
  String? _lastFailedQuestion;
  OilSpecification? _oilSpecification;
  OilSpecificationSourceType? _oilSpecificationSource;
  bool _isLoadingOilSpecification = false;

  static const _sampleQuestions = [
    'Bedanya 10W-30 dan 10W-40?',
    'Kalau tiap hari macet, oli lebih cepat diganti?',
    'Oli apa yang cocok untuk motorku?',
  ];

  @override
  void initState() {
    super.initState();
    _aiService = widget.aiService ?? AiServiceFactory.createDefault();
    _consentStorage = widget.consentStorage ?? const LocalAiConsentStorage();
    _oilSpecificationService = OilSpecificationServiceFactory.createDefault();
    _oilSpecification = widget.motor?.oilSpec;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOilSpecification();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleAskQuestion([String? presetQuestion]) async {
    final question = (presetQuestion ?? _inputController.text).trim();
    if (question.isEmpty) return;

    if (question.length > 500) {
      _showSnackbar('Pertanyaan melebihi batas 500 karakter.');
      return;
    }

    // 1. Periksa persetujuan pengguna sebelum permintaan jaringan
    final hasConsent = await _consentStorage.hasConsent();
    if (!hasConsent) {
      if (!mounted) return;
      final agreed = await _showConsentDialog();
      if (!agreed) return;
      await _consentStorage.setConsent(true);
    }

    if (!mounted) return;

    // Bersihkan input jika pengiriman dari textfield
    if (presetQuestion == null) {
      _inputController.clear();
    }

    // Simpan riwayat sebelum pertanyaan aktif agar backend tidak menerima
    // pertanyaan yang sama dua kali (di history dan di field question).
    final historyBefore = _chatHistory.length > 6
        ? _chatHistory.sublist(_chatHistory.length - 6)
        : List.of(_chatHistory);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _lastFailedQuestion = null;
      _chatHistory.add(AiChatMessage(role: AiChatRole.user, content: question));
    });

    try {
      final installId = await _consentStorage.getOrCreateInstallId();
      final motorSpec = widget.motor?.oilSpec;
      final isVerified = motorSpec != null && motorSpec.verified;

      final request = AiOilRequest(
        installId: installId,
        question: question,
        motor: AiMotorContext(
          id:
              widget.motor?.id ??
              widget.profile?.maintenanceMotorId ??
              'motor-pengguna',
          name:
              widget.motor?.name ??
              (widget.profile != null
                  ? '${widget.profile!.brand} ${widget.profile!.model}'
                  : 'Motor Saya'),
          oilSpec: isVerified
              ? AiOilSpecContext.fromOilSpecification(motorSpec)
              : null,
        ),
        history: historyBefore,
        reference: OilGuideContent.fullReferenceText,
      );

      final response = await _aiService.askOilGuide(request);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _chatHistory.add(
          AiChatMessage(role: AiChatRole.assistant, content: response.answer),
        );
      });
    } on AiServiceException catch (e) {
      if (!mounted) return;
      if (e.code == 'ai_unconfigured') {
        setState(() {
          _isLoading = false;
          _aiUnavailable = true;
          _chatHistory.removeLast();
        });
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
        _lastFailedQuestion = question;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Tidak dapat menghubungi layanan AI. Silakan coba lagi.';
        _lastFailedQuestion = question;
      });
    }
  }

  Future<bool> _showConsentDialog() async {
    final colors = RawatinColors.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surface,
        title: Row(
          children: [
            Icon(AppIcons.sparkle, color: colors.accent, size: 24),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Tanya Panduan Oli AI', style: AppType.cardTitle),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pertanyaanmu akan dikirim ke layanan AI untuk dijawab berdasarkan materi panduan resmi Rawatin.',
              style: TextStyle(
                color: colors.inkSoft,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(color: colors.line),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.lock, size: 16, color: colors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Privasi terjaga: nama, nomor plat, dan riwayat catatan kilometer tidak pernah dikirimkan.',
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Setuju & Tanya'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _resetChat() {
    setState(() {
      _chatHistory.clear();
      _errorMessage = null;
      _lastFailedQuestion = null;
      _isLoading = false;
    });
  }

  void _showSnackbar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _loadOilSpecification({bool refresh = false}) async {
    if (_isLoadingOilSpecification || !mounted) return;
    final motor = widget.motor;
    final profile = widget.profile;
    final motorId =
        motor?.id ??
        profile?.maintenanceMotorId ??
        _slug('${profile?.brand ?? ''}-${profile?.model ?? ''}');
    if (motorId.isEmpty) return;
    final motorName =
        motor?.name ??
        (profile == null
            ? 'Motor pengguna'
            : '${profile.brand} ${profile.model}');
    setState(() {
      _isLoadingOilSpecification = true;
      _errorMessage = null;
    });
    try {
      final result = await _oilSpecificationService.load(
        motorId: motorId,
        motorName: motorName,
        year: profile?.year ?? DateTime.now().year,
        localSpecification: motor?.oilSpec,
        refresh: refresh,
      );
      if (!mounted) return;
      setState(() {
        _oilSpecification = result.specification;
        _oilSpecificationSource = result.sourceType;
        _isLoadingOilSpecification = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingOilSpecification = false);
      _showSnackbar('Spesifikasi online belum dapat dimuat.');
    }
  }

  String _slug(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PANDUAN OLI',
              style: AppType.eyebrow.copyWith(color: colors.primary),
            ),
            const Text('Perawatan & Spesifikasi', style: AppType.cardTitle),
          ],
        ),
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(AppIcons.arrowBack, color: colors.ink),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Kembali',
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: colors.line, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.xxxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const OilGuideDisclaimer(),
                  const SizedBox(height: AppSpacing.lg),
                  OilGuideMotorSpec(
                    motor: widget.motor,
                    profile: widget.profile,
                    specification: _oilSpecification,
                    sourceType: _oilSpecificationSource,
                    isLoading: _isLoadingOilSpecification,
                    onRefresh: () => _loadOilSpecification(refresh: true),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const OilGuideAccordion(),
                  if (AiServiceFactory.featureEnabled) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    _buildAiAssistantSection(colors),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(colors),
    );
  }

  Widget _buildAiAssistantSection(RawatinColors colors) {
    if (_aiUnavailable) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: colors.line),
        ),
        child: Row(
          children: [
            Icon(AppIcons.sparkle, color: colors.muted, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TANYA PANDUAN OLI',
                    style: AppType.eyebrow.copyWith(color: colors.muted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Segera hadir',
                    style: AppType.cardTitle.copyWith(color: colors.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Asisten AI belum dikonfigurasi. Panduan di atas tetap bisa kamu baca kapan saja.',
                    style: TextStyle(color: colors.muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(AppIcons.sparkle, color: colors.accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TANYA PANDUAN OLI',
                      style: AppType.eyebrow.copyWith(color: colors.primary),
                    ),
                    const Text('Asisten Panduan', style: AppType.cardTitle),
                  ],
                ),
              ),
              if (_chatHistory.isNotEmpty)
                TextButton.icon(
                  onPressed: _resetChat,
                  icon: Icon(AppIcons.restart, size: 14, color: colors.muted),
                  label: Text(
                    'Mulai ulang',
                    style: TextStyle(color: colors.muted, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_chatHistory.isEmpty) ...[
            Text(
              'Pilih pertanyaan umum atau ketik pertanyaanmu sendiri seputar materi panduan:',
              style: TextStyle(color: colors.muted, fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sampleQuestions
                  .map(
                    (q) => ActionChip(
                      label: Text(q),
                      labelStyle: TextStyle(
                        color: colors.inkSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      backgroundColor: colors.surfaceSoft,
                      side: BorderSide(color: colors.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => _handleAskQuestion(q),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
          ] else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final message = _chatHistory[index];
                return _buildChatMessageBubble(colors, message);
              },
            ),
            const SizedBox(height: 10),
          ],
          if (_isLoading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Mencari jawaban di panduan...',
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: colors.dueSoft,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(color: colors.due.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.warning, color: colors.due, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: colors.due, fontSize: 12),
                    ),
                  ),
                  if (_lastFailedQuestion != null)
                    TextButton(
                      onPressed: () => _handleAskQuestion(_lastFailedQuestion),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 30),
                      ),
                      child: Text(
                        'Coba lagi',
                        style: TextStyle(
                          color: colors.due,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          _buildInputBar(colors),
        ],
      ),
    );
  }

  Widget _buildChatMessageBubble(RawatinColors colors, AiChatMessage message) {
    final isUser = message.role == AiChatRole.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? colors.primary : colors.surfaceSoft,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppRadii.md),
                topRight: const Radius.circular(AppRadii.md),
                bottomLeft: Radius.circular(isUser ? AppRadii.md : 2),
                bottomRight: Radius.circular(isUser ? 2 : AppRadii.md),
              ),
              border: isUser ? null : Border.all(color: colors.line),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: isUser ? colors.white : colors.ink,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ),
          if (!isUser) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.sparkle, size: 10, color: colors.muted),
                const SizedBox(width: 4),
                Text(
                  OilGuideContent.aiDisclaimer,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar(RawatinColors colors) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _inputController,
          builder: (context, value, child) {
            final length = value.text.length;
            return TextField(
              controller: _inputController,
              focusNode: _focusNode,
              maxLength: 500,
              maxLines: null,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleAskQuestion(),
              decoration: InputDecoration(
                hintText: 'Tanyakan sesuatu tentang oli...',
                counterText: '$length/500',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                fillColor: colors.surfaceSoft,
                filled: true,
              ),
            );
          },
        ),
      ),
      const SizedBox(width: 8),
      IconButton.filled(
        onPressed: _isLoading ? null : () => _handleAskQuestion(),
        icon: const Icon(AppIcons.send, size: 18),
        style: IconButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.white,
          minimumSize: const Size(48, 48),
        ),
        tooltip: 'Kirim pertanyaan',
      ),
    ],
  );

  Widget _buildBottomActionBar(RawatinColors colors) => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
    decoration: BoxDecoration(
      color: colors.surface,
      border: Border(top: BorderSide(color: colors.line)),
    ),
    child: SafeArea(
      child: FilledButton.icon(
        onPressed: () {
          Navigator.of(context).pop();
          widget.onRecordOilService?.call();
        },
        icon: const Icon(AppIcons.record),
        label: const Text('Catat ganti oli'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
    ),
  );
}
