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

    return RawatinCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, color: colors.primaryDark),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Ringkasan biaya',
                  style: AppType.cardTitle.copyWith(color: colors.ink),
                ),
              ),
              Text(
                shortMonthName(now.month),
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _amount('Bulan ini', thisMonth, colors)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _amount('Tahun ini', thisYear, colors)),
            ],
          ),
          if (sortedItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            for (final item in sortedItems.take(4))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.inkSoft, fontSize: 12),
                      ),
                    ),
                    Text(
                      formatRupiah(item.value),
                      style: TextStyle(
                        color: colors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                'Biaya akan muncul setelah kamu mencatat servis.',
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _amount(String label, int amount, RawatinColors colors) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: colors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: colors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.muted, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          formatRupiah(amount),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppType.metric.copyWith(color: colors.ink, fontSize: 16),
        ),
      ],
    ),
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
