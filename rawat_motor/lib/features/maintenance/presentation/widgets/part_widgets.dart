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
    required this.onEditInterval,
    required this.onRecord,
    this.progress,
    this.compact = false,
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
  final VoidCallback onEditInterval;
  final VoidCallback onRecord;
  final double? progress;
  final bool compact;
  final bool prominent;
  final bool inspection;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    final cardTint = Color.lerp(colors.surface, statusSoft, 0.38)!;
    return Material(
      color: Colors.transparent,
      child: ClipPath(
        clipper: _PartCardClipper(cut: compact ? 11 : 14),
        child: CustomPaint(
          foregroundPainter: _PartCardBorderPainter(
            color: statusColor.withValues(alpha: prominent ? 0.9 : 0.62),
            cut: compact ? 11 : 14,
            strokeWidth: prominent ? 1.6 : 1.2,
          ),
          child: Material(
            color: cardTint,
            child: InkWell(
              onTap: onOpen,
              child: Container(
                padding: EdgeInsets.all(compact ? 12 : AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        RawatinIconTile(
                          icon: icon,
                          color: statusColor,
                          soft: statusSoft,
                          size: compact ? 42 : 46,
                          borderColor: statusColor.withValues(alpha: 0.28),
                        ),
                        SizedBox(
                          width: compact ? AppSpacing.sm : AppSpacing.md,
                        ),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.cardTitle.copyWith(
                              color: colors.ink,
                              fontSize: compact ? 16 : 17,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        IconButton(
                          tooltip: 'Atur interval',
                          onPressed: onEditInterval,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(
                            minWidth: 38,
                            minHeight: 38,
                          ),
                          style: IconButton.styleFrom(
                            foregroundColor: statusColor,
                            backgroundColor: colors.surface.withValues(
                              alpha: 0.75,
                            ),
                            side: BorderSide(
                              color: statusColor.withValues(alpha: 0.35),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                          ),
                          icon: Icon(
                            inspection
                                ? Icons.edit_outlined
                                : Icons.tune_rounded,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 9 : AppSpacing.sm),
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
                            style: TextStyle(
                              color: colors.muted,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        if (inspection && !compact) ...[
                          const SizedBox(width: AppSpacing.sm),
                          RawatinInfoChip(
                            icon: AppIcons.search,
                            label: 'Pemeriksaan',
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: compact ? 7 : 9),
                    Text(
                      description,
                      maxLines: compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: prominent ? statusColor : colors.inkSoft,
                        fontSize: compact ? 13 : 12.5,
                        fontWeight: prominent
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    if (progress != null) ...[
                      SizedBox(height: compact ? 9 : AppSpacing.sm),
                      SegmentedGauge(
                        value: progress!,
                        color: statusColor,
                        height: compact ? 6 : 8,
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
                    SizedBox(height: compact ? 5 : 8),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        TextButton.icon(
                          onPressed: onOpen,
                          icon: const Icon(Icons.history_rounded, size: 15),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                            ),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: AppType.button.copyWith(fontSize: 12),
                          ),
                          label: const Text('Detail · Riwayat'),
                        ),
                        PartRecordButton(
                          prominent: prominent,
                          inspection: inspection,
                          onPressed: onRecord,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PartCardClipper extends CustomClipper<Path> {
  const _PartCardClipper({required this.cut});
  final double cut;

  @override
  Path getClip(Size size) => _partCardPath(size, cut);

  @override
  bool shouldReclip(_PartCardClipper oldClipper) => oldClipper.cut != cut;
}

class _PartCardBorderPainter extends CustomPainter {
  const _PartCardBorderPainter({
    required this.color,
    required this.cut,
    required this.strokeWidth,
  });

  final Color color;
  final double cut;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _partCardPath(size, cut),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(_PartCardBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.cut != cut ||
      oldDelegate.strokeWidth != strokeWidth;
}

Path _partCardPath(Size size, double cut) {
  final small = cut * .38;
  return Path()
    ..moveTo(cut, 0)
    ..lineTo(size.width - small, 0)
    ..lineTo(size.width, small)
    ..lineTo(size.width, size.height - cut)
    ..lineTo(size.width - cut, size.height)
    ..lineTo(small, size.height)
    ..lineTo(0, size.height - small)
    ..lineTo(0, cut)
    ..close();
}

class PartRecordButton extends StatelessWidget {
  const PartRecordButton({
    required this.onPressed,
    this.prominent = false,
    this.inspection = false,
    super.key,
  });

  final VoidCallback onPressed;
  final bool prominent;
  final bool inspection;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(AppIcons.record, size: 15),
      label: Text(inspection ? 'Catat cek' : 'Catat servis'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 13),
        backgroundColor: colors.accent,
        foregroundColor: colors.onAccent,
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
                tooltip: part.isInspection ? 'Catat cek' : 'Catat ganti',
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
