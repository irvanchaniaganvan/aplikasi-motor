import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:convert';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/rawatin_logo.dart';
import '../../domain/entities/driver_motor_profile.dart';
import '../../domain/entities/motor_model_catalog.dart';
import '../../../maintenance/domain/entities/maintenance_motor_catalog.dart';
import '../../../maintenance/data/repositories/default_interval_repository.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({
    required this.onSave,
    this.initialProfile,
    this.catalog,
    super.key,
  });
  final Future<void> Function(DriverMotorProfile profile) onSave;
  final DriverMotorProfile? initialProfile;
  final MotorModelCatalog? catalog;

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController(text: DateTime.now().year.toString());
  String? _motorType;
  String? _cooling;
  String? _frontBrake;
  late String _profileId;
  MotorModelCatalog _catalog = const MotorModelCatalog(brands: []);
  MotorBrand? _selectedBrand;
  MotorModel? _selectedModel;
  List<MaintenanceMotor> _maintenanceMotors = const [];
  MaintenanceMotor? _selectedMaintenanceMotor;
  bool _manualMotor = true;
  bool _typeEdited = false;
  bool _coolingEdited = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    _loadMaintenanceMotors();
    final profile = widget.initialProfile;
    _profileId = profile?.id.isNotEmpty == true
        ? profile!.id
        : DateTime.now().microsecondsSinceEpoch.toString();
    if (profile != null) {
      _name.text = profile.driverName;
      _brand.text = profile.brand;
      _model.text = profile.model;
      _year.text = profile.year.toString();
      _motorType = profile.motorType;
      _cooling = profile.cooling;
      _frontBrake = profile.frontBrake;
      _manualMotor = true;
    }
  }

  Future<void> _loadCatalog() async {
    try {
      final catalog =
          widget.catalog ??
          MotorModelCatalog.fromJson(
            jsonDecode(await rootBundle.loadString('data/model_motor.json'))
                as Map<String, dynamic>,
          );
      if (mounted) setState(() => _catalog = catalog);
    } catch (_) {
      // Form manual tetap dapat digunakan jika asset katalog belum terbaca.
    }
  }

  Future<void> _loadMaintenanceMotors() async {
    try {
      final catalog = await const DefaultIntervalRepository().loadMotors();
      if (mounted) setState(() => _maintenanceMotors = catalog.motors);
    } catch (_) {}
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        DriverMotorProfile(
          id: _profileId,
          driverName: _name.text.trim(),
          brand: _brand.text.trim(),
          model: _model.text.trim(),
          year: int.parse(_year.text),
          motorType: _motorType,
          cooling: _cooling,
          frontBrake: _frontBrake,
          maintenanceMotorId: _selectedMaintenanceMotor?.id,
          transmission: _selectedMaintenanceMotor?.transmission,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil gagal disimpan. Coba lagi.')),
        );
      }
    }
  }

  MaintenanceMotor? _findMaintenanceMotor(String modelName) {
    final normalized = modelName.toLowerCase();
    for (final motor in _maintenanceMotors) {
      if (normalized == motor.name.toLowerCase() ||
          (motor.id == 'yamaha-mio-gear-2024' && normalized.contains('gear')) ||
          (motor.id == 'honda-beat-k0j' && normalized.contains('beat')) ||
          (motor.id == 'honda-vario-125-kzr' &&
              normalized.contains('vario 125'))) {
        return motor;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const RawatinLogo(size: 42),
                      const SizedBox(width: 11),
                      const Text(
                        'Rawatin',
                        style: TextStyle(
                          color: ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE9EFE3), Color(0xFFF7F2E9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MULAI PERJALANAN',
                                style: TextStyle(
                                  color: green,
                                  letterSpacing: 1.2,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 9),
                              const Text(
                                'Kenalan dulu,\nyuk.',
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 30,
                                  height: 1.08,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Biar pengingat perawatan lebih pas untuk kamu dan motor kesayanganmu.',
                                style: TextStyle(
                                  color: ink.withValues(alpha: 0.72),
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.two_wheeler_rounded,
                          color: green,
                          size: 68,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _StepLabel(),
                        const SizedBox(height: 18),
                        _field(
                          _name,
                          'Nama pengendara',
                          'Contoh: Irvan',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 14),
                        if (_catalog.brands.isNotEmpty) ...[
                          _searchDropdown(
                            label: 'Merek motor',
                            hint: 'Cari atau pilih merek',
                            value: _selectedBrand?.name,
                            options: [
                              ..._catalog.brands.map((brand) => brand.name),
                              'Lainnya',
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedBrand = _catalog.brands
                                    .where((b) => b.name == value)
                                    .firstOrNull;
                                _selectedModel = null;
                                _model.clear();
                                _manualMotor = value == 'Lainnya';
                                _brand.text = _manualMotor ? '' : value ?? '';
                              });
                            },
                          ),
                          if (_selectedBrand != null) ...[
                            const SizedBox(height: 14),
                            _searchDropdown(
                              label: 'Model motor',
                              hint: 'Cari atau pilih model',
                              value: _selectedModel?.name,
                              options: [
                                ..._selectedBrand!.models.map(
                                  (model) => model.searchLabel,
                                ),
                                'Lainnya',
                              ],
                              onChanged: (value) {
                                if (value == 'Lainnya') {
                                  setState(() {
                                    _manualMotor = true;
                                    _selectedModel = null;
                                    _brand.text = _selectedBrand!.name;
                                    _model.clear();
                                  });
                                  return;
                                }
                                final model = _selectedBrand!.models
                                    .where((m) => m.searchLabel == value)
                                    .firstOrNull;
                                setState(() {
                                  _selectedModel = model;
                                  _manualMotor = model == null;
                                  _selectedMaintenanceMotor =
                                      _findMaintenanceMotor(model?.name ?? '');
                                  if (model != null) {
                                    _model.text = model.name;
                                    _motorType = model.motorType;
                                    _cooling = model.cooling;
                                    if (_selectedMaintenanceMotor != null) {
                                      _cooling =
                                          _selectedMaintenanceMotor!.cooling;
                                    }
                                    _typeEdited = false;
                                    _coolingEdited = false;
                                  }
                                });
                              },
                            ),
                          ],
                        ],
                        if (_manualMotor) ...[
                          if (_catalog.brands.isNotEmpty)
                            const SizedBox(height: 14),
                          _field(
                            _brand,
                            'Merek motor',
                            'Contoh: Yamaha',
                            icon: Icons.two_wheeler_outlined,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            _model,
                            'Model motor',
                            'Contoh: Gear 125',
                            icon: Icons.directions_bike_outlined,
                          ),
                        ],
                        const SizedBox(height: 14),
                        _field(
                          _year,
                          'Tahun motor',
                          'Contoh: 2024',
                          digitsOnly: true,
                          icon: Icons.calendar_month_outlined,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _dropdown(
                                value: _motorType,
                                label: 'Jenis motor',
                                hint: 'Pilih jenis motor',
                                icon: Icons.category_outlined,
                                items: const {
                                  'matic': 'Matic',
                                  'bebek': 'Bebek',
                                  'sport': 'Sport',
                                },
                                onChanged: (value) => setState(() {
                                  _motorType = value;
                                  if (_selectedModel != null) {
                                    _typeEdited = true;
                                  }
                                }),
                              ),
                            ),
                            if (_selectedModel != null) ...[
                              const SizedBox(width: 8),
                              _autoChip(_typeEdited),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _dropdown(
                                value: _cooling,
                                label: 'Sistem pendingin',
                                hint: 'Pilih pendingin',
                                icon: Icons.ac_unit_rounded,
                                items: const {
                                  'udara': 'Udara',
                                  'oli': 'Oli',
                                  'cair': 'Cair',
                                  'TODO_VERIFY': 'Perlu diverifikasi',
                                },
                                onChanged: (value) => setState(() {
                                  _cooling = value;
                                  if (_selectedModel != null) {
                                    _coolingEdited = true;
                                  }
                                }),
                              ),
                            ),
                            if (_selectedModel != null) ...[
                              const SizedBox(width: 8),
                              _autoChip(_coolingEdited),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14),
                        _dropdown(
                          value: _frontBrake,
                          label: 'Rem depan',
                          hint: 'Pilih rem depan',
                          icon: Icons.disc_full_rounded,
                          items: const {'cakram': 'Cakram', 'tromol': 'Tromol'},
                          onChanged: (value) =>
                              setState(() => _frontBrake = value),
                        ),
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: _saving ? null : _submit,
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward_rounded),
                          label: Text(
                            _saving ? 'Menyimpan…' : 'Simpan dan lanjutkan',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 14, color: muted),
                      SizedBox(width: 6),
                      Text(
                        'Profil tersimpan aman di perangkat ini',
                        style: TextStyle(color: muted, fontSize: 12),
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

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
    bool digitsOnly = false,
    IconData? icon,
  }) => TextFormField(
    controller: controller,
    keyboardType: digitsOnly ? TextInputType.number : TextInputType.text,
    inputFormatters: digitsOnly
        ? [FilteringTextInputFormatter.digitsOnly]
        : null,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: muted, size: 20),
    ),
    validator: (value) {
      if (value == null || value.trim().isEmpty) {
        return 'Bagian ini perlu diisi.';
      }
      if (digitsOnly) {
        final year = int.tryParse(value);
        if (year == null || year < 1950 || year > DateTime.now().year + 1) {
          return 'Masukkan tahun motor yang valid.';
        }
      }
      return null;
    },
  );

  Widget _dropdown({
    required String? value,
    required String label,
    required String hint,
    required IconData icon,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: muted, size: 20),
    ),
    hint: Text(hint),
    items: [
      for (final entry in items.entries)
        DropdownMenuItem(value: entry.key, child: Text(entry.value)),
    ],
    onChanged: onChanged,
    validator: (selected) =>
        selected == null ? 'Bagian ini perlu diisi.' : null,
  );

  Widget _searchDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) => FormField<String>(
    initialValue: value,
    validator: (selected) =>
        selected == null ? 'Bagian ini perlu diisi.' : null,
    builder: (field) => InkWell(
      onTap: () async {
        final selected = await showDialog<String>(
          context: context,
          builder: (context) =>
              _SearchOptionDialog(title: label, options: options),
        );
        if (selected != null) {
          field.didChange(selected);
          onChanged(selected);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.search_rounded, color: muted, size: 20),
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
          errorText: field.errorText,
        ),
        child: Text(
          value ?? hint,
          style: TextStyle(color: value == null ? muted : ink),
        ),
      ),
    ),
  );

  Widget _autoChip(bool edited) => Chip(
    label: Text(edited ? 'Manual' : 'Otomatis'),
    avatar: Icon(
      edited ? Icons.edit_rounded : Icons.auto_awesome_rounded,
      size: 15,
    ),
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
  );
}

class _SearchOptionDialog extends StatefulWidget {
  const _SearchOptionDialog({required this.title, required this.options});
  final String title;
  final List<String> options;

  @override
  State<_SearchOptionDialog> createState() => _SearchOptionDialogState();
}

class _SearchOptionDialogState extends State<_SearchOptionDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where((item) => item.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return AlertDialog(
      title: Text('Cari ${widget.title.toLowerCase()}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Ketik untuk mencari',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final option in filtered)
                    ListTile(
                      title: Text(option),
                      onTap: () => Navigator.pop(context, option),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 27,
        height: 27,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: sage, shape: BoxShape.circle),
        child: const Text(
          '1',
          style: TextStyle(color: green, fontWeight: FontWeight.w800),
        ),
      ),
      const SizedBox(width: 10),
      const Text(
        'Profil pengendara & motor',
        style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ],
  );
}
