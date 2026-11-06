import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../profile/domain/entities/driver_motor_profile.dart';
import '../../data/services/ai_consent_storage.dart';
import '../../data/services/ai_service_factory.dart';
import '../../domain/entities/maintenance_motor_catalog.dart';
import '../../domain/services/ai_service.dart';
import '../content/oil_guide_content.dart';

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

  final List<AiChatMessage> _chatHistory = [];
  bool _isLoading = false;
  bool _aiUnavailable = false;
  String? _errorMessage;
  String? _lastFailedQuestion;

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
                  _buildDisclaimerBanner(colors),
                  const SizedBox(height: AppSpacing.lg),
                  _buildMotorSpecSection(colors),
                  const SizedBox(height: AppSpacing.xl),
                  _buildAccordionGuide(colors),
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

  Widget _buildDisclaimerBanner(RawatinColors colors) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: colors.accentSoft.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: colors.accent.withValues(alpha: 0.35)),
    ),
    child: Row(
      children: [
        Icon(AppIcons.info, color: colors.accent, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            OilGuideContent.banner,
            style: TextStyle(
              color: colors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildMotorSpecSection(RawatinColors colors) {
    final spec = widget.motor?.oilSpec;
    final isVerified = spec != null && spec.verified;
    final motorName =
        widget.motor?.name ??
        (widget.profile != null
            ? '${widget.profile!.brand} ${widget.profile!.model}'
            : 'Motor Kamu');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.oil, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SPESIFIKASI OLI MOTOR INI',
                  style: AppType.eyebrow.copyWith(color: colors.muted),
                ),
              ),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.safeSoft,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppIcons.verified, size: 13, color: colors.safe),
                      const SizedBox(width: 4),
                      Text(
                        'Terverifikasi',
                        style: TextStyle(
                          color: colors.safe,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            motorName,
            style: AppType.cardTitle.copyWith(color: colors.ink, fontSize: 17),
          ),
          const SizedBox(height: 10),
          if (isVerified) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Row(
                children: [
                  _buildSpecMetric(colors, label: 'GRADE SAE', value: spec.sae),
                  Container(
                    height: 32,
                    width: 1,
                    color: colors.line,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  _buildSpecMetric(
                    colors,
                    label: 'STANDAR JASO',
                    value: spec.jaso,
                  ),
                  Container(
                    height: 32,
                    width: 1,
                    color: colors.line,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  _buildSpecMetric(
                    colors,
                    label: 'VOLUME OLI',
                    value: spec.volume,
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.dueSoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: colors.due.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.warning, color: colors.due, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      OilGuideContent.unverifiedWarning,
                      style: TextStyle(
                        color: colors.inkSoft,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecMetric(
    RawatinColors colors, {
    required String label,
    required String value,
  }) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppType.eyebrow.copyWith(
            color: colors.muted,
            fontSize: 9.5,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: colors.ink,
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
          ),
        ),
      ],
    ),
  );

  Widget _buildAccordionGuide(RawatinColors colors) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'BAB PANDUAN LENGKAP',
        style: AppType.eyebrow.copyWith(color: colors.muted),
      ),
      const SizedBox(height: 8),
      for (var i = 0; i < OilGuideContent.sections.length; i++) ...[
        _buildAccordionItem(
          colors,
          OilGuideContent.sections[i],
          initiallyExpanded: i == 0,
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    ],
  );

  Widget _buildAccordionItem(
    RawatinColors colors,
    OilGuideSection section, {
    required bool initiallyExpanded,
  }) => Material(
    color: colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      side: BorderSide(color: colors.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        iconColor: colors.primary,
        collapsedIconColor: colors.muted,
        title: Text(
          section.title,
          style: TextStyle(
            color: colors.ink,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              section.content,
              style: TextStyle(
                color: colors.inkSoft,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ),
          if (section.points.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final point in section.points)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 7, right: 8),
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          color: colors.inkSoft,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    ),
  );

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
