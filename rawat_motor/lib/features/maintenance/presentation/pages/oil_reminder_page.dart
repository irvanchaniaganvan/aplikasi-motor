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
                      ),
                      Expanded(
                        child: switch (_selectedSection) {
                          0 => _buildDashboard(),
                          1 || 2 => _buildHistoryPage(),
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
    selectedIndex: _selectedSection,
    onDestinationSelected: _selectSection,
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.grid_view_outlined),
        selectedIcon: Icon(Icons.grid_view_rounded),
        label: 'Ringkasan',
      ),
      NavigationDestination(
        icon: Icon(Icons.build_outlined),
        selectedIcon: Icon(Icons.build_rounded),
        label: 'Riwayat',
      ),
      NavigationDestination(
        icon: Icon(Icons.speed_outlined),
        selectedIcon: Icon(Icons.speed_rounded),
        label: 'Odometer',
      ),
      NavigationDestination(
        icon: Icon(Icons.handyman_outlined),
        selectedIcon: Icon(Icons.handyman_rounded),
        label: 'Komponen',
      ),
    ],
  );

  String get _sectionTitle => switch (_selectedSection) {
    0 => 'Ringkasan',
    1 || 2 => '',
    _ => 'Komponen & perawatan',
  };

  Widget _buildDashboard() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PageHeader(profile: widget.profile),
            const SizedBox(height: 18),
            _buildProfileCard(),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 820) {
                  return Column(
                    children: [
                      _buildDashboardMaintenanceSummary(),
                      const SizedBox(height: 16),
                      _buildDashboardPrimaryAction(),
                      const SizedBox(height: 16),
                      _buildOilRecommendation(),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 11,
                      child: Column(
                        children: [
                          _buildDashboardMaintenanceSummary(),
                          const SizedBox(height: 12),
                          _buildDashboardPrimaryAction(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(flex: 9, child: _buildOilRecommendation()),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            const _SafetyNote(),
          ],
        ),
      ),
    ),
  );

  Widget _buildHistoryPage() {
    final isService = _selectedSection == 1;
    final title = isService ? 'Riwayat servis' : 'Log odometer';
    final data = _motorData;
    final records = [...?data?.serviceHistory]
      ..sort((a, b) => b.date.compareTo(a.date));
    final entries = [...?data?.odometerLogs]
      ..sort((a, b) => b.date.compareTo(a.date));
    final dates = isService
        ? records.map((record) => record.date).toList()
        : entries.map((entry) => entry.date).toList();
    final groups = <Widget>[];
    final seenMonths = <String>{};

    for (final date in dates) {
      final key = _monthKey(date);
      if (!seenMonths.add(key)) continue;
      groups.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
          child: Text(
            _monthLabel(date),
            style: const TextStyle(
              color: green,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
      if (isService) {
        final monthly = records
            .where((record) => _monthKey(record.date) == key)
            .toList();
        for (var i = 0; i < monthly.length; i++) {
          final record = monthly[i];
          ServiceRecord? previous;
          for (final candidate in records.skip(records.indexOf(record) + 1)) {
            if (candidate.item.toLowerCase() == record.item.toLowerCase()) {
              previous = candidate;
              break;
            }
          }
          groups.add(
            _historyTile(
              icon: Icons.build_circle_outlined,
              title: record.item,
              subtitle: _formatDate(record.date),
              trailing: formatKm(record.odometer),
              detail: previous == null
                  ? 'Servis pertama untuk komponen ini'
                  : 'Servis · +${formatKm(record.odometer - previous.odometer)} sejak servis sebelumnya',
              chip: record.workshop.isEmpty ? null : record.workshop,
            ),
          );
          if (i < monthly.length - 1) groups.add(const Divider(height: 1));
        }
      } else {
        final monthly = entries
            .where((entry) => _monthKey(entry.date) == key)
            .toList();
        for (var i = 0; i < monthly.length; i++) {
          final entry = monthly[i];
          final globalIndex = entries.indexOf(entry);
          final previous = globalIndex + 1 < entries.length
              ? entries[globalIndex + 1]
              : null;
          groups.add(
            _historyTile(
              icon: Icons.speed_rounded,
              title: formatKm(entry.kilometers),
              subtitle: _formatDate(entry.date),
              detail: previous == null
                  ? 'Entri odometer pertama'
                  : '+${formatKm(entry.kilometers - previous.kilometers)} sejak entri sebelumnya',
              chip: _sourceLabel(entry.source),
            ),
          );
          if (i < monthly.length - 1) groups.add(const Divider(height: 1));
        }
      }
    }

    final count = isService ? records.length : entries.length;
    final latestKm = isService
        ? (records.isEmpty ? null : records.first.odometer)
        : (entries.isEmpty ? data?.currentOdometer : entries.first.kilometers);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: ink,
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _historySummary(
                isService: isService,
                count: count,
                latestKm: latestKm,
              ),
              if (!isService) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: data == null ? null : _updateOdometer,
                  icon: const Icon(Icons.speed_rounded),
                  label: const Text('Perbarui odometer'),
                ),
              ],
              const SizedBox(height: 14),
              _CardShell(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: groups.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.inbox_outlined,
                              color: muted,
                              size: 30,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isService
                                  ? 'Riwayat servis masih kosong'
                                  : 'Log odometer masih kosong',
                              style: const TextStyle(
                                color: ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              isService
                                  ? 'Catat servis komponen agar kilometer dan tanggalnya muncul di sini.'
                                  : 'Perbarui odometer untuk mulai melihat perubahan kilometer.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: groups,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historySummary({
    required bool isService,
    required int count,
    int? latestKm,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: line),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: sage,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            isService ? Icons.build_circle_outlined : Icons.speed_rounded,
            color: green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count ${isService ? 'catatan servis' : 'entri odometer'}',
                style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
              ),
              Text(
                latestKm == null
                    ? 'Belum ada data tersimpan'
                    : 'Catatan terbaru · ${formatKm(latestKm)}',
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );

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
    if (data == null) return;
    final controller = TextEditingController(
      text: data.currentOdometer.toString(),
    );
    String? error;
    final updatedKm = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Perbarui odometer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Kilometer saat ini',
                  suffixText: 'km',
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    error!,
                    style: const TextStyle(color: danger, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final km = int.tryParse(controller.text.trim());
                if (km == null || km < data.currentOdometer) {
                  setDialogState(
                    () => error = 'Kilometer baru tidak boleh lebih rendah dari odometer saat ini.',
                  );
                  return;
                }
                Navigator.pop(dialogContext, km);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (updatedKm == null || updatedKm == data.currentOdometer) return;
    final updated = data.copyWith(
      currentOdometer: updatedKm,
      odometerLogs: _appendOdometerLog(data.odometerLogs, updatedKm, 'manual'),
    );
    await _saveComponentData(updated);
    if (mounted && _motorData == updated) {
      _currentController.text = updatedKm.toString();
      _showMessage('Odometer diperbarui ke ${formatKm(updatedKm)}.');
    }
  }

  Widget _historyTile({
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailing,
    String? detail,
    String? chip,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: sage,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: green, size: 18),
        ),
        const SizedBox(width: 10),
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
                      style: const TextStyle(
                        color: ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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
                style: const TextStyle(color: muted, fontSize: 11),
              ),
              if (detail != null) ...[
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: green,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Text(
            trailing,
            style: const TextStyle(
              color: ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    ),
  );

  Widget _buildPartsPage() {
    final data = _motorData;
    final visibleComponents = _visibleParts()
      ..sort(
        (a, b) =>
            _componentUrgency(a, data).compareTo(_componentUrgency(b, data)),
      );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'KOMPONEN & PERAWATAN',
                style: TextStyle(
                  color: green,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Jadwal perawatan',
                style: TextStyle(
                  color: ink,
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Interval adalah perkiraan umum, bukan spesifikasi resmi. Ikuti buku manual atau saran bengkel.',
                style: TextStyle(color: muted, height: 1.5, fontSize: 13),
              ),
              if (widget.profile != null) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.two_wheeler_rounded,
                      label:
                          '${widget.profile!.brand} ${widget.profile!.model}',
                    ),
                    if (_motorTypeLabel != null)
                      _InfoChip(
                        icon: Icons.category_outlined,
                        label: _motorTypeLabel!,
                      ),
                    if (_coolingLabel != null)
                      _InfoChip(
                        icon: Icons.ac_unit_rounded,
                        label: _coolingLabel!,
                      ),
                    if (_frontBrakeLabel != null)
                      _InfoChip(
                        icon: Icons.disc_full_rounded,
                        label: _frontBrakeLabel!,
                      ),
                    _InfoChip(
                      icon: Icons.view_module_outlined,
                      label: '${visibleComponents.length} komponen',
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              if (data == null) ...[
                const _CardShell(
                  child: Text(
                    'Simpan kilometer motor terlebih dahulu untuk menghitung jadwal.',
                    style: TextStyle(color: muted),
                  ),
                ),
              ] else if (_components.isEmpty) ...[
                _CardShell(
                  child: _catalogFailed
                      ? const Text(
                          'Data interval perawatan tidak dapat dimuat. Periksa file data default.',
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
              ] else if (visibleComponents.isEmpty) ...[
                const _CardShell(
                  child: Text(
                    'Belum ada komponen yang cocok dengan profil motor.',
                    style: TextStyle(color: muted),
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
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (final component in visibleComponents)
                          if (_componentSchedule(component, data)?.status ==
                              ComponentScheduleStatus.needsCheck)
                            SizedBox(
                              width: constraints.maxWidth,
                              child: _buildUnrecordedComponentRow(
                                component,
                                data,
                              ),
                            )
                          else
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

  Widget _buildUnrecordedComponentRow(
    MaintenanceComponent component,
    MotorData data,
  ) {
    final state = _findComponentState(data, component.name);
    final interval =
        state?.intervalKmOverride ??
        (component.name == 'Oli mesin'
            ? data.oilInterval
            : component.intervalKm);
    return _CardShell(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showComponentActions(component, state),
        child: Row(
          children: [
            Icon(_componentIcon(component), color: green, size: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    component.name,
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Setiap ${formatKm(interval)} · belum dicatat',
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Catat',
              onPressed: () => _showRecordComponentForm(component),
              icon: const Icon(Icons.add_task_rounded, color: green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentCard(MaintenanceComponent component, MotorData data) {
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
    final statusColor = due
        ? danger
        : soon
        ? warning
        : green;
    final statusBackground = due
        ? dangerSoft
        : soon
        ? warningSoft
        : safeSoft;
    final statusIcon = due
        ? Icons.priority_high_rounded
        : soon
        ? Icons.schedule_rounded
        : schedule.status == ComponentScheduleStatus.needsCheck
        ? Icons.info_outline_rounded
        : Icons.check_rounded;
    final statusText = schedule.status == ComponentScheduleStatus.needsCheck
        ? 'Perlu dicek'
        : switch (schedule.status) {
            ComponentScheduleStatus.safe => 'Aman',
            ComponentScheduleStatus.needsCheck => 'Perlu dicek',
            ComponentScheduleStatus.soon =>
              component.isInspection ? 'Segera cek' : 'Segera ganti',
            ComponentScheduleStatus.due =>
              component.isInspection
                  ? 'Waktunya cek kondisi'
                  : 'Waktunya ganti',
          };
    final intervalText =
        '${component.isInspection ? 'Cek' : 'Ganti'} setiap ${formatKm(interval)}'
        '${months == null ? '' : ' atau $months bulan'}';
    final progress =
        schedule.status == ComponentScheduleStatus.needsCheck ||
            interval <= 0 ||
            lastServicedKm == null
        ? null
        : ((data.currentOdometer - lastServicedKm) / interval)
              .clamp(0.0, 1.0)
              .toDouble();
    final targetKm = schedule.targetKm;
    final remainingKm = schedule.remainingKm;

    return _CardShell(
      padding: const EdgeInsets.all(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showComponentActions(component, state),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_componentIcon(component), color: green, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    component.name,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusBadge(
                  label: statusText,
                  icon: statusIcon,
                  color: statusColor,
                  background: statusBackground,
                ),
                _InfoChip(
                  icon: component.isInspection
                      ? Icons.search_rounded
                      : Icons.build_outlined,
                  label: component.isInspection ? 'Pemeriksaan' : 'Penggantian',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              intervalText,
              style: const TextStyle(color: muted, fontSize: 12, height: 1.45),
            ),
            if (component.note != null) ...[
              const SizedBox(height: 6),
              Text(
                component.note!,
                style: const TextStyle(
                  color: muted,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (progress != null) ...[
              _ProgressBlock(
                value: progress,
                color: statusColor,
                leftLabel: 'Terakhir ${formatKm(lastServicedKm!)}',
                rightLabel: 'Target ${formatKm(targetKm)}',
                caption: remainingKm <= 0
                    ? 'Jadwal sudah tercapai'
                    : '${formatKm(remainingKm)} lagi',
              ),
              if (schedule.daysRemaining != null)
                Text(
                  schedule.daysRemaining! <= 0
                      ? 'Waktu servis tercapai'
                      : '${schedule.daysRemaining} hari lagi',
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _MiniMetric(
                      label: 'Terakhir',
                      value: lastServicedKm == null
                          ? 'Belum ada'
                          : formatKm(lastServicedKm),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: _MiniMetric(label: 'Target', value: '—'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Container(height: 1, color: line),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showRecordComponentForm(component),
                icon: const Icon(Icons.add_task_rounded, size: 18),
                label: const Text('Catat ganti'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _componentIcon(MaintenanceComponent component) {
    final name = component.name.toLowerCase();
    if (name.contains('oli')) return Icons.oil_barrel_outlined;
    if (name.contains('rem')) return Icons.disc_full_rounded;
    if (name.contains('ban')) return Icons.tire_repair_rounded;
    if (name.contains('rantai')) return Icons.link_rounded;
    if (name.contains('busi')) return Icons.electrical_services_rounded;
    if (name.contains('aki') || name.contains('baterai')) {
      return Icons.battery_charging_full_rounded;
    }
    if (name.contains('filter')) return Icons.air_rounded;
    if (name.contains('lampu')) return Icons.lightbulb_outline_rounded;
    return component.isInspection
        ? Icons.search_rounded
        : Icons.build_circle_outlined;
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
    final result = await showDialog<({int km, int? months})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Interval ${component.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
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
                if (monthText.isNotEmpty && (months == null || months <= 0)) {
                  setDialogState(
                    () => error = 'Interval bulan harus lebih dari 0.',
                  );
                  return;
                }
                Navigator.pop(dialogContext, (km: km, months: months));
              },
              child: const Text('Simpan'),
            ),
          ],
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
                child: const Text('Simpan catatan'),
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
              eyebrow: 'JADWAL PERAWATAN',
              title: 'Atur pengingat oli',
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
    final typeLabel = _motorTypeLabel;
    return _CardShell(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: sage,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.two_wheeler_rounded, color: green),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.driverName,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${profile.brand} ${profile.model} · ${profile.year}'
                  '${typeLabel == null ? '' : ' · $typeLabel'}',
                  style: const TextStyle(color: muted, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: surfaceSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, color: green, size: 14),
                SizedBox(width: 5),
                Text(
                  'Aktif',
                  style: TextStyle(
                    color: green,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardMaintenanceSummary() {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in ranked) ...[
          _buildDashboardComponentCard(item.component, data),
          if (item.component.id != ranked.last.component.id)
            const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildDashboardPrimaryAction() {
    final data = _motorData;
    if (data == null) {
      return OutlinedButton.icon(
        onPressed: _showOilReminderSettings,
        icon: const Icon(Icons.tune_rounded, size: 18),
        label: const Text('Ubah interval'),
      );
    }
    final active = _visibleParts()
      ..sort(
        (a, b) =>
            _componentUrgency(a, data).compareTo(_componentUrgency(b, data)),
      );
    final primary = active.isEmpty ? null : active.first;
    if (primary?.name == 'Oli mesin') {
      return OutlinedButton.icon(
        onPressed: _showOilReminderSettings,
        icon: const Icon(Icons.tune_rounded, size: 18),
        label: const Text('Ubah interval'),
      );
    }
    return OutlinedButton.icon(
      onPressed: primary == null
          ? null
          : () => _showComponentActions(
              primary,
              _findComponentState(data, primary.name),
            ),
      icon: const Icon(Icons.open_in_new_rounded, size: 18),
      label: const Text('Detail komponen utama'),
    );
  }

  Widget _buildDashboardComponentCard(
    MaintenanceComponent component,
    MotorData? data,
  ) {
    final state = _findComponentState(data, component.name);
    final schedule = data == null ? null : _componentSchedule(component, data);
    final interval =
        state?.intervalKmOverride ??
        (component.name == 'Oli mesin' && data != null
            ? data.oilInterval
            : component.intervalKm);
    final intervalMonths =
        state?.intervalMonthsOverride ??
        (component.name == 'Oli mesin' && data != null
            ? data.oilIntervalMonths
            : component.intervalMonths);
    final lastServiced =
        state?.lastServicedKm ??
        (component.name == 'Oli mesin' &&
                data != null &&
                data.lastOilOdometer > 0
            ? data.lastOilOdometer
            : null);
    final isDue = schedule?.status == ComponentScheduleStatus.due;
    final isSoon = schedule?.status == ComponentScheduleStatus.soon;
    final color = isDue
        ? danger
        : isSoon
        ? warning
        : green;
    final background = isDue
        ? dangerSoft
        : isSoon
        ? warningSoft
        : safeSoft;
    final label =
        schedule == null ||
            schedule.status == ComponentScheduleStatus.needsCheck
        ? 'Perlu dicek'
        : isDue
        ? (component.isInspection ? 'Waktunya cek' : 'Jatuh tempo')
        : isSoon
        ? 'Segera'
        : 'Aman';
    final remaining = schedule?.remainingKm;
    final progress =
        schedule == null ||
            schedule.status == ComponentScheduleStatus.needsCheck ||
            lastServiced == null ||
            interval <= 0
        ? null
        : ((data!.currentOdometer - lastServiced) / interval)
              .clamp(0.0, 1.0)
              .toDouble();

    return _CardShell(
      color: isDue
          ? const Color(0xFFFFF8F5)
          : isSoon
          ? const Color(0xFFFFFCF4)
          : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(_componentIcon(component), color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  component.name,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusBadge(
                label: label,
                icon: isDue
                    ? Icons.priority_high_rounded
                    : isSoon
                    ? Icons.schedule_rounded
                    : schedule == null
                    ? Icons.info_outline_rounded
                    : Icons.check_rounded,
                color: color,
                background: background,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            schedule == null
                ? 'Catat servis untuk mulai menghitung jadwal.'
                : schedule.status == ComponentScheduleStatus.needsCheck
                ? 'Perlu dicek'
                : remaining! <= 0
                ? 'Terlambat ${formatKm(remaining.abs())}'
                : '${formatKm(remaining)} lagi menuju jadwal berikutnya',
            style: TextStyle(
              color: isDue ? danger : ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Interval ${formatKm(interval)}${intervalMonths == null ? '' : ' · $intervalMonths bulan'}',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          if (progress != null) ...[
            const SizedBox(height: 14),
            _SlimProgressIndicator(
              value: progress,
              color: color,
              label: '${(progress * 100).round()}% interval terpakai',
            ),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => _showRecordComponentForm(component),
            icon: const Icon(Icons.add_task_rounded, size: 18),
            label: const Text('Catat ganti'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final data = _motorData;
    final schedule = data == null
        ? null
        : const OilScheduleCalculator().calculate(data);
    final remaining = schedule?.distanceRemaining;
    final due = schedule?.isDue ?? false;
    final soon = schedule?.status == OilScheduleStatus.soon;
    final statusColor = due
        ? danger
        : soon
        ? warning
        : green;
    final statusBackground = due
        ? dangerSoft
        : soon
        ? warningSoft
        : safeSoft;
    final statusIcon = due
        ? Icons.priority_high_rounded
        : soon
        ? Icons.schedule_rounded
        : Icons.check_rounded;
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
      color: due
          ? const Color(0xFFFFF8F5)
          : soon
          ? const Color(0xFFFFFCF4)
          : Colors.white,
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.oil_barrel_outlined,
                  color: statusColor,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: _StatusBadge(
              label: statusLabel,
              icon: statusIcon,
              color: statusColor,
              background: statusBackground,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            reminder,
            style: TextStyle(
              color: due ? danger : ink,
              fontSize: remaining != null && remaining.abs() >= 100000
                  ? 28
                  : 36,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            style: const TextStyle(color: muted, fontSize: 13, height: 1.45),
          ),
          if (data != null && schedule != null) ...[
            const SizedBox(height: 18),
            _SlimProgressIndicator(
              value: progress,
              color: statusColor,
              label: '${(progress * 100).round()}% interval terpakai',
            ),
          ],
          const SizedBox(height: 20),
          Container(height: 1, color: line),
          const SizedBox(height: 16),
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
                  icon: Icons.speed_rounded,
                  label: '${data.odometerLogs.length} log odometer',
                ),
                _InfoChip(
                  icon: Icons.build_outlined,
                  label: '${data.serviceHistory.length} catatan servis',
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: data == null ? null : _recordOilChange,
            icon: const Icon(Icons.check_circle_outline, size: 19),
            label: const Text('Catat ganti oli'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data == null
                ? 'Tombol aktif setelah data motor disimpan.'
                : 'Ganti oli terakhir dicatat di ${formatKm(data.lastOilOdometer)}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildOilRecommendation() {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            eyebrow: 'PANDUAN UMUM',
            title: 'Spesifikasi oli',
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: surfaceSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: sage,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.opacity_rounded, color: green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _recommendedOilTitle,
                        style: const TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Contoh rekomendasi. Selalu cocokkan spesifikasi dengan buku manual motor.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.open_in_new_rounded, size: 17),
            label: const Text('Lihat contoh produk'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tautan produk belum diaktifkan.',
            style: TextStyle(color: muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String get _recommendedOilTitle {
    final profile = widget.profile;
    final isScooter =
        profile?.model.toLowerCase().contains('matic') == true ||
        profile?.model.toLowerCase().contains('gear') == true ||
        profile?.model.toLowerCase().contains('scoopy') == true ||
        profile?.model.toLowerCase().contains('beat') == true;
    return isScooter ? 'Contoh oli matic 10W-40' : 'Contoh oli mesin 10W-40';
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'RINGKASAN PERAWATAN',
        style: TextStyle(
          color: green,
          fontSize: 10,
          letterSpacing: 1.3,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        profile == null ? 'Kondisi motormu' : 'Hai, ${profile!.driverName}!',
        style: const TextStyle(
          color: ink,
          fontSize: 28,
          height: 1.12,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Jadwal dan catatan perawatan dalam satu tempat.',
        style: TextStyle(color: muted, height: 1.45, fontSize: 14),
      ),
    ],
  );
}

class _AppSidebar extends StatelessWidget {
  const _AppSidebar({
    required this.selected,
    required this.onSelect,
    this.profile,
  });
  final int selected;
  final ValueChanged<int> onSelect;
  final DriverMotorProfile? profile;

  @override
  Widget build(BuildContext context) => Container(
    width: 252,
    decoration: const BoxDecoration(
      color: Color(0xFFF1EFE8),
      border: Border(right: BorderSide(color: line)),
    ),
    padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _BrandMark(),
              SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rawatin',
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Perawatan motor',
                    style: TextStyle(color: muted, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 34),
        const Padding(
          padding: EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            'NAVIGASI',
            style: TextStyle(
              color: muted,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _navItem(0, Icons.grid_view_rounded, 'Ringkasan'),
        _navItem(1, Icons.build_outlined, 'Riwayat servis'),
        _navItem(2, Icons.speed_rounded, 'Log odometer'),
        _navItem(3, Icons.handyman_outlined, 'Komponen'),
        const Spacer(),
        if (profile != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: line),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: sage,
                  foregroundColor: green,
                  child: Text(
                    profile!.driverName.isEmpty
                        ? '?'
                        : profile!.driverName[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile!.driverName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${profile!.brand} ${profile!.model}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _navItem(int index, IconData icon, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: ListTile(
      selected: selected == index,
      selectedTileColor: sage,
      selectedColor: green,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      minLeadingWidth: 22,
      leading: Icon(icon, color: selected == index ? green : muted, size: 20),
      title: Text(
        label,
        style: TextStyle(
          color: selected == index ? green : ink,
          fontWeight: selected == index ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
      onTap: () => onSelect(index),
      dense: true,
    ),
  );
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

  @override
  Widget build(BuildContext context) => Container(
    height: 72,
    padding: const EdgeInsets.symmetric(horizontal: 28),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: line)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'RAWATIN',
                style: TextStyle(
                  color: green,
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (profile != null) ...[
          const SizedBox(width: 12),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Text(
                    '${profile!.brand} ${profile!.model}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded, color: muted),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  profile!.driverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String>(
                tooltip: 'Menu akun',
                icon: CircleAvatar(
                  radius: 18,
                  backgroundColor: sage,
                  foregroundColor: green,
                  child: Text(
                    profile!.driverName.isNotEmpty
                        ? profile!.driverName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                onSelected: (value) {
                  if (value == 'edit') onEditProfile?.call();
                  if (value == 'signout') onSignOut?.call();
                },
                itemBuilder: (context) => [
                  if (onEditProfile != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit profil'),
                    ),
                  if (onSignOut != null)
                    const PopupMenuItem(
                      value: 'signout',
                      child: Text('Keluar'),
                    ),
                ],
              ),
            ],
          ),
        ] else ...[
          PopupMenuButton<String>(
            tooltip: 'Menu akun',
            icon: const CircleAvatar(
              radius: 18,
              backgroundColor: sage,
              foregroundColor: green,
              child: Text('U', style: TextStyle(fontWeight: FontWeight.w800)),
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
          ),
        ],
      ],
    ),
  );
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(22),
  });
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A20352C),
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
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
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({
    required this.value,
    required this.color,
    required this.leftLabel,
    required this.rightLabel,
    required this.caption,
  });

  final double value;
  final Color color;
  final String leftLabel;
  final String rightLabel;
  final String caption;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0).toDouble(),
          minHeight: 8,
          backgroundColor: line,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: Text(
              leftLabel,
              style: const TextStyle(color: muted, fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            rightLabel,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        caption,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
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
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0).toDouble(),
          minHeight: 5,
          backgroundColor: line,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        label,
        textAlign: TextAlign.end,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: muted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(
          color: ink,
          fontSize: 12,
          fontWeight: FontWeight.w700,
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: surfaceSoft,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: green, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: surfaceSoft,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: muted,
        fontSize: 9,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.eyebrow, required this.title});
  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: const TextStyle(
          color: green,
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        title,
        style: const TextStyle(
          color: ink,
          fontSize: 19,
          height: 1.25,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: ink,
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
        decoration: InputDecoration(
          hintText: hint,
          suffixText: suffixText,
          prefixIcon: const Icon(Icons.speed_rounded, color: muted, size: 19),
        ),
      ),
    ],
  );
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: surfaceSoft,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: muted, size: 18),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Pengingat ini membantu mencatat jadwal. Ikuti juga rekomendasi buku manual motormu.',
            style: TextStyle(color: muted, fontSize: 12, height: 1.45),
          ),
        ),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: muted, fontSize: 12.5),
        ),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(
            color: ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}
