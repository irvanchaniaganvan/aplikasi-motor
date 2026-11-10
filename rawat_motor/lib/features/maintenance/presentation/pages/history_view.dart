import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_labels.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/motor_data.dart';
import '../../domain/entities/odometer_entry.dart';
import '../../domain/entities/service_record.dart';
import '../widgets/common_widgets.dart';
import '../widgets/cost_summary_card.dart';
import '../../../trips/data/repositories/local_trip_repository.dart';
import '../../../trips/presentation/pages/trip_record_page.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({
    required this.data,
    this.vehicleId = 'vehicle-1',
    super.key,
  });

  final MotorData? data;
  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    final entries = <({DateTime date, Widget tile})>[];
    for (final record in data?.serviceHistory ?? const <ServiceRecord>[]) {
      entries.add((
        date: record.date,
        tile: _historyTile(
          context,
          icon: AppIcons.wrench,
          title: record.item,
          subtitle: 'Servis - ${formatShortDate(record.date)}',
          trailing: formatKm(record.odometer),
          chip: record.workshop.isEmpty ? null : record.workshop,
          detail: record.notes.isEmpty ? null : record.notes,
          receiptPath: record.receiptPath,
        ),
      ));
    }
    for (final entry in data?.odometerLogs ?? const <OdometerEntry>[]) {
      entries.add((
        date: entry.date,
        tile: _historyTile(
          context,
          icon: AppIcons.speed,
          title: 'Kilometer diperbarui',
          subtitle: formatShortDate(entry.date),
          trailing: formatKm(entry.kilometers),
          chip: _sourceLabel(entry.source),
        ),
      ));
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    final grouped = <Widget>[];
    String? currentMonth;
    for (final entry in entries) {
      final month = _monthKey(entry.date);
      if (month != currentMonth) {
        currentMonth = month;
        grouped.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
            child: Text(
              _monthLabel(entry.date).toUpperCase(),
              style: AppType.eyebrow.copyWith(
                color: RawatinColors.of(context).primaryDark,
                fontSize: 10,
              ),
            ),
          ),
        );
      }
      grouped.add(entry.tile);
      grouped.add(const Divider(height: 1));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const RawatinScreenIntro(
                eyebrow: 'CATATAN PERAWATAN',
                title: 'Riwayat',
                description: 'Catatan servis dan perubahan kilometer motormu, rapi dalam satu garis waktu.',
              ),
              const SizedBox(height: AppSpacing.lg),
              CostSummaryCard(records: data?.serviceHistory ?? const []),
              const SizedBox(height: AppSpacing.md),
              RawatinCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: grouped.isEmpty
                    ? const RawatinEmptyState(
                        icon: AppIcons.history,
                        title: 'Belum ada riwayat',
                        message: 'Catat servis atau perbarui KM dari Beranda untuk melihatnya di sini.',
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: grouped,
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              RawatinCard(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: TripHistorySection(
                  vehicleId: vehicleId,
                  repository: LocalTripRepository(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _monthKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

String _monthLabel(DateTime date) =>
    '${shortMonthName(date.month)} ${date.year}';

String _sourceLabel(String source) => switch (source.toLowerCase()) {
  'manual' => 'Manual',
  'servis' => 'Servis',
  _ => source,
};

Widget _historyTile(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  String? trailing,
  String? detail,
  String? chip,
  String? receiptPath,
}) {
  final colors = RawatinColors.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Icon(icon, color: colors.primaryDark, size: 19),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (chip != null) ...[
                    const SizedBox(width: 6),
                    RawatinSourceChip(label: chip),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: colors.muted, fontSize: 11.5),
              ),
              if (detail != null) ...[
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    color: colors.primaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (receiptPath != null && receiptPath.isNotEmpty)
                ServiceReceiptButton(path: receiptPath),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            trailing,
            style: AppType.metric.copyWith(color: colors.ink, fontSize: 14),
          ),
        ],
      ],
    ),
  );
}
