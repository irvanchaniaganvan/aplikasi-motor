import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_labels.dart';
import '../../domain/entities/service_record.dart';
import '../../../profile/presentation/widgets/vehicle_photo_viewer.dart';
import 'common_widgets.dart';

class CostSummaryCard extends StatelessWidget {
  const CostSummaryCard({required this.records, super.key});

  final List<ServiceRecord> records;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    final now = DateTime.now();
    final thisMonth = records
        .where(
          (record) =>
              record.date.year == now.year && record.date.month == now.month,
        )
        .fold<int>(0, (total, record) => total + record.cost);
    final thisYear = records
        .where((record) => record.date.year == now.year)
        .fold<int>(0, (total, record) => total + record.cost);
    final byItem = <String, int>{};
    for (final record in records) {
      byItem.update(
        record.item,
        (value) => value + record.cost,
        ifAbsent: () => record.cost,
      );
    }
    final sortedItems = byItem.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topItems = sortedItems.take(4).toList();
    final maxCost = topItems.isEmpty ? 1 : topItems.first.value;

    return RawatinCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                color: colors.primaryDark,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Ringkasan biaya',
                  style: AppType.cardTitle.copyWith(
                    color: colors.ink,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  '${shortMonthName(now.month).toUpperCase()} ${now.year}',
                  style: AppType.eyebrow.copyWith(
                    color: colors.muted,
                    fontSize: 8.5,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _amount('Bulan ini', thisMonth, colors)),
              Container(
                width: 1,
                height: 46,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                color: colors.line,
              ),
              Expanded(child: _amount('Tahun ini', thisYear, colors)),
            ],
          ),
          if (topItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(height: 1, color: colors.line),
            const SizedBox(height: AppSpacing.md),
            for (final item in topItems)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _costBar(item.key, item.value, maxCost, colors),
              ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Biaya akan muncul setelah kamu mencatat servis.',
              style: TextStyle(color: colors.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _amount(String label, int amount, RawatinColors colors) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: colors.muted, fontSize: 11)),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          formatRupiah(amount),
          style: AppType.metric.copyWith(color: colors.ink, fontSize: 26),
        ),
      ),
    ],
  );

  Widget _costBar(
    String label,
    int value,
    int maxValue,
    RawatinColors colors,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.inkSoft, fontSize: 11.5),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            formatRupiah(value),
            style: TextStyle(
              color: colors.ink,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Container(
          height: 3,
          color: colors.surfaceSoft,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (value / maxValue).clamp(0.04, 1.0).toDouble(),
            child: Container(color: colors.accent.withValues(alpha: 0.85)),
          ),
        ),
      ),
    ],
  );
}

String formatRupiah(int value) {
  final digits = value.toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'Rp$grouped';
}

class ServiceReceiptButton extends StatelessWidget {
  const ServiceReceiptButton({required this.path, super.key});

  final String path;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => VehiclePhotoViewer.show(context, path),
    icon: const Icon(Icons.receipt_long_outlined, size: 16),
    label: const Text('Lihat nota'),
  );
}
