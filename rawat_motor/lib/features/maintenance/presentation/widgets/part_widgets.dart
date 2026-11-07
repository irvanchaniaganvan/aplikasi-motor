import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/maintenance_component.dart';
import 'common_widgets.dart';

class PartCard extends StatelessWidget {
  const PartCard({
    required this.name,
    required this.icon,
    required this.statusLabel,
    required this.statusColor,
    required this.statusSoft,
    required this.statusIcon,
    required this.description,
    required this.meta,
    required this.onOpen,
    required this.onRecord,
    this.progress,
    this.prominent = false,
    this.inspection = false,
    super.key,
  });

  final String name;
  final IconData icon;
  final String statusLabel;
  final Color statusColor;
  final Color statusSoft;
  final IconData statusIcon;
  final String description;
  final String meta;
  final VoidCallback onOpen;
  final VoidCallback onRecord;
  final double? progress;
  final bool prominent;
  final bool inspection;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: prominent
                  ? statusColor.withValues(alpha: 0.5)
                  : colors.line,
              width: prominent ? 1.4 : 1,
            ),
            boxShadow: prominent
                ? [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  RawatinIconTile(icon: icon, color: statusColor, soft: statusSoft),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.cardTitle.copyWith(
                        color: colors.ink,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  if (inspection) ...[
                    const SizedBox(width: AppSpacing.sm),
                    RawatinInfoChip(icon: AppIcons.search, label: 'Pemeriksaan'),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Flexible(
                    child: RawatinStatusBadge(
                      label: statusLabel,
                      icon: statusIcon,
                      color: statusColor,
                      background: statusSoft,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.muted, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: prominent ? statusColor : colors.inkSoft,
                  fontSize: 12.5,
                  fontWeight: prominent ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (progress != null) ...[
                const SizedBox(height: AppSpacing.sm),
                SegmentedGauge(
                  value: progress!,
                  color: statusColor,
                  height: 8,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Interval terpakai',
                      style: TextStyle(color: colors.muted, fontSize: 10),
                    ),
                    const Spacer(),
                    Text(
                      '${(progress! * 100).round()}%',
                      style: AppType.eyebrow.copyWith(
                        color: statusColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  TextButton(
                    onPressed: onOpen,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: AppType.button.copyWith(fontSize: 12),
                    ),
                    child: const Text('Detail · Atur interval'),
                  ),
                  PartRecordButton(prominent: prominent, onPressed: onRecord),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PartRecordButton extends StatelessWidget {
  const PartRecordButton({
    required this.onPressed,
    this.prominent = false,
    super.key,
  });

  final VoidCallback onPressed;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(AppIcons.record, size: 15),
      label: const Text('Catat ganti'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        backgroundColor: prominent ? colors.primary : colors.primarySoft,
        foregroundColor: prominent ? colors.white : colors.primaryDark,
        textStyle: AppType.button.copyWith(fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class CollapsiblePartGroup extends StatelessWidget {
  const CollapsiblePartGroup({
    required this.storageKey,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.soft,
    required this.statusLabel,
    required this.statusColor,
    required this.statusSoft,
    required this.statusIcon,
    required this.parts,
    required this.iconFor,
    required this.onOpen,
    required this.onRecord,
    super.key,
  });

  final String storageKey;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color soft;
  final String statusLabel;
  final Color statusColor;
  final Color statusSoft;
  final IconData statusIcon;
  final List<MaintenanceComponent> parts;
  final IconData Function(MaintenanceComponent) iconFor;
  final ValueChanged<MaintenanceComponent> onOpen;
  final ValueChanged<MaintenanceComponent> onRecord;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return RawatinCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey(storageKey),
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 2,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          leading: RawatinIconTile(icon: icon, color: color, soft: soft),
          title: Text(
            title,
            style: AppType.cardTitle.copyWith(color: colors.ink, fontSize: 16),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: colors.muted, fontSize: 11.5),
          ),
          iconColor: colors.primary,
          collapsedIconColor: colors.muted,
          children: [
            Divider(color: colors.line),
            for (var index = 0; index < parts.length; index++) ...[
              CompactPartRow(
                part: parts[index],
                icon: iconFor(parts[index]),
                statusLabel: statusLabel,
                statusColor: statusColor,
                statusSoft: statusSoft,
                statusIcon: statusIcon,
                onOpen: () => onOpen(parts[index]),
                onRecord: () => onRecord(parts[index]),
              ),
              if (index != parts.length - 1) Divider(color: colors.line),
            ],
          ],
        ),
      ),
    );
  }
}

class CompactPartRow extends StatelessWidget {
  const CompactPartRow({
    required this.part,
    required this.icon,
    required this.statusLabel,
    required this.statusColor,
    required this.statusSoft,
    required this.statusIcon,
    required this.onOpen,
    required this.onRecord,
    super.key,
  });

  final MaintenanceComponent part;
  final IconData icon;
  final String statusLabel;
  final Color statusColor;
  final Color statusSoft;
  final IconData statusIcon;
  final VoidCallback onOpen;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(icon, color: colors.inkSoft, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  part.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              RawatinStatusBadge(
                label: statusLabel,
                icon: statusIcon,
                color: statusColor,
                background: statusSoft,
              ),
              IconButton(
                tooltip: 'Catat ganti',
                onPressed: onRecord,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                icon: Icon(AppIcons.record, size: 19, color: colors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SegmentedGauge extends StatelessWidget {
  const SegmentedGauge({
    required this.value,
    required this.color,
    this.height = 8,
    this.segments = 14,
    super.key,
  });

  final double value;
  final Color color;
  final double height;
  final int segments;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0).toDouble()),
      duration: reduceMotion ? Duration.zero : AppMotion.normal,
      curve: Curves.easeOutCubic,
      builder: (context, animated, child) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: SegmentedGaugePainter(
            value: animated,
            color: color,
            track: colors.line,
            segments: segments,
          ),
        ),
      ),
    );
  }
}

class SegmentedGaugePainter extends CustomPainter {
  const SegmentedGaugePainter({
    required this.value,
    required this.color,
    required this.track,
    required this.segments,
  });

  final double value;
  final Color color;
  final Color track;
  final int segments;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final gap = math.min(3.0, size.width / (segments * 4));
    final segmentWidth = (size.width - gap * (segments - 1)) / segments;
    if (segmentWidth <= 0) return;
    final filled = (value.clamp(0.0, 1.0) * segments).round();
    final paint = Paint()..isAntiAlias = true;
    for (var index = 0; index < segments; index++) {
      paint.color = index < filled ? color : track;
      final rect = Rect.fromLTWH(
        index * (segmentWidth + gap),
        0,
        segmentWidth,
        size.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SegmentedGaugePainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.color != color ||
      oldDelegate.track != track ||
      oldDelegate.segments != segments;
}

class SlimProgressIndicator extends StatelessWidget {
  const SlimProgressIndicator({
    required this.value,
    required this.color,
    required this.label,
    super.key,
  });

  final double value;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SegmentedGauge(value: value, color: color, height: 8, segments: 16),
      const SizedBox(height: 5),
      Align(
        alignment: Alignment.centerRight,
        child: Text(
          label,
          style: AppType.eyebrow.copyWith(color: color, fontSize: 10),
        ),
      ),
    ],
  );
}
