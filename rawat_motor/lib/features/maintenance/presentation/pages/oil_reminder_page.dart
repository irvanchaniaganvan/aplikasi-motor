import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/rawatin_logo.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/repositories/default_interval_repository.dart';
import '../../domain/entities/maintenance_component.dart';
import '../../domain/entities/maintenance_catalog.dart';
import '../../domain/entities/maintenance_motor_catalog.dart';
import '../../domain/entities/motor_data.dart';
import '../../domain/entities/odometer_entry.dart';
import '../../domain/entities/service_record.dart';
import '../../domain/services/component_filter.dart';
import '../../domain/services/component_schedule_calculator.dart';
import '../../domain/services/record_component_service.dart';
import '../../domain/services/oil_schedule_calculator.dart';
import '../../domain/use_cases/load_motor_data.dart';
import '../../domain/use_cases/save_motor_data.dart';
import '../../../profile/domain/entities/driver_motor_profile.dart';

class OilReminderPage extends StatefulWidget {
  const OilReminderPage({
    required this.loadMotorData,
    required this.saveMotorData,
    this.profile,
    this.onEditProfile,
    this.onSignOut,
    this.onSelectVehicle,
    this.onAddVehicle,
    this.onManageVehicles,
    this.vehicles = const [],
    this.vehicleCount = 1,
    this.catalog,
    super.key,
  });

  final LoadMotorData loadMotorData;
  final SaveMotorData saveMotorData;
  final DriverMotorProfile? profile;
  final VoidCallback? onEditProfile;
  final VoidCallback? onSignOut;
  final ValueChanged<DriverMotorProfile>? onSelectVehicle;
  final VoidCallback? onAddVehicle;
  final VoidCallback? onManageVehicles;
  final int vehicleCount;
  final List<DriverMotorProfile> vehicles;

  /// Katalog opsional untuk pengujian atau pemuatan awal.
  final MaintenanceCatalog? catalog;

  @override
  State<OilReminderPage> createState() => _OilReminderPageState();
}

class _OilReminderPageState extends State<OilReminderPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _lastOilController = TextEditingController();
  final _intervalController = TextEditingController(text: '3000');
  final _monthsController = TextEditingController(text: '3');
  MotorData? _motorData;
  bool _isLoading = true;
  bool _isSaving = false;
  int _selectedSection = 0;
  List<MaintenanceComponent> _components = const [];
  List<MaintenanceMotor> _maintenanceMotors = const [];
  bool _catalogFailed = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    final catalog = widget.catalog;
    if (catalog != null) {
      _components = catalog.components;
    } else {
      _loadDefaultIntervals();
    }
  }

  Future<void> _loadDefaultIntervals() async {
    try {
      final catalog = await const DefaultIntervalRepository().load();
      final motors = await const DefaultIntervalRepository().loadMotors();
      if (!mounted) return;
      setState(() {
        _components = catalog.components;
        _maintenanceMotors = motors.motors;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _catalogFailed = true);
      _showMessage('Data interval perawatan tidak dapat dimuat.');
    }
  }

  Future<void> _loadSavedData() async {
    try {
      final data = await widget.loadMotorData();
      if (!mounted) return;
      setState(() {
        _motorData = data;
        _isLoading = false;
        if (data != null) {
          _currentController.text = data.currentOdometer.toString();
          _lastOilController.text = data.lastOilOdometer.toString();
          _intervalController.text = data.oilInterval.toString();
          _monthsController.text = (data.oilIntervalMonths ?? 3).toString();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Data tersimpan tidak dapat dibaca. Coba simpan ulang.');
    }
  }

  @override
  void dispose() {
    _currentController.dispose();
    _lastOilController.dispose();
    _intervalController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  Future<bool> _saveMotorData() async {
    if (!_formKey.currentState!.validate()) return false;
    final previousDate = _motorData?.lastOilChangeDate;
    final lastOil = int.parse(_lastOilController.text);
    final interval = int.parse(_intervalController.text);
    final months = int.parse(_monthsController.text);
    final previousOilState = _findComponentState(_motorData, 'Oli mesin');
    final oilState = ComponentMaintenanceState(
      componentName: 'Oli mesin',
      lastServicedKm: lastOil,
      intervalKmOverride: interval,
      intervalMonthsOverride: months,
      lastServicedAt: previousDate ?? previousOilState?.lastServicedAt,
    );
    final data = MotorData(
      currentOdometer: int.parse(_currentController.text),
      lastOilOdometer: lastOil,
      oilInterval: interval,
      oilIntervalMonths: months,
      lastOilChangeDate: previousDate,
      odometerLogs: _appendOdometerLog(
        _motorData?.odometerLogs ?? const [],
        int.parse(_currentController.text),
        'manual',
      ),
      serviceHistory: _motorData?.serviceHistory ?? const [],
      componentStates: _replaceComponentState(
        _motorData?.componentStates ?? const [],
        oilState,
      ),
    );
    setState(() => _isSaving = true);
    try {
      await widget.saveMotorData(data);
      if (!mounted) return false;
      setState(() => _motorData = data);
    } catch (_) {
      _showMessage('Data gagal disimpan. Periksa ruang penyimpanan perangkat.');
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
    FocusScope.of(context).unfocus();
    _showMessage('Data motor siap dipakai untuk menghitung jadwal.');
    return true;
  }

  Future<void> _recordOilChange() async {
    final data = _motorData;
    if (data == null) return;
    final service = ServiceRecord(
      date: DateTime.now(),
      odometer: data.currentOdometer,
      item: 'Oli mesin',
    );
    final currentState = _findComponentState(data, 'Oli mesin');
    final oilState = ComponentMaintenanceState(
      componentName: 'Oli mesin',
      lastServicedKm: data.currentOdometer,
      intervalKmOverride: currentState?.intervalKmOverride ?? data.oilInterval,
      intervalMonthsOverride:
          currentState?.intervalMonthsOverride ?? data.oilIntervalMonths,
      lastServicedAt: service.date,
    );
    final updated = data.copyWith(
      lastOilOdometer: data.currentOdometer,
      lastOilChangeDate: service.date,
      odometerLogs: _appendOdometerLog(
        data.odometerLogs,
        data.currentOdometer,
        'servis',
      ),
      serviceHistory: [...data.serviceHistory, service],
      componentStates: _replaceComponentState(data.componentStates, oilState),
    );
    try {
      await widget.saveMotorData(updated);
    } catch (_) {
      _showMessage('Ganti oli belum dicatat karena data gagal disimpan.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _motorData = updated;
      _lastOilController.text = data.currentOdometer.toString();
    });
    _showMessage('Ganti oli dicatat pada ${formatKm(data.currentOdometer)}.');
  }

  ComponentMaintenanceState? _findComponentState(
    MotorData? data,
    String componentName,
  ) {
    if (data == null) return null;
    for (final state in data.componentStates) {
      if (state.componentName == componentName) return state;
    }
    return null;
  }

  List<ComponentMaintenanceState> _replaceComponentState(
    List<ComponentMaintenanceState> states,
    ComponentMaintenanceState state,
  ) => [
    ...states.where((item) => item.componentName != state.componentName),
    state,
  ];

  List<OdometerEntry> _appendOdometerLog(
    List<OdometerEntry> logs,
    int km,
    String source,
  ) {
    if (logs.isNotEmpty && km <= logs.last.kilometers) return logs;
    return [
      ...logs,
      OdometerEntry(kilometers: km, date: DateTime.now(), source: source),
    ];
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 800;
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (wide)
                  _AppSidebar(
                    selected: _selectedSection,
                    onSelect: _selectSection,
                    profile: widget.profile,
                    onOpenSettings: _showOilReminderSettings,
                  ),
                Expanded(
                  child: Column(
                    children: [
                      _AppTopBar(
                        title: _sectionTitle,
                        profile: widget.profile,
                        onEditProfile: widget.onEditProfile,
                        onSignOut: widget.onSignOut,
                        vehicleCount: widget.vehicleCount,
                        onSelectVehicle: widget.onSelectVehicle,
                        onAddVehicle: widget.onAddVehicle,
                        onManageVehicles: widget.onManageVehicles,
                        vehicles: widget.vehicles,
                        onOpenSettings: _showOilReminderSettings,
                      ),
                      Expanded(
                        child: switch (_selectedSection) {
                          0 => _buildDashboard(),
                          1 => _buildHistoryPage(),
                          2 => _buildHistoryPage(),
                          _ => _buildPartsPage(),
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: wide ? null : _buildMobileNavigation(),
        );
      },
    );
  }

  void _selectSection(int index) => setState(() => _selectedSection = index);

  Widget _buildMobileNavigation() => NavigationBar(
    selectedIndex: _selectedSection == 0 ? 0 : 1,
    onDestinationSelected: (index) => _selectSection(index),
    destinations: const [
      NavigationDestination(
        icon: Icon(AppIcons.home),
        selectedIcon: Icon(AppIcons.home),
        label: 'Beranda',
      ),
      NavigationDestination(
        icon: Icon(AppIcons.history),
        selectedIcon: Icon(AppIcons.history),
        label: 'Riwayat',
      ),
    ],
  );

  String get _sectionTitle => switch (_selectedSection) {
    0 => 'Beranda',
    1 || 2 => 'Riwayat',
    _ => 'Semua jadwal',
  };

  Widget _buildOdometerHero() {
    final colors = RawatinColors.of(context);
    final km = _motorData?.currentOdometer;
    final schedules = _motorData == null
        ? <ComponentSchedule>[]
        : _visibleParts()
              .map((part) => _componentSchedule(part, _motorData!))
              .whereType<ComponentSchedule>()
              .toList();
    int count(ComponentScheduleStatus status) =>
        schedules.where((item) => item.status == status).length;
    final due = count(ComponentScheduleStatus.due);
    final soon = count(ComponentScheduleStatus.soon);
    final safe = count(ComponentScheduleStatus.safe);
    final needsCheck = count(ComponentScheduleStatus.needsCheck);
    final attention = due + soon + needsCheck;
    final allSafe = km != null && attention == 0;
    final statusText = km == null
        ? 'Mulai dengan mencatat kilometer motor'
        : allSafe
        ? 'Semua jadwal terkendali'
        : '$attention hal perlu perhatian';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.ink,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(
          color: colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _HeroBackdropPainter(
                stripe: colors.primary,
                accent: colors.accent,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ODOMETER SEKARANG',
                        style: AppType.eyebrow.copyWith(
                          color: colors.white.withValues(alpha: 0.75),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Icon(
                      AppIcons.speed,
                      size: 19,
                      color: colors.white.withValues(alpha: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (km == null)
                  Text(
                    'Belum dicatat',
                    style: AppType.km.copyWith(
                      fontSize: 40,
                      color: colors.white,
                    ),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: _CountUpOdometer(
                          value: km,
                          style: AppType.km.copyWith(
                            fontSize: 60,
                            color: colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'km',
                        style: AppType.metric.copyWith(
                          color: colors.white.withValues(alpha: 0.65),
                          fontSize: 20,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                if (km != null) ...[
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _HeroStat(
                        label: 'Waktunya',
                        value: due,
                        color: colors.due,
                        soft: colors.dueSoft,
                        icon: AppIcons.due,
                      ),
                      _HeroStat(
                        label: 'Segera',
                        value: soon,
                        color: colors.soon,
                        soft: colors.soonSoft,
                        icon: AppIcons.soon,
                      ),
                      _HeroStat(
                        label: 'Aman',
                        value: safe,
                        color: colors.safe,
                        soft: colors.safeSoft,
                        icon: AppIcons.check,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                Row(
                  children: [
                    Icon(
                      allSafe ? AppIcons.checkCircle : AppIcons.info,
                      color: allSafe ? colors.safeSoft : colors.accent,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _updateOdometer,
                  icon: const Icon(AppIcons.speed),
                  label: const Text('Update KM'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                if (allSafe) ...[
                  const SizedBox(height: 12),
                  const _FinishBanner(
                    title: 'Semua aman',
                    subtitle:
                        'Gas terus! Cek lagi setelah kilometer bertambah.',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.xxl,
      AppSpacing.lg,
      AppSpacing.xxxl,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PageHeader(profile: widget.profile),
            const SizedBox(height: AppSpacing.lg),
            _buildProfileCard(),
            const SizedBox(height: AppSpacing.lg),
            _buildOdometerHero(),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: _SectionHeading(
                    eyebrow: 'JADWAL MOTOR',
                    title: 'Jadwal motormu',
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _selectSection(3),
                  icon: const Icon(AppIcons.arrowForward, size: 16),
                  label: const Text('Semua'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildDashboardMaintenanceSummary(),
            const SizedBox(height: AppSpacing.xl),
            const _SafetyNote(),
          ],
        ),
      ),
    ),
  );

  Widget _buildHistoryPage() {
    final data = _motorData;
    final entries = <({DateTime date, Widget tile})>[];
    for (final record in data?.serviceHistory ?? const <ServiceRecord>[]) {
      entries.add((
        date: record.date,
        tile: _historyTile(
          icon: AppIcons.wrench,
          title: record.item,
          subtitle: 'Servis - ${_formatDate(record.date)}',
          trailing: formatKm(record.odometer),
          chip: record.workshop.isEmpty ? null : record.workshop,
        ),
      ));
    }
    for (final entry in data?.odometerLogs ?? const <OdometerEntry>[]) {
      entries.add((
        date: entry.date,
        tile: _historyTile(
          icon: AppIcons.speed,
          title: 'Kilometer diperbarui',
          subtitle: _formatDate(entry.date),
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
              const _ScreenIntro(
                eyebrow: 'CATATAN PERAWATAN',
                title: 'Riwayat',
                description: 'Catatan servis dan perubahan kilometer motormu, rapi dalam satu garis waktu.',
              ),
              const SizedBox(height: AppSpacing.lg),
              _CardShell(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: grouped.isEmpty
                    ? const _EmptyState(
                        icon: AppIcons.history,
                        title: 'Belum ada riwayat',
                        message: 'Catat servis atau perbarui KM dari Beranda untuk melihatnya di sini.',
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: grouped,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  String _monthLabel(DateTime date) => '${_monthName(date.month)} ${date.year}';

  String _monthName(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ][month - 1];

  String _sourceLabel(String source) => switch (source.toLowerCase()) {
    'manual' => 'Manual',
    'servis' => 'Servis',
    _ => source,
  };

  Future<void> _updateOdometer() async {
    final data = _motorData;
    final controller = _currentController
      ..text = (data?.currentOdometer ?? 0).toString();
    String? error;
    final updatedKm = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SheetHeading(
                    eyebrow: 'ODOMETER',
                    title: 'Update KM',
                    icon: AppIcons.speed,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Kilometer sekarang',
                      suffixText: 'km',
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: RawatinColors.of(context).due,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () {
                      final km = int.tryParse(controller.text.trim());
                      if (km == null ||
                          km < 0 ||
                          (data != null && km < data.currentOdometer)) {
                        setSheetState(
                          () => error =
                              data != null &&
                                  km != null &&
                                  km < data.currentOdometer
                              ? 'KM tidak boleh lebih rendah dari catatan terakhir.'
                              : 'Masukkan angka kilometer yang valid.',
                        );
                        return;
                      }
                      Navigator.pop(sheetContext, km);
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (updatedKm == null ||
        (data != null && updatedKm == data.currentOdometer)) {
      return;
    }
    final updated = data == null
        ? MotorData(
            currentOdometer: updatedKm,
            lastOilOdometer: 0,
            oilInterval: 3000,
            odometerLogs: _appendOdometerLog(const [], updatedKm, 'manual'),
          )
        : data.copyWith(
            currentOdometer: updatedKm,
            odometerLogs: _appendOdometerLog(
              data.odometerLogs,
              updatedKm,
              'manual',
            ),
          );
    await _saveComponentData(updated);
    if (mounted && _motorData == updated) {
      _currentController.text = updatedKm.toString();
      _showMessage('KM berhasil diperbarui ke ${formatKm(updatedKm)}.');
    }
  }

  Widget _historyTile({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailing,
    String? detail,
    String? chip,
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
                      _SourceChip(label: chip),
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

  Widget _buildPartsPage() {
    final data = _motorData;
    final visibleComponents = _visibleParts()
      ..sort(
        (a, b) =>
            _componentUrgency(a, data).compareTo(_componentUrgency(b, data)),
      );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _ScreenIntro(
                eyebrow: 'KOMPONEN & PERAWATAN',
                title: 'Jadwal perawatan',
                description: 'Interval adalah perkiraan umum, bukan spesifikasi resmi. Ikuti buku manual atau saran bengkel.',
              ),
              if (widget.profile != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _InfoChip(
                      icon: AppIcons.vehicle,
                      label:
                          '${widget.profile!.brand} ${widget.profile!.model}',
                    ),
                    if (_motorTypeLabel != null)
                      _InfoChip(
                        icon: AppIcons.category,
                        label: _motorTypeLabel!,
                      ),
                    if (_coolingLabel != null)
                      _InfoChip(icon: AppIcons.cooling, label: _coolingLabel!),
                    if (_frontBrakeLabel != null)
                      _InfoChip(icon: AppIcons.brake, label: _frontBrakeLabel!),
                    _InfoChip(
                      icon: AppIcons.grid,
                      label: '${visibleComponents.length} komponen',
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (data == null) ...[
                _CardShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionHeading(
                        eyebrow: 'LANGKAH PERTAMA',
                        title: 'Mulai dari odometer',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Masukkan kilometer saat ini dan kapan oli terakhir diganti. Setelah disimpan, jadwal part akan muncul otomatis.',
                        style: TextStyle(
                          color: RawatinColors.of(context).muted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton.icon(
                        onPressed: _showOilReminderSettings,
                        icon: const Icon(AppIcons.play),
                        label: const Text('Atur kilometer motor'),
                      ),
                    ],
                  ),
                ),
              ] else if (_components.isEmpty) ...[
                _CardShell(
                  child: _catalogFailed
                      ? Text(
                          'Data interval perawatan tidak dapat dimuat. Periksa file data default.',
                          style: TextStyle(
                            color: RawatinColors.of(context).muted,
                          ),
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
              ] else if (visibleComponents.isEmpty) ...[
                _CardShell(
                  child: Text(
                    'Belum ada komponen yang cocok dengan profil motor.',
                    style: TextStyle(color: RawatinColors.of(context).muted),
                  ),
                ),
              ] else ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 920
                        ? 3
                        : constraints.maxWidth >= 600
                        ? 2
                        : 1;
                    final width =
                        (constraints.maxWidth - (columns - 1) * 16) / columns;
                    return Wrap(
                      spacing: AppSpacing.lg,
                      runSpacing: AppSpacing.lg,
                      children: [
                        for (final component in visibleComponents)
                          SizedBox(
                            width: width,
                            child: _buildComponentCard(component, data),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  MaintenanceMotor? get _selectedMaintenanceMotor {
    final profile = widget.profile;
    if (profile == null) return null;
    for (final motor in _maintenanceMotors) {
      if (profile.maintenanceMotorId == motor.id) return motor;
      final normalized = '${profile.brand} ${profile.model}'.toLowerCase();
      if (normalized.contains(motor.name.toLowerCase()) ||
          (motor.id == 'yamaha-mio-gear-2024' && normalized.contains('gear')) ||
          (motor.id == 'honda-beat-k0j' && normalized.contains('beat')) ||
          (motor.id == 'honda-vario-125-kzr' && normalized.contains('kzr'))) {
        return motor;
      }
    }
    return null;
  }

  List<MaintenanceComponent> _visibleParts() {
    final motor = _selectedMaintenanceMotor;
    final source = motor == null
        ? _components
        : filterPartsForMotor(parts: _components, motor: motor);
    return filterMaintenanceComponents(
      components: source,
      motorType: widget.profile?.motorType,
      cooling: motor?.cooling == 'TODO_VERIFY'
          ? null
          : motor?.cooling ?? widget.profile?.cooling,
      frontBrake: widget.profile?.frontBrake,
    );
  }

  ComponentSchedule? _componentSchedule(
    MaintenanceComponent component,
    MotorData data,
  ) {
    final state = _findComponentState(data, component.name);
    final lastServicedKm =
        state?.lastServicedKm ??
        (component.name == 'Oli mesin' && data.lastOilOdometer > 0
            ? data.lastOilOdometer
            : null);
    final interval =
        state?.intervalKmOverride ??
        (component.name == 'Oli mesin'
            ? data.oilInterval
            : component.intervalKm);
    return const ComponentScheduleCalculator().calculate(
      currentOdometer: data.currentOdometer,
      intervalKm: interval,
      lastServicedKm: lastServicedKm,
      intervalMonths:
          state?.intervalMonthsOverride ??
          (component.id == 'oli-mesin'
              ? data.oilIntervalMonths
              : component.intervalMonths),
      lastServicedAt:
          state?.lastServicedAt ??
          (component.id == 'oli-mesin' ? data.lastOilChangeDate : null),
    );
  }

  int _componentUrgency(MaintenanceComponent component, MotorData? data) {
    if (data == null) return 3;
    final schedule = _componentSchedule(component, data);
    if (schedule == null) return 3;
    return switch (schedule.status) {
      ComponentScheduleStatus.due => 0,
      ComponentScheduleStatus.soon => 1,
      ComponentScheduleStatus.needsCheck => 2,
      ComponentScheduleStatus.safe => 3,
    };
  }

  Widget _buildComponentCard(MaintenanceComponent component, MotorData data) {
    final colors = RawatinColors.of(context);
    final state = _findComponentState(data, component.name);
    final interval =
        state?.intervalKmOverride ??
        (component.name == 'Oli mesin'
            ? data.oilInterval
            : component.intervalKm);
    final months =
        state?.intervalMonthsOverride ??
        (component.name == 'Oli mesin'
            ? data.oilIntervalMonths
            : component.intervalMonths);
    var lastServicedKm = state?.lastServicedKm;
    if (component.name == 'Oli mesin' &&
        lastServicedKm == null &&
        data.lastOilOdometer > 0) {
      lastServicedKm = data.lastOilOdometer;
    }
    final schedule =
        const ComponentScheduleCalculator().calculate(
          currentOdometer: data.currentOdometer,
          intervalKm: interval,
          lastServicedKm: lastServicedKm,
          intervalMonths: months,
          lastServicedAt:
              state?.lastServicedAt ??
              (component.id == 'oli-mesin' ? data.lastOilChangeDate : null),
        ) ??
        const ComponentSchedule(
          targetKm: 0,
          remainingKm: 0,
          status: ComponentScheduleStatus.needsCheck,
        );
    final due = schedule.status == ComponentScheduleStatus.due;
    final soon = schedule.status == ComponentScheduleStatus.soon;
    final needsCheck = schedule.status == ComponentScheduleStatus.needsCheck;
    final statusColor = due
        ? colors.due
        : soon
        ? colors.soon
        : needsCheck
        ? colors.check
        : colors.safe;
    final statusBackground = due
        ? colors.dueSoft
        : soon
        ? colors.soonSoft
        : needsCheck
        ? colors.checkSoft
        : colors.safeSoft;
    final statusIcon = due
        ? AppIcons.due
        : soon
        ? AppIcons.soon
        : needsCheck
        ? AppIcons.needsCheck
        : AppIcons.check;
    final statusText = needsCheck
        ? 'Perlu dicek'
        : switch (schedule.status) {
            ComponentScheduleStatus.safe => 'Aman',
            ComponentScheduleStatus.needsCheck => 'Perlu dicek',
            ComponentScheduleStatus.soon =>
              component.isInspection ? 'Segera cek' : 'Segera ganti',
            ComponentScheduleStatus.due =>
              component.isInspection ? 'Waktunya cek' : 'Waktunya ganti',
          };
    final intervalText =
        '${component.isInspection ? 'Cek' : 'Ganti'} tiap ${formatKm(interval)}'
        '${months == null ? '' : ' / $months bln'}';
    final progress = needsCheck || interval <= 0 || lastServicedKm == null
        ? null
        : ((data.currentOdometer - lastServicedKm) / interval)
              .clamp(0.0, 1.0)
              .toDouble();
    final remainingKm = schedule.remainingKm;
    final description = needsCheck
        ? 'Belum ada catatan servis untuk komponen ini.'
        : remainingKm <= 0
        ? component.isInspection
              ? 'Sudah waktunya periksa sekarang.'
              : 'Sudah waktunya ganti sekarang.'
        : '${component.isInspection ? 'Periksa' : 'Ganti'} sekitar '
              '${formatKm(remainingKm)} lagi'
              '${schedule.daysRemaining == null ? '' : ' atau ${schedule.daysRemaining} hari'}';

    return _PartCard(
      name: component.name,
      icon: _componentIcon(component),
      statusLabel: statusText,
      statusColor: statusColor,
      statusSoft: statusBackground,
      statusIcon: statusIcon,
      description: description,
      meta: intervalText,
      progress: progress,
      prominent: due || soon,
      inspection: component.isInspection,
      onOpen: () => _showComponentActions(component, state),
      onRecord: () => _showRecordComponentForm(component),
    );
  }

  IconData _componentIcon(MaintenanceComponent component) {
    final name = component.name.toLowerCase();
    if (name.contains('oli gardan') || name.contains('oli')) {
      return AppIcons.oil;
    }
    if (name.contains('busi')) return AppIcons.sparkPlug;
    if (name.contains('rem') || name.contains('minyak rem')) {
      return AppIcons.brake;
    }
    if (name.contains('ban')) return AppIcons.tire;
    if (name.contains('v-belt') ||
        name.contains('vbelt') ||
        name.contains('belt') ||
        name.contains('roller') ||
        name.contains('cvt')) {
      return AppIcons.belt;
    }
    if (name.contains('rantai') || name.contains('gear')) {
      return AppIcons.chain;
    }
    if (name.contains('coolant') ||
        name.contains('radiator') ||
        name.contains('pendingin')) {
      return AppIcons.cooling;
    }
    if (name.contains('filter')) return AppIcons.airFilter;
    if (name.contains('aki') || name.contains('baterai')) {
      return AppIcons.battery;
    }
    if (name.contains('lampu')) return AppIcons.tip;
    return component.isInspection ? AppIcons.search : AppIcons.wrench;
  }

  Future<void> _showComponentActions(
    MaintenanceComponent component,
    ComponentMaintenanceState? state,
  ) async {
    final data = _motorData;
    if (data == null) return;
    final history =
        data.serviceHistory
            .where(
              (record) =>
                  record.item.toLowerCase() == component.name.toLowerCase(),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: cream,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(_componentIcon(component), color: green, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      component.name,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _editComponentInterval(component, state);
                },
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Ubah interval'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Riwayat servis',
                style: TextStyle(color: ink, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (history.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Belum ada riwayat servis untuk komponen ini.',
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(sheetContext).height * .35,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: history.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final record = history[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.build_circle_outlined,
                          color: green,
                        ),
                        title: Text(
                          formatKm(record.odometer),
                          style: const TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          _formatDate(record.date),
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editComponentInterval(
    MaintenanceComponent component,
    ComponentMaintenanceState? current,
  ) async {
    final kmController = TextEditingController(
      text: '${current?.intervalKmOverride ?? component.intervalKm}',
    );
    final monthController = TextEditingController(
      text:
          (current?.intervalMonthsOverride ?? component.intervalMonths)
              ?.toString() ??
          '',
    );
    String? error;
    final result = await showModalBottomSheet<({int km, int? months})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Atur interval · ${component.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextField(
                  controller: kmController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Kilometer',
                    suffixText: 'km',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: monthController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Bulan (opsional)',
                    suffixText: 'bulan',
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      error!,
                      style: const TextStyle(color: danger, fontSize: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    final km = int.tryParse(kmController.text.trim());
                    final monthText = monthController.text.trim();
                    final months = monthText.isEmpty
                        ? null
                        : int.tryParse(monthText);
                    if (km == null || km <= 0) {
                      setDialogState(
                        () => error = 'Isi interval kilometer lebih dari 0.',
                      );
                      return;
                    }
                    if (monthText.isNotEmpty &&
                        (months == null || months <= 0)) {
                      setDialogState(
                        () => error = 'Interval bulan harus lebih dari 0.',
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, (km: km, months: months));
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    kmController.dispose();
    monthController.dispose();
    if (result == null || _motorData == null) return;

    final data = _motorData!;
    final state = ComponentMaintenanceState(
      componentName: component.name,
      lastServicedKm: current?.lastServicedKm,
      intervalKmOverride: result.km,
      intervalMonthsOverride: result.months,
      lastServicedAt: current?.lastServicedAt,
    );
    var updated = data.copyWith(
      componentStates: _replaceComponentState(data.componentStates, state),
    );
    if (component.name == 'Oli mesin') {
      updated = updated.copyWith(
        oilInterval: result.km,
        oilIntervalMonths: result.months ?? data.oilIntervalMonths,
      );
    }
    await _saveComponentData(updated);
  }

  Future<void> _showRecordComponentForm(MaintenanceComponent component) async {
    final data = _motorData;
    if (data == null) return;
    final kmController = TextEditingController(
      text: data.currentOdometer.toString(),
    );
    final costController = TextEditingController();
    final notesController = TextEditingController();
    var serviceDate = DateTime.now();
    var showDetails = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: cream,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Catat ganti ${component.name}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: kmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kilometer servis',
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final chosen = await showDatePicker(
                    context: context,
                    initialDate: serviceDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (chosen != null) setSheetState(() => serviceDate = chosen);
                },
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  'Tanggal: ${serviceDate.day}/${serviceDate.month}/${serviceDate.year}',
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    setSheetState(() => showDetails = !showDetails),
                icon: Icon(showDetails ? Icons.expand_less : Icons.expand_more),
                label: Text(
                  showDetails ? 'Sembunyikan detail' : 'Tambah detail',
                ),
              ),
              if (showDetails) ...[
                TextField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Biaya (opsional)',
                  ),
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  final km = int.tryParse(kmController.text.trim());
                  final cost = int.tryParse(
                    costController.text.trim().isEmpty
                        ? '0'
                        : costController.text.trim(),
                  );
                  if (km == null || km < 0 || cost == null || cost < 0) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Isi kilometer dan biaya dengan angka yang valid.',
                        ),
                      ),
                    );
                    return;
                  }
                  if (km < data.currentOdometer) {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Kilometer lebih rendah'),
                        content: Text(
                          'Odometer saat ini ${formatKm(data.currentOdometer)}, sedangkan catatan ${formatKm(km)}. Servis boleh dicatat, tetapi log odometer tidak ditambah. Lanjutkan?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text('Tetap catat'),
                          ),
                        ],
                      ),
                    );
                    if (!context.mounted) return;
                    if (confirmed != true) return;
                  }
                  final updated = const RecordComponentService().record(
                    data: data,
                    component: component,
                    odometer: km,
                    date: serviceDate,
                    cost: cost,
                    notes: notesController.text.trim(),
                  );
                  try {
                    await widget.saveMotorData(updated);
                    if (!context.mounted || !mounted) return;
                    setState(() => _motorData = updated);
                    Navigator.pop(sheetContext);
                    _showMessage('${component.name} berhasil dicatat.');
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Catatan servis gagal disimpan.'),
                        ),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
    kmController.dispose();
    costController.dispose();
    notesController.dispose();
  }

  Future<void> _saveComponentData(MotorData data) async {
    try {
      await widget.saveMotorData(data);
      if (mounted) setState(() => _motorData = data);
    } catch (_) {
      if (mounted) _showMessage('Perubahan komponen gagal disimpan.');
    }
  }

  Future<void> _showOilReminderSettings() async {
    final originalCurrent = _currentController.text;
    final originalLast = _lastOilController.text;
    final originalInterval = _intervalController.text;
    final originalMonths = _monthsController.text;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: cream,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SingleChildScrollView(child: _buildFormCard()),
        ),
      ),
    );
    if (!mounted) return;
    if (_motorData != null) {
      setState(() {
        _currentController.text = _motorData!.currentOdometer.toString();
        _lastOilController.text = _motorData!.lastOilOdometer.toString();
        _intervalController.text = _motorData!.oilInterval.toString();
        _monthsController.text = (_motorData!.oilIntervalMonths ?? 3)
            .toString();
      });
    } else {
      _currentController.text = originalCurrent;
      _lastOilController.text = originalLast;
      _intervalController.text = originalInterval;
      _monthsController.text = originalMonths;
    }
  }

  Widget _buildFormCard() {
    return _CardShell(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeading(
              eyebrow: 'PENGATURAN MOTOR',
              title: 'Data awal dan interval',
            ),
            const SizedBox(height: 22),
            _OdometerField(
              controller: _currentController,
              label: 'Kilometer saat ini',
              hint: 'Contoh: 12500',
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  requiredNumber(value, 'Isi kilometer saat ini.'),
            ),
            const SizedBox(height: 16),
            _OdometerField(
              controller: _lastOilController,
              label: 'Ganti oli terakhir di kilometer',
              hint: 'Contoh: 10000',
              textInputAction: TextInputAction.next,
              validator: (value) {
                final error = requiredNumber(
                  value,
                  'Isi kilometer ganti oli terakhir.',
                );
                if (error != null) return error;
                final current = int.tryParse(_currentController.text);
                final lastOil = int.tryParse(value!.trim());
                if (current != null && lastOil != null && lastOil > current) {
                  return 'Angka ini tidak boleh melebihi kilometer saat ini.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _OdometerField(
              controller: _intervalController,
              label: 'Pengingat setiap',
              hint: '3000',
              textInputAction: TextInputAction.done,
              validator: (value) {
                final error = requiredNumber(value, 'Isi jarak pengingat.');
                if (error != null) return error;
                if (int.parse(value!.trim()) <= 0) {
                  return 'Jarak pengingat harus lebih besar dari 0 km.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _OdometerField(
              controller: _monthsController,
              label: 'Pengingat setiap berapa bulan',
              hint: '3',
              textInputAction: TextInputAction.done,
              suffixText: 'bulan',
              validator: (value) {
                final error = requiredNumber(value, 'Isi interval bulan.');
                if (error != null) return error;
                if (int.parse(value!.trim()) <= 0) {
                  return 'Interval bulan harus lebih dari 0.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      final saved = await _saveMotorData();
                      if (saved && mounted) {
                        Navigator.of(context).maybePop();
                      }
                    },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text(_isSaving ? 'Menyimpan…' : 'Simpan data motor'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Data disimpan di perangkat ini dan tidak dikirim ke server.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final profile = widget.profile;
    if (profile == null) return const SizedBox.shrink();
    final colors = RawatinColors.of(context);
    final typeLabel = _motorTypeLabel;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          _IconTile(
            icon: AppIcons.vehicle,
            color: colors.primaryDark,
            soft: colors.primarySoft,
            size: 44,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.driverName,
                  style: AppType.cardTitle.copyWith(
                    color: colors.ink,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${profile.brand} ${profile.model} · ${profile.year}'
                  '${typeLabel == null ? '' : ' · $typeLabel'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatusBadge(
            label: 'Aktif',
            icon: AppIcons.verified,
            color: colors.safe,
            background: colors.safeSoft,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardMaintenanceSummary() {
    final colors = RawatinColors.of(context);
    final data = _motorData;
    final active = _visibleParts();
    final ranked =
        active.map((component) {
          final schedule = data == null
              ? null
              : _componentSchedule(component, data);
          return (component: component, schedule: schedule);
        }).toList()..sort((a, b) {
          int rank(ComponentSchedule? schedule) => switch (schedule?.status) {
            ComponentScheduleStatus.due => 0,
            ComponentScheduleStatus.soon => 1,
            ComponentScheduleStatus.needsCheck => 2,
            ComponentScheduleStatus.safe => 3,
            null => 4,
          };
          final statusOrder = rank(a.schedule).compareTo(rank(b.schedule));
          if (statusOrder != 0) return statusOrder;
          return (a.schedule?.remainingKm ?? 0).compareTo(
            b.schedule?.remainingKm ?? 0,
          );
        });
    if (ranked.isEmpty) return _buildStatusCard();

    final attention = ranked
        .where(
          (item) =>
              item.schedule?.status == ComponentScheduleStatus.due ||
              item.schedule?.status == ComponentScheduleStatus.soon,
        )
        .toList();
    final needsCheck = ranked
        .where(
          (item) =>
              item.schedule == null ||
              item.schedule?.status == ComponentScheduleStatus.needsCheck,
        )
        .map((item) => item.component)
        .toList();
    final safeEntries = ranked
        .where((item) => item.schedule?.status == ComponentScheduleStatus.safe)
        .toList();
    final safe = safeEntries.map((item) => item.component).toList();
    final firstSafe = safeEntries.isEmpty ? null : safeEntries.first;
    final safeSubtitle = firstSafe == null
        ? 'Tidak perlu tindakan sekarang.'
        : 'Terdekat: ${firstSafe.component.name}, '
              '${firstSafe.schedule!.remainingKm <= 0 ? 'sudah waktunya dicek' : '${formatKm(firstSafe.schedule!.remainingKm)} lagi'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in attention) ...[
          _buildComponentCard(item.component, data!),
          const SizedBox(height: AppSpacing.md),
        ],
        if (needsCheck.isNotEmpty) ...[
          _CollapsiblePartGroup(
            storageKey: 'needs-check',
            title: 'Belum ada data (${needsCheck.length})',
            subtitle: 'Lengkapi catatan servis agar jadwal lebih akurat.',
            icon: AppIcons.needsCheck,
            color: colors.check,
            soft: colors.checkSoft,
            statusLabel: 'Perlu dicek',
            statusColor: colors.check,
            statusSoft: colors.checkSoft,
            statusIcon: AppIcons.needsCheck,
            parts: needsCheck,
            iconFor: _componentIcon,
            onOpen: (component) => _showComponentActions(
              component,
              _findComponentState(data, component.name),
            ),
            onRecord: _showRecordComponentForm,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (safe.isNotEmpty) ...[
          _CollapsiblePartGroup(
            storageKey: 'safe-parts',
            title: 'Aman (${safe.length})',
            subtitle: safeSubtitle,
            icon: AppIcons.checkCircle,
            color: colors.safe,
            soft: colors.safeSoft,
            statusLabel: 'Aman',
            statusColor: colors.safe,
            statusSoft: colors.safeSoft,
            statusIcon: AppIcons.check,
            parts: safe,
            iconFor: _componentIcon,
            onOpen: (component) => _showComponentActions(
              component,
              _findComponentState(data, component.name),
            ),
            onRecord: _showRecordComponentForm,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _CardShell(
          padding: EdgeInsets.zero,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 2,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              leading: _IconTile(
                icon: AppIcons.tip,
                color: colors.primaryDark,
                soft: colors.primarySoft,
              ),
              title: Text(
                'Panduan oli (contoh)',
                style: AppType.cardTitle.copyWith(
                  color: colors.ink,
                  fontSize: 15,
                ),
              ),
              iconColor: colors.primary,
              collapsedIconColor: colors.muted,
              children: [
                Text(
                  'Gunakan interval sebagai perkiraan umum. Untuk angka yang tepat, ikuti buku manual motor atau saran bengkel.',
                  style: TextStyle(color: colors.muted, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    final colors = RawatinColors.of(context);
    final data = _motorData;
    final schedule = data == null
        ? null
        : const OilScheduleCalculator().calculate(data);
    final remaining = schedule?.distanceRemaining;
    final due = schedule?.isDue ?? false;
    final soon = schedule?.status == OilScheduleStatus.soon;
    final statusColor = due
        ? colors.due
        : soon
        ? colors.soon
        : colors.safe;
    final statusBackground = due
        ? colors.dueSoft
        : soon
        ? colors.soonSoft
        : colors.safeSoft;
    final statusIcon = due
        ? AppIcons.due
        : soon
        ? AppIcons.soon
        : AppIcons.check;
    final statusLabel = due
        ? 'Jatuh tempo'
        : soon
        ? 'Segera'
        : 'Aman';
    final reminder = remaining == null
        ? '—'
        : remaining == 0
        ? 'Sudah waktunya'
        : remaining < 0
        ? 'Terlambat ${formatKm(remaining.abs())}'
        : '${formatKm(remaining)} lagi';
    final caption = remaining == null
        ? 'Isi data motor untuk melihat jadwal oli.'
        : remaining <= 0
        ? remaining == 0
              ? 'Jadwal ganti oli sudah tercapai.'
              : 'Jadwal ganti oli sudah terlewat.'
        : 'menuju jadwal ganti oli berikutnya';
    final progress = data == null || data.oilInterval <= 0
        ? 0.0
        : ((data.currentOdometer - data.lastOilOdometer) / data.oilInterval)
              .clamp(0.0, 1.0)
              .toDouble();

    return _CardShell(
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: _SectionHeading(
                  eyebrow: 'JADWAL OLI',
                  title: 'Ganti oli berikutnya',
                ),
              ),
              _IconTile(
                icon: AppIcons.oil,
                color: statusColor,
                soft: statusBackground,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: _StatusBadge(
              label: statusLabel,
              icon: statusIcon,
              color: statusColor,
              background: statusBackground,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            reminder,
            style: AppType.metric.copyWith(
              color: due ? colors.due : colors.ink,
              fontSize: remaining != null && remaining.abs() >= 100000
                  ? 30
                  : 38,
              height: 1.05,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            caption,
            style: TextStyle(color: colors.muted, fontSize: 13, height: 1.45),
          ),
          if (data != null && schedule != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _SlimProgressIndicator(
              value: progress,
              color: statusColor,
              label: '${(progress * 100).round()}% interval terpakai',
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Divider(color: colors.line),
          const SizedBox(height: AppSpacing.lg),
          _SummaryRow(
            label: 'Odometer sekarang',
            value: data == null ? '—' : formatKm(data.currentOdometer),
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Ganti oli terakhir',
            value: data == null ? '—' : formatKm(data.lastOilOdometer),
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Tanggal servis',
            value: data?.lastOilChangeDate == null
                ? 'Belum dicatat'
                : _formatDate(data!.lastOilChangeDate!),
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Target berikutnya',
            value: schedule == null ? '—' : formatKm(schedule.nextOdometer),
          ),
          if (schedule?.nextDate != null) ...[
            const SizedBox(height: 12),
            _SummaryRow(
              label: 'Target berdasarkan waktu',
              value: _formatDate(schedule!.nextDate!),
            ),
            const SizedBox(height: 12),
            _SummaryRow(
              label: 'Sisa waktu',
              value: schedule.daysRemaining! <= 0
                  ? 'Jatuh tempo'
                  : '${schedule.daysRemaining} hari',
            ),
          ],
          if (data != null &&
              (data.odometerLogs.isNotEmpty ||
                  data.serviceHistory.isNotEmpty)) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: AppIcons.speed,
                  label: '${data.odometerLogs.length} log odometer',
                ),
                _InfoChip(
                  icon: AppIcons.wrench,
                  label: '${data.serviceHistory.length} catatan servis',
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: data == null ? null : _recordOilChange,
            icon: const Icon(AppIcons.checkCircleOutline, size: 19),
            label: const Text('Catat ganti oli'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data == null
                ? 'Tombol aktif setelah data motor disimpan.'
                : 'Ganti oli terakhir dicatat di ${formatKm(data.lastOilOdometer)}.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.muted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  String? get _motorTypeLabel => switch (widget.profile?.motorType) {
    'matic' => 'Matic',
    'bebek' => 'Bebek',
    'sport' => 'Sport',
    _ => null,
  };

  String? get _coolingLabel => switch (widget.profile?.cooling) {
    'udara' => 'Pendingin udara',
    'cair' => 'Pendingin cair',
    _ => null,
  };

  String? get _frontBrakeLabel => switch (widget.profile?.frontBrake) {
    'cakram' => 'Rem cakram',
    'tromol' => 'Rem tromol',
    _ => null,
  };

  String _formatDate(DateTime date) =>
      '${date.day} ${_monthName(date.month)} ${date.year}';
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({this.profile});
  final DriverMotorProfile? profile;

  @override
  Widget build(BuildContext context) => _ScreenIntro(
    eyebrow: 'RINGKASAN PERAWATAN',
    title: profile == null ? 'Kondisi motormu' : 'Hai, ${profile!.driverName}!',
    description: 'Jadwal dan catatan perawatan dalam satu tempat.',
  );
}

class _AppSidebar extends StatelessWidget {
  const _AppSidebar({
    required this.selected,
    required this.onSelect,
    this.profile,
    this.onOpenSettings,
  });
  final int selected;
  final ValueChanged<int> onSelect;
  final DriverMotorProfile? profile;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Container(
      width: 252,
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        border: Border(right: BorderSide(color: colors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      const _BrandMark(),
                      const SizedBox(width: 11),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rawatin',
                            style: AppType.cardTitle.copyWith(
                              color: colors.ink,
                              fontSize: 21,
                              letterSpacing: 0.2,
                            ),
                          ),
                          Text(
                            'PERAWATAN MOTOR',
                            style: AppType.eyebrow.copyWith(
                              color: colors.muted,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 8),
                  child: Text(
                    'NAVIGASI',
                    style: AppType.eyebrow.copyWith(
                      color: colors.muted,
                      fontSize: 9,
                    ),
                  ),
                ),
                _navItem(0, AppIcons.home, 'Beranda', colors),
                _navItem(1, AppIcons.history, 'Riwayat', colors),
                _actionItem(
                  AppIcons.settings,
                  'Pengaturan motor',
                  onOpenSettings,
                  colors,
                ),
              ],
            ),
          ),
          const Spacer(),
          if (profile != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(color: colors.line),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: colors.primarySoft,
                      foregroundColor: colors.primaryDark,
                      child: Text(
                        profile!.driverName.isEmpty
                            ? '?'
                            : profile!.driverName[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile!.driverName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.ink,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${profile!.brand} ${profile!.model}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: colors.muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _navItem(
    int index,
    IconData icon,
    String label,
    RawatinColors colors,
  ) {
    final active = selected == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          selected: active,
          selectedTileColor: colors.primarySoft,
          selectedColor: colors.primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          minLeadingWidth: 22,
          leading: Icon(
            icon,
            color: active ? colors.primaryDark : colors.muted,
            size: 20,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: active ? colors.primaryDark : colors.inkSoft,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
          onTap: () => onSelect(index),
          dense: true,
        ),
      ),
    );
  }

  Widget _actionItem(
    IconData icon,
    String label,
    VoidCallback? onTap,
    RawatinColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          minLeadingWidth: 22,
          leading: Icon(icon, color: colors.muted, size: 20),
          title: Text(
            label,
            style: TextStyle(
              color: colors.inkSoft,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          onTap: onTap,
          dense: true,
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => const RawatinLogo(size: 38);
}

class _AppTopBar extends StatelessWidget {
  const _AppTopBar({
    required this.title,
    this.profile,
    this.onEditProfile,
    this.onSignOut,
    this.vehicleCount = 1,
    this.onSelectVehicle,
    this.onAddVehicle,
    this.onManageVehicles,
    this.vehicles = const [],
    this.onOpenSettings,
  });
  final String title;
  final DriverMotorProfile? profile;
  final VoidCallback? onEditProfile;
  final VoidCallback? onSignOut;
  final int vehicleCount;
  final ValueChanged<DriverMotorProfile>? onSelectVehicle;
  final VoidCallback? onAddVehicle;
  final VoidCallback? onManageVehicles;
  final List<DriverMotorProfile> vehicles;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    final compact = MediaQuery.sizeOf(context).width < 560;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 16),
          child: Row(
            children: [
              if (compact) ...[
                const RawatinLogo(size: 28, showShadow: false),
                const SizedBox(width: 9),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'RAWATIN',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: AppType.eyebrow.copyWith(
                        color: colors.primary,
                        fontSize: 9.5,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.cardTitle.copyWith(
                        color: colors.ink,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Pengaturan motor',
                onPressed: onOpenSettings,
                icon: Icon(AppIcons.settings, color: colors.inkSoft),
              ),
              if (profile != null) ...[
                PopupMenuButton<String>(
                  tooltip: 'Pilih kendaraan',
                  onSelected: (value) {
                    if (value == '__add__') {
                      onAddVehicle?.call();
                    } else if (value == '__manage__') {
                      onManageVehicles?.call();
                    } else if (value == profile!.id) {
                      return;
                    } else {
                      onSelectVehicle?.call(
                        vehicles.firstWhere((item) => item.id == value),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    for (final vehicle in vehicles)
                      PopupMenuItem(
                        value: vehicle.id,
                        child: Text('${vehicle.brand} ${vehicle.model}'),
                      ),
                    if (onManageVehicles != null)
                      const PopupMenuItem(
                        value: '__manage__',
                        child: Text('Kelola kendaraan'),
                      ),
                    if (onAddVehicle != null)
                      const PopupMenuItem(
                        value: '__add__',
                        child: Text('Tambah kendaraan'),
                      ),
                  ],
                  child: compact
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            AppIcons.vehicle,
                            size: 22,
                            color: colors.inkSoft,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 130),
                              child: Text(
                                '${profile!.brand} ${profile!.model}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.ink,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(AppIcons.chevronDown, color: colors.muted),
                          ],
                        ),
                ),
                if (!compact) ...[
                  const SizedBox(width: AppSpacing.sm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      profile!.driverName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.muted, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(width: 2),
                _AccountMenu(
                  profile: profile!,
                  onEditProfile: onEditProfile,
                  onSignOut: onSignOut,
                ),
              ] else
                _AccountMenu(
                  profile: null,
                  onEditProfile: onEditProfile,
                  onSignOut: onSignOut,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({
    required this.profile,
    this.onEditProfile,
    this.onSignOut,
  });

  final DriverMotorProfile? profile;
  final VoidCallback? onEditProfile;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return PopupMenuButton<String>(
      tooltip: 'Menu akun',
      icon: CircleAvatar(
        radius: 18,
        backgroundColor: colors.primarySoft,
        foregroundColor: colors.primaryDark,
        child: Text(
          profile?.driverName.isNotEmpty == true
              ? profile!.driverName[0].toUpperCase()
              : 'U',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      onSelected: (value) {
        if (value == 'edit') onEditProfile?.call();
        if (value == 'signout') onSignOut?.call();
      },
      itemBuilder: (context) => [
        if (onEditProfile != null)
          const PopupMenuItem(value: 'edit', child: Text('Edit profil')),
        if (onSignOut != null)
          const PopupMenuItem(value: 'signout', child: Text('Keluar')),
      ],
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      // Material transparan memberi ListTile/ExpansionTile permukaan untuk
      // menggambar latar dan ripple di dalam card berwarna.
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadii.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.eyebrow.copyWith(
              color: color,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    ),
  );
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.color,
    required this.soft,
    this.size = 40,
  });

  final IconData icon;
  final Color color;
  final Color soft;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: soft,
      borderRadius: BorderRadius.circular(size * .29),
    ),
    child: Icon(icon, color: color, size: size * .5),
  );
}

class _PartCard extends StatelessWidget {
  const _PartCard({
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
                  _IconTile(icon: icon, color: statusColor, soft: statusSoft),
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
                    _InfoChip(icon: AppIcons.search, label: 'Pemeriksaan'),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Flexible(
                    child: _StatusBadge(
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
                _SegmentedGauge(
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
                  _RecordButton(prominent: prominent, onPressed: onRecord),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.onPressed, this.prominent = false});

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

class _CollapsiblePartGroup extends StatelessWidget {
  const _CollapsiblePartGroup({
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
    return _CardShell(
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
          leading: _IconTile(icon: icon, color: color, soft: soft),
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
              _CompactPartRow(
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

class _CompactPartRow extends StatelessWidget {
  const _CompactPartRow({
    required this.part,
    required this.icon,
    required this.statusLabel,
    required this.statusColor,
    required this.statusSoft,
    required this.statusIcon,
    required this.onOpen,
    required this.onRecord,
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
              _StatusBadge(
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

class _SegmentedGauge extends StatelessWidget {
  const _SegmentedGauge({
    required this.value,
    required this.color,
    this.height = 8,
    this.segments = 14,
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
          painter: _SegmentedGaugePainter(
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

class _SegmentedGaugePainter extends CustomPainter {
  const _SegmentedGaugePainter({
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
  bool shouldRepaint(covariant _SegmentedGaugePainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.color != color ||
      oldDelegate.track != track ||
      oldDelegate.segments != segments;
}

class _SlimProgressIndicator extends StatelessWidget {
  const _SlimProgressIndicator({
    required this.value,
    required this.color,
    required this.label,
  });

  final double value;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _SegmentedGauge(value: value, color: color, height: 8, segments: 16),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.primaryDark, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: colors.inkSoft,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppType.eyebrow.copyWith(
          color: colors.muted,
          fontSize: 8,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.eyebrow, required this.title});
  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SpeedStripe(color: colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.eyebrow.copyWith(
                  color: colors.primaryDark,
                  fontSize: 9.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: AppType.cardTitle.copyWith(
            color: colors.ink,
            fontSize: 20,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _OdometerField extends StatelessWidget {
  const _OdometerField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.textInputAction,
    required this.validator,
    this.suffixText = 'km',
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputAction textInputAction;
  final String? Function(String?) validator;
  final String suffixText;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.ink,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: TextInputType.number,
          textInputAction: textInputAction,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppType.metric.copyWith(
            color: colors.ink,
            fontSize: 16,
            fontFeatures: const [],
          ),
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffixText,
            prefixIcon: Icon(AppIcons.speed, color: colors.muted, size: 19),
          ),
        ),
      ],
    );
  }
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.infoOutline, color: colors.muted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pengingat ini membantu mencatat jadwal. Ikuti juga rekomendasi buku manual motormu.',
              style: TextStyle(color: colors.muted, fontSize: 12, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: colors.muted, fontSize: 12.5),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppType.metric.copyWith(
              color: colors.ink,
              fontSize: 13,
              fontFeatures: const [],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScreenIntro extends StatelessWidget {
  const _ScreenIntro({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SpeedStripe(color: colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                eyebrow,
                style: AppType.eyebrow.copyWith(
                  color: colors.primaryDark,
                  fontSize: 9.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: AppType.km.copyWith(
            color: colors.ink,
            fontSize: 34,
            height: 1.02,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: TextStyle(color: colors.muted, height: 1.45, fontSize: 13.5),
        ),
      ],
    );
  }
}

class _SpeedStripe extends StatelessWidget {
  const _SpeedStripe({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 3.5,
    height: 12,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

class _CountUpOdometer extends StatelessWidget {
  const _CountUpOdometer({required this.value, required this.style});
  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: reduceMotion ? Duration.zero : AppMotion.odometer,
      curve: Curves.easeOutCubic,
      builder: (context, animated, child) => Text(
        formatNumber(animated.round()),
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: style,
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
    required this.soft,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final Color soft;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadii.sm),
      border: Border.all(color: color.withValues(alpha: 0.32), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          '$value',
          style: AppType.metric.copyWith(
            color: Colors.white,
            fontSize: 14,
            fontFeatures: const [],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _FinishBanner extends StatelessWidget {
  const _FinishBanner({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.safe.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: colors.safe.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.safe.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(AppIcons.checkCircle, color: colors.safeSoft, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.white.withValues(alpha: 0.75),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          _IconTile(
            icon: icon,
            color: colors.primaryDark,
            soft: colors.primarySoft,
            size: 50,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppType.cardTitle.copyWith(color: colors.ink, fontSize: 17),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.muted, height: 1.45, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _SheetHeading extends StatelessWidget {
  const _SheetHeading({
    required this.eyebrow,
    required this.title,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Row(
      children: [
        _IconTile(
          icon: icon,
          color: colors.primaryDark,
          soft: colors.primarySoft,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: AppType.eyebrow.copyWith(
                  color: colors.primaryDark,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: AppType.cardTitle.copyWith(
                  color: colors.ink,
                  fontSize: 21,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroBackdropPainter extends CustomPainter {
  const _HeroBackdropPainter({required this.stripe, required this.accent});
  final Color stripe;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);

    // 1. Garis aksen presisi telemetry di tepi atas instrumen cluster (3px)
    final topBarPaint = Paint()
      ..shader = LinearGradient(
        colors: [stripe, accent.withValues(alpha: 0.8), Colors.transparent],
        stops: const [0.0, 0.45, 0.85],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 3));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 3), topBarPaint);

    // 2. Ambient radial glow halus di sudut kanan atas
    final glowCenter = Offset(size.width * 0.9, size.height * 0.2);
    final glowRadius = size.width * 0.65;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          stripe.withValues(alpha: 0.14),
          stripe.withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius));
    canvas.drawCircle(glowCenter, glowRadius, glowPaint);

    // 3. Lengkung takometer/spedometer digital yang bersih dan presisi
    final gaugeCenter = Offset(size.width * 0.88, size.height * 0.2);
    final outerRing = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(gaugeCenter, 115, outerRing);
    canvas.drawCircle(gaugeCenter, 132, outerRing);

    final telemetryArc = Paint()
      ..color = accent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: gaugeCenter, radius: 124),
      math.pi * 0.65,
      math.pi * 0.45,
      false,
      telemetryArc,
    );
  }

  @override
  bool shouldRepaint(covariant _HeroBackdropPainter oldDelegate) =>
      oldDelegate.stripe != stripe || oldDelegate.accent != accent;
}
