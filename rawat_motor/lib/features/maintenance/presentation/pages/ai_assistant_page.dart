import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../profile/domain/entities/driver_motor_profile.dart';
import '../../../profile/domain/entities/motor_model_catalog.dart';
import '../../data/services/ai_consent_storage.dart';
import '../../data/services/ai_service_factory.dart';
import '../../data/services/motor_oil_spec_resolver.dart';
import '../../domain/entities/maintenance_motor_catalog.dart';
import '../../domain/entities/oil_specification.dart';
import '../../domain/services/ai_service.dart';
import '../content/motor_care_content.dart';
import '../widgets/ai_orb.dart';

/// Halaman asisten perawatan motor dengan chat AI.
class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({
    super.key,
    this.motor,
    this.profile,
    this.aiService,
    this.consentStorage,
    this.modelCatalog,
    this.initialOilSpecification,
  });

  final MaintenanceMotor? motor;
  final DriverMotorProfile? profile;
  final AiService? aiService;
  final AiConsentStorage? consentStorage;
  final MotorModelCatalog? modelCatalog;
  final OilSpecification? initialOilSpecification;

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();

  late final AiService _aiService;
  late final AiConsentStorage _consentStorage;
  late final MotorOilSpecResolver _oilSpecResolver;

  final List<AiChatMessage> _chatHistory = [];
  bool _isLoading = false;
  bool _aiUnavailable = false;
  String? _errorMessage;
  String? _lastFailedQuestion;

  OilSpecification? _oilSpecification;

  @override
  void initState() {
    super.initState();
    _aiService = widget.aiService ?? AiServiceFactory.createDefault();
    _consentStorage = widget.consentStorage ?? const LocalAiConsentStorage();
    _oilSpecResolver = MotorOilSpecResolver(catalog: widget.modelCatalog);

    final motorSpec = widget.motor?.oilSpec;
    _oilSpecification =
        widget.initialOilSpecification ??
        (motorSpec?.verified == true ? motorSpec : null);

    if (_oilSpecification == null && widget.profile != null) {
      _resolveOilSpecification();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _resolveOilSpecification() async {
    final profile = widget.profile;
    if (profile == null) return;
    final resolved = await _oilSpecResolver.resolve(
      brand: profile.brand,
      model: profile.model,
    );
    if (!mounted) return;
    final spec = resolved;
    if (spec != null) {
      setState(() => _oilSpecification = spec);
    }
  }

  Future<void> _handleAskQuestion([String? presetQuestion]) async {
    final question = (presetQuestion ?? _inputController.text).trim();
    if (question.isEmpty) return;

    if (question.length > 500) {
      _showSnackbar('Pertanyaan melebihi batas 500 karakter.');
      return;
    }

    final hasConsent = await _consentStorage.hasConsent();
    if (!hasConsent) {
      if (!mounted) return;
      final agreed = await _showConsentDialog();
      if (!agreed) return;
      await _consentStorage.setConsent(true);
    }

    if (!mounted) return;

    if (presetQuestion == null) {
      _inputController.clear();
    }

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
      final motorSpec = _oilSpecification;
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
          oilSpec: isVerified ? AiOilSpecContext.fromOilSpecification(motorSpec) : null,
        ),
        history: historyBefore,
        reference: MotorCareContent.aiReferenceText,
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
        _errorMessage = 'Tidak dapat menghubungi layanan AI. Silakan coba lagi.';
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
            const Icon(AppIcons.sparkle, color: AppPalette.accent, size: 24),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Tanya Rawatin AI', style: AppType.cardTitle),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pertanyaan dan konteks motor anonim akan dikirim melalui server Rawatin ke layanan AI pihak ketiga untuk dijawab berdasarkan materi perawatan motor resmi Rawatin.',
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
                  const Icon(AppIcons.lock, size: 16, color: AppPalette.muted),
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
              'TANYA RAWATIN',
              style: AppType.eyebrow.copyWith(color: colors.primary),
            ),
            const Text('Asisten Perawatan Motor', style: AppType.cardTitle),
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
        child: Column(
          children: [
            Expanded(
              child: _aiUnavailable
                  ? _buildUnavailable(colors)
                  : SingleChildScrollView(
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
                              _buildAssistantHeader(colors),
                              const SizedBox(height: AppSpacing.lg),
                              _chatContent(colors),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            if (!_aiUnavailable) _buildInputBar(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailable(RawatinColors colors) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: colors.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(AppIcons.sparkle, color: AppPalette.accent, size: 28),
            const SizedBox(height: 10),
            const Text(
              'Asisten AI belum dikonfigurasi.',
              style: AppType.cardTitle,
            ),
            const SizedBox(height: 6),
            Text(
              'Panduan perawatan di atas tetap bisa kamu baca kapan saja.',
              style: TextStyle(color: colors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatContent(RawatinColors colors) {
    if (_chatHistory.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Tanya seputar perawatan motor, oli, rem, ban, CVT, aki, atau hal lain yang kamu butuhkan.',
            style: TextStyle(color: colors.muted, fontSize: 12.5, height: 1.45),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MotorCareContent.sampleQuestions
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
                    onPressed: _isLoading ? null : () => _handleAskQuestion(q),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 8),
          itemCount: _chatHistory.length,
          itemBuilder: (context, index) {
            final message = _chatHistory[index];
            return _buildChatMessageBubble(colors, message);
          },
        ),
        if (_isLoading) ...[
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppPalette.primary,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Mencari jawaban...',
                  style: TextStyle(
                    color: AppPalette.muted,
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
              color: AppPalette.dueSoft,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: AppPalette.due.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(AppIcons.warning, color: AppPalette.due, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppPalette.due, fontSize: 12),
                  ),
                ),
                if (_lastFailedQuestion != null)
                  TextButton(
                    onPressed: () => _handleAskQuestion(_lastFailedQuestion),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 30),
                    ),
                    child: const Text(
                      'Coba lagi',
                      style: TextStyle(
                        color: AppPalette.due,
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
      ],
    );
  }

  Widget _buildAssistantHeader(RawatinColors colors) {
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
      child: Row(
        children: [
          const AiOrb(size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TANYA RAWATIN',
                  style: AppType.eyebrow.copyWith(color: colors.primary),
                ),
                const Text('Asisten Perawatan Motor', style: AppType.cardTitle),
                const SizedBox(height: 4),
                Text(
                  'Tanya seputar oli, rem, ban, CVT, aki, busi, radiator, rantai, dan perawatan motor umum.',
                  style: TextStyle(
                    color: colors.inkSoft,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                if (_oilSpecification?.verified == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Spesifikasi terverifikasi: SAE ${_oilSpecification!.sae}, JASO ${_oilSpecification!.jaso}, kapasitas ${_oilSpecification!.volume}.',
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
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
                const Icon(AppIcons.sparkle, size: 10, color: AppPalette.muted),
                const SizedBox(width: 4),
                Text(
                  MotorCareContent.disclaimer,
                  style: TextStyle(
                    color: AppPalette.muted,
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

  Widget _buildInputBar(RawatinColors colors) => Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
    decoration: BoxDecoration(
      color: colors.surface,
      border: Border(top: BorderSide(color: colors.line)),
    ),
    child: Row(
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
                  hintText: 'Tanyakan seputar perawatan motor...',
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
            backgroundColor: AppPalette.primary,
            foregroundColor: AppPalette.white,
            minimumSize: const Size(48, 48),
          ),
          tooltip: 'Kirim pertanyaan',
        ),
      ],
    ),
  );
}
