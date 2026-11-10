import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../profile/domain/entities/driver_motor_profile.dart';
import '../../data/services/oil_specification_service_factory.dart';
import '../../domain/entities/maintenance_motor_catalog.dart';
import '../../domain/entities/oil_specification.dart';
import '../../domain/services/oil_specification_service.dart';
import '../widgets/oil_guide_widgets.dart';

/// Halaman panduan edukasi oli motor dengan spesifikasi terverifikasi.
///
/// Halaman ini tidak menyertakan asisten AI; AI kini ada di
/// [AiAssistantPage] dan dibuka lewat kartu AI di Beranda.
class OilGuidePage extends StatefulWidget {
  const OilGuidePage({
    super.key,
    this.motor,
    this.profile,
    this.onRecordOilService,
  });

  final MaintenanceMotor? motor;
  final DriverMotorProfile? profile;
  final VoidCallback? onRecordOilService;

  @override
  State<OilGuidePage> createState() => _OilGuidePageState();
}

class _OilGuidePageState extends State<OilGuidePage> {
  late final OilSpecificationService _oilSpecificationService;

  OilSpecification? _oilSpecification;
  OilSpecificationSourceType? _oilSpecificationSource;
  bool _isLoadingOilSpecification = false;

  @override
  void initState() {
    super.initState();
    _oilSpecificationService = OilSpecificationServiceFactory.createDefault();
    _oilSpecification = widget.motor?.oilSpec;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOilSpecification();
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
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(colors),
    );
  }

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
