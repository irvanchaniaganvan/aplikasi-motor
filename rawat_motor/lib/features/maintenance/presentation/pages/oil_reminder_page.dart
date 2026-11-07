import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_labels.dart';
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
import 'history_view.dart';
import 'oil_guide_page.dart';
import '../widgets/common_widgets.dart';
import '../widgets/part_widgets.dart';
import '../widgets/app_shell.dart';
import '../widgets/dashboard_widgets.dart';

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
                  RawatinSidebar(
                    selected: _selectedSection,
                    onSelect: _selectSection,
                    profile: widget.profile,
                    onOpenSettings: _showOilReminderSettings,
                  ),
                Expanded(
                  child: Column(
                    children: [
                      RawatinTopBar(
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
                          1 => HistoryView(data: _motorData),
                          2 => HistoryView(data: _motorData),
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
              painter: HeroBackdropPainter(
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
                        child: CountUpOdometer(
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
                      HeroStat(
                        label: 'Waktunya',
                        value: due,
                        color: colors.due,
                        soft: colors.dueSoft,
                        icon: AppIcons.due,
                      ),
                      HeroStat(
                        label: 'Segera',
                        value: soon,
                        color: colors.soon,
                        soft: colors.soonSoft,
                        icon: AppIcons.soon,
                      ),
                      HeroStat(
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
                  const FinishBanner(
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
            DashboardHeader(profile: widget.profile),
            const SizedBox(height: AppSpacing.lg),
            _buildProfileCard(),
            const SizedBox(height: AppSpacing.lg),
            _buildOdometerHero(),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: RawatinSectionHeading(
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
            const RawatinSafetyNote(),
          ],
        ),
      ),
    ),
  );

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
                  const RawatinSheetHeading(
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
              const RawatinScreenIntro(
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
                    RawatinInfoChip(
                      icon: AppIcons.vehicle,
                      label:
                          '${widget.profile!.brand} ${widget.profile!.model}',
                    ),
                    if (_motorTypeLabel != null)
                      RawatinInfoChip(
                        icon: AppIcons.category,
                        label: _motorTypeLabel!,
                      ),
                    if (_coolingLabel != null)
                      RawatinInfoChip(icon: AppIcons.cooling, label: _coolingLabel!),
                    if (_frontBrakeLabel != null)
                      RawatinInfoChip(icon: AppIcons.brake, label: _frontBrakeLabel!),
                    RawatinInfoChip(
                      icon: AppIcons.grid,
                      label: '${visibleComponents.length} komponen',
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (data == null) ...[
                RawatinCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const RawatinSectionHeading(
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
                RawatinCard(
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
                RawatinCard(
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

    return PartCard(
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
              if (component.name == 'Oli mesin' ||
                  component.name == 'Oli gardan') ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _openOilGuide();
                  },
                  icon: const Icon(AppIcons.oil),
                  label: const Text('Panduan oli'),
                ),
              ],
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
                          formatShortDate(record.date),
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

  void _openOilGuide() {
    final motor = _selectedMaintenanceMotor;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => OilGuidePage(
          motor: motor,
          profile: widget.profile,
          onRecordOilService: _openOilChangeForm,
        ),
      ),
    );
  }

  /// Membuka form "Catat ganti" oli mesin, terlepas dari kartu mana
  /// yang dipakai untuk membuka panduan oli.
  void _openOilChangeForm() {
    for (final component in _components) {
      final name = component.name.toLowerCase();
      if (name == 'oli mesin' || name == 'oli-mesin') {
        _showRecordComponentForm(component);
        return;
      }
    }
    _showMessage('Komponen oli mesin belum tersedia.');
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
    return RawatinCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RawatinSectionHeading(
              eyebrow: 'PENGATURAN MOTOR',
              title: 'Data awal dan interval',
            ),
            const SizedBox(height: 22),
            RawatinOdometerField(
              controller: _currentController,
              label: 'Kilometer saat ini',
              hint: 'Contoh: 12500',
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  requiredNumber(value, 'Isi kilometer saat ini.'),
            ),
            const SizedBox(height: 16),
            RawatinOdometerField(
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
            RawatinOdometerField(
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
            RawatinOdometerField(
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
          RawatinIconTile(
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
          RawatinStatusBadge(
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
          CollapsiblePartGroup(
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
          CollapsiblePartGroup(
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
        RawatinCard(
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
              leading: RawatinIconTile(
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

    return RawatinCard(
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: RawatinSectionHeading(
                  eyebrow: 'JADWAL OLI',
                  title: 'Ganti oli berikutnya',
                ),
              ),
              RawatinIconTile(
                icon: AppIcons.oil,
                color: statusColor,
                soft: statusBackground,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: RawatinStatusBadge(
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
            SlimProgressIndicator(
              value: progress,
              color: statusColor,
              label: '${(progress * 100).round()}% interval terpakai',
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Divider(color: colors.line),
          const SizedBox(height: AppSpacing.lg),
          RawatinSummaryRow(
            label: 'Odometer sekarang',
            value: data == null ? '—' : formatKm(data.currentOdometer),
          ),
          const SizedBox(height: 12),
          RawatinSummaryRow(
            label: 'Ganti oli terakhir',
            value: data == null ? '—' : formatKm(data.lastOilOdometer),
          ),
          const SizedBox(height: 12),
          RawatinSummaryRow(
            label: 'Tanggal servis',
            value: data?.lastOilChangeDate == null
                ? 'Belum dicatat'
                : formatShortDate(data!.lastOilChangeDate!),
          ),
          const SizedBox(height: 12),
          RawatinSummaryRow(
            label: 'Target berikutnya',
            value: schedule == null ? '—' : formatKm(schedule.nextOdometer),
          ),
          if (schedule?.nextDate != null) ...[
            const SizedBox(height: 12),
            RawatinSummaryRow(
              label: 'Target berdasarkan waktu',
              value: formatShortDate(schedule!.nextDate!),
            ),
            const SizedBox(height: 12),
            RawatinSummaryRow(
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
                RawatinInfoChip(
                  icon: AppIcons.speed,
                  label: '${data.odometerLogs.length} log odometer',
                ),
                RawatinInfoChip(
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
}
