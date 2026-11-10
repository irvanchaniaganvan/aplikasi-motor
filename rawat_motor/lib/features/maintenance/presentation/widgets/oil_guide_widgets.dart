import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../profile/domain/entities/driver_motor_profile.dart';
import '../../domain/entities/maintenance_motor_catalog.dart';
import '../../domain/entities/oil_specification.dart';
import '../../domain/services/oil_specification_service.dart';
import '../content/oil_guide_content.dart';

class OilGuideDisclaimer extends StatelessWidget {
  const OilGuideDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Container(
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
  }
}

class OilGuideMotorSpec extends StatelessWidget {
  const OilGuideMotorSpec({
    this.motor,
    this.profile,
    this.specification,
    this.sourceType,
    this.isLoading = false,
    this.onRefresh,
    super.key,
  });

  final MaintenanceMotor? motor;
  final DriverMotorProfile? profile;
  final OilSpecification? specification;
  final OilSpecificationSourceType? sourceType;
  final bool isLoading;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    final spec = specification ?? motor?.oilSpec;
    final isVerified = spec != null && spec.verified;
    final motorName =
        motor?.name ??
        (profile != null
            ? '${profile!.brand} ${profile!.model}'
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
              if (onRefresh != null)
                IconButton(
                  onPressed: isLoading ? null : onRefresh,
                  icon: isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        )
                      : Icon(Icons.refresh_rounded, color: colors.primary),
                  tooltip: 'Perbarui spesifikasi',
                  visualDensity: VisualDensity.compact,
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
            if (sourceType != null) ...[
              const SizedBox(height: 8),
              _buildSourceStatus(colors, spec),
            ],
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

  Widget _buildSourceStatus(RawatinColors colors, OilSpecification spec) {
    final sourceLabel = switch (sourceType) {
      OilSpecificationSourceType.online => 'Online',
      OilSpecificationSourceType.cache => 'Cache lokal',
      OilSpecificationSourceType.local => 'Katalog aplikasi',
      OilSpecificationSourceType.unavailable || null => 'Belum tersedia',
    };
    final updated = spec.updatedAt;
    final updatedText = updated == null
        ? ''
        : ' · diperbarui ${updated.day}/${updated.month}/${updated.year}';
    return Text(
      'Sumber: $sourceLabel${spec.source == null ? '' : ' · ${spec.source}'}$updatedText',
      style: TextStyle(color: colors.muted, fontSize: 11.5, height: 1.3),
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
}

class OilGuideAccordion extends StatelessWidget {
  const OilGuideAccordion({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BAB PANDUAN LENGKAP',
          style: AppType.eyebrow.copyWith(color: colors.muted),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < OilGuideContent.sections.length; i++) ...[
          _buildAccordionItem(
            context,
            colors,
            OilGuideContent.sections[i],
            initiallyExpanded: i == 0,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _buildAccordionItem(
    BuildContext context,
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
}
