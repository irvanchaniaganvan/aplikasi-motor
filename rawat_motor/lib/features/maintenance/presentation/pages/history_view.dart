import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_labels.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/motor_data.dart';
import '../../domain/entities/odometer_entry.dart';
import '../../domain/entities/service_record.dart';
import '../../../trips/data/repositories/local_trip_repository.dart';
import '../../../trips/domain/repositories/trip_repository.dart';
import '../../../trips/presentation/pages/trip_record_page.dart';
import '../widgets/common_widgets.dart';
import '../widgets/cost_summary_card.dart';

enum _HistoryFilter { all, service, odometer }

enum _HistoryKind { service, odometer }

class _HistoryEntry {
  const _HistoryEntry({
    required this.date,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.kilometers,
    this.cost = 0,
    this.notes,
    this.receiptPath,
  });

  final DateTime date;
  final _HistoryKind kind;
  final String title;
  final String subtitle;
  final int kilometers;
  final int cost;
  final String? notes;
  final String? receiptPath;
}

class _MonthGroup {
  _MonthGroup(this.entries);

  final List<_HistoryEntry> entries;
}

class HistoryView extends StatefulWidget {
  const HistoryView({
    required this.data,
    this.vehicleId = 'vehicle-1',
    this.tripRepository,
    super.key,
  });

  final MotorData? data;
  final String vehicleId;
  final TripRepository? tripRepository;

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    final records = widget.data?.serviceHistory ?? const <ServiceRecord>[];
    final entries = _buildEntries(records);
    final serviceCount = entries
        .where((entry) => entry.kind == _HistoryKind.service)
        .length;
    final odometerCount = entries.length - serviceCount;
    final visible = switch (_filter) {
      _HistoryFilter.all => entries,
      _HistoryFilter.service =>
        entries.where((entry) => entry.kind == _HistoryKind.service).toList(),
      _HistoryFilter.odometer =>
        entries.where((entry) => entry.kind == _HistoryKind.odometer).toList(),
    };
    final months = _groupByMonth(visible);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isNarrow ? AppSpacing.lg : AppSpacing.xl,
        isNarrow ? AppSpacing.lg : AppSpacing.xxl,
        isNarrow ? AppSpacing.lg : AppSpacing.xl,
        AppSpacing.xxxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RawatinScreenIntro(
                eyebrow: 'CATATAN PERAWATAN',
                title: 'Riwayat',
                compact: isNarrow,
                description: isNarrow
                    ? 'Servis dan perubahan kilometer, rapi dalam satu garis waktu.'
                    : 'Catatan servis dan perubahan kilometer motormu, rapi dalam satu garis waktu.',
              ),
              SizedBox(height: isNarrow ? AppSpacing.md : AppSpacing.lg),
              CostSummaryCard(records: records),
              SizedBox(height: isNarrow ? AppSpacing.md : AppSpacing.lg),
              _FilterBar(
                filter: _filter,
                serviceCount: serviceCount,
                odometerCount: odometerCount,
                onSelected: (filter) => setState(() => _filter = filter),
              ),
              const SizedBox(height: AppSpacing.sm),
              RawatinCard(
                padding: EdgeInsets.zero,
                child: months.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: RawatinEmptyState(
                          icon: AppIcons.history,
                          title: entries.isEmpty
                              ? 'Belum ada riwayat'
                              : 'Tidak ada catatan',
                          message: entries.isEmpty
                              ? 'Catat servis atau perbarui KM dari Beranda untuk melihatnya di sini.'
                              : _emptyFilterMessage,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final month in months) ...[
                            _MonthHeading(
                              date: month.entries.first.date,
                              count: month.entries.length,
                            ),
                            for (
                              var index = 0;
                              index < month.entries.length;
                              index++
                            )
                              _TimelineRow(
                                entry: month.entries[index],
                                isFirst: index == 0,
                                isLast: index == month.entries.length - 1,
                              ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
              ),
              SizedBox(height: isNarrow ? AppSpacing.md : AppSpacing.lg),
              RawatinCard(
                padding: EdgeInsets.all(
                  isNarrow ? AppSpacing.lg : AppSpacing.xl,
                ),
                child: TripHistorySection(
                  vehicleId: widget.vehicleId,
                  repository: widget.tripRepository ?? LocalTripRepository(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _emptyFilterMessage => switch (_filter) {
    _HistoryFilter.service => 'Belum ada catatan servis pada filter ini.',
    _HistoryFilter.odometer => 'Belum ada perubahan kilometer pada filter ini.',
    _HistoryFilter.all => 'Belum ada catatan pada filter ini.',
  };

  List<_HistoryEntry> _buildEntries(List<ServiceRecord> records) {
    final entries = <_HistoryEntry>[
      for (final record in records)
        _HistoryEntry(
          date: record.date,
          kind: _HistoryKind.service,
          title: record.item,
          subtitle: record.workshop.trim().isEmpty
              ? 'Servis'
              : record.workshop.trim(),
          kilometers: record.odometer,
          cost: record.cost,
          notes: record.notes.trim().isEmpty ? null : record.notes.trim(),
          receiptPath: record.receiptPath,
        ),
      for (final log in widget.data?.odometerLogs ?? const <OdometerEntry>[])
        _HistoryEntry(
          date: log.date,
          kind: _HistoryKind.odometer,
          title: 'Kilometer diperbarui',
          subtitle: 'Odometer · ${_sourceLabel(log.source)}',
          kilometers: log.kilometers,
        ),
    ]..sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  List<_MonthGroup> _groupByMonth(List<_HistoryEntry> entries) {
    final groups = <_MonthGroup>[];
    var currentKey = '';
    for (final entry in entries) {
      final key = '${entry.date.year}-${entry.date.month}';
      if (groups.isEmpty || key != currentKey) {
        currentKey = key;
        groups.add(_MonthGroup([]));
      }
      groups.last.entries.add(entry);
    }
    return groups;
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.serviceCount,
    required this.odometerCount,
    required this.onSelected,
  });

  final _HistoryFilter filter;
  final int serviceCount;
  final int odometerCount;
  final ValueChanged<_HistoryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final chips = <({_HistoryFilter filter, String label, int count})>[
      (
        filter: _HistoryFilter.all,
        label: 'Semua',
        count: serviceCount + odometerCount,
      ),
      (filter: _HistoryFilter.service, label: 'Servis', count: serviceCount),
      (filter: _HistoryFilter.odometer, label: 'KM', count: odometerCount),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final chip in chips)
          _HistoryFilterChip(
            label: chip.label,
            count: chip.count,
            selected: filter == chip.filter,
            onTap: () => onSelected(chip.filter),
          ),
      ],
    );
  }
}

class _HistoryFilterChip extends StatelessWidget {
  const _HistoryFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return FilterChip(
      selected: selected,
      label: Text('$label · $count'),
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: colors.accentSoft,
      backgroundColor: colors.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? colors.accent : colors.line,
          width: selected ? 1.4 : 1,
        ),
      ),
      labelStyle: TextStyle(
        color: selected ? colors.accent : colors.inkSoft,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class _MonthHeading extends StatelessWidget {
  const _MonthHeading({required this.date, required this.count});

  final DateTime date;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          RawatinSpeedStripe(color: colors.accent),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${shortMonthName(date.month).toUpperCase()} ${date.year}',
            style: AppType.eyebrow.copyWith(
              color: colors.inkSoft,
              fontSize: 9.5,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Container(height: 1, color: colors.line)),
          const SizedBox(width: AppSpacing.md),
          Text(
            '$count',
            style: AppType.metric.copyWith(color: colors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.entry,
    required this.isFirst,
    required this.isLast,
  });

  final _HistoryEntry entry;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    final isService = entry.kind == _HistoryKind.service;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 42,
            child: Padding(
              padding: const EdgeInsets.only(top: 11),
              child: Align(
                alignment: Alignment.topRight,
                child: Text(
                  entry.date.day.toString().padLeft(2, '0'),
                  style: AppType.metric.copyWith(
                    color: colors.ink,
                    fontSize: 15,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: CustomPaint(
              painter: _RailPainter(
                lineColor: colors.line,
                nodeColor: isService ? colors.accent : colors.muted,
                nodeTop: 18,
                isFirst: isFirst,
                isLast: isLast,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 11, AppSpacing.lg, 11),
              child: _EntryBody(entry: entry),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryBody extends StatelessWidget {
  const _EntryBody({required this.entry});

  final _HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    final isService = entry.kind == _HistoryKind.service;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isService ? AppIcons.wrench : AppIcons.speed,
                    size: 13,
                    color: isService ? colors.primaryDark : colors.muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.ink,
                        fontSize: 13.5,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                entry.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.muted, fontSize: 11.5),
              ),
              if (entry.notes != null) ...[
                const SizedBox(height: 4),
                Text(
                  entry.notes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.inkSoft,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
              if (entry.receiptPath != null && entry.receiptPath!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: ServiceReceiptButton(path: entry.receiptPath!),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatKm(entry.kilometers),
              style: AppType.metric.copyWith(color: colors.ink, fontSize: 13.5),
            ),
            if (entry.cost > 0) ...[
              const SizedBox(height: 2),
              Text(
                formatRupiah(entry.cost),
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _RailPainter extends CustomPainter {
  const _RailPainter({
    required this.lineColor,
    required this.nodeColor,
    required this.nodeTop,
    required this.isFirst,
    required this.isLast,
  });

  final Color lineColor;
  final Color nodeColor;
  final double nodeTop;
  final bool isFirst;
  final bool isLast;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final start = isFirst ? nodeTop : 0.0;
    final end = isLast ? nodeTop : size.height;
    if (end > start) {
      canvas.drawLine(
        Offset(x, start),
        Offset(x, end),
        Paint()
          ..color = lineColor
          ..strokeWidth = 1,
      );
    }
    canvas.drawCircle(
      Offset(x, nodeTop),
      6.5,
      Paint()..color = nodeColor.withValues(alpha: 0.14),
    );
    canvas.drawCircle(Offset(x, nodeTop), 3.2, Paint()..color = nodeColor);
  }

  @override
  bool shouldRepaint(_RailPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor ||
      oldDelegate.nodeColor != nodeColor ||
      oldDelegate.nodeTop != nodeTop ||
      oldDelegate.isFirst != isFirst ||
      oldDelegate.isLast != isLast;
}

String _sourceLabel(String source) => switch (source.toLowerCase()) {
  'manual' => 'Manual',
  'servis' => 'Servis',
  _ => source,
};
