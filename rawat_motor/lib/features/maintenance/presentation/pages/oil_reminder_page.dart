import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/motor_data.dart';
import '../../domain/use_cases/load_motor_data.dart';
import '../../domain/use_cases/save_motor_data.dart';
import '../../domain/services/oil_schedule_calculator.dart';
import '../../../profile/domain/entities/driver_motor_profile.dart';

class OilReminderPage extends StatefulWidget {
  const OilReminderPage({
    required this.loadMotorData,
    required this.saveMotorData,
    this.profile,
    this.onEditProfile,
    this.onSignOut,
    super.key,
  });

  final LoadMotorData loadMotorData;
  final SaveMotorData saveMotorData;
  final DriverMotorProfile? profile;
  final VoidCallback? onEditProfile;
  final VoidCallback? onSignOut;

  @override
  State<OilReminderPage> createState() => _OilReminderPageState();
}

class _OilReminderPageState extends State<OilReminderPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _lastOilController = TextEditingController();
  final _intervalController = TextEditingController(text: '2000');
  MotorData? _motorData;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
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
    super.dispose();
  }

  Future<void> _saveMotorData() async {
    if (!_formKey.currentState!.validate()) return;
    final previousDate = _motorData?.lastOilChangeDate;
    final data = MotorData(
        currentOdometer: int.parse(_currentController.text),
        lastOilOdometer: int.parse(_lastOilController.text),
        oilInterval: int.parse(_intervalController.text),
        lastOilChangeDate: previousDate,
      );
    setState(() => _isSaving = true);
    try {
      await widget.saveMotorData(data);
      if (!mounted) return;
      setState(() => _motorData = data);
    } catch (_) {
      _showMessage('Data gagal disimpan. Periksa ruang penyimpanan perangkat.');
      return;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
    FocusScope.of(context).unfocus();
    _showMessage('Data motor siap dipakai untuk menghitung jadwal.');
  }

  Future<void> _recordOilChange() async {
    final data = _motorData;
    if (data == null) return;
    final updated = data.copyWith(
      lastOilOdometer: data.currentOdometer,
      lastOilChangeDate: DateTime.now(),
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PageHeader(
                    profile: widget.profile,
                    onEditProfile: widget.onEditProfile,
                    onSignOut: widget.onSignOut,
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(builder: (context, constraints) {
                    if (constraints.maxWidth < 620) {
                      return Column(children: [_buildProfileCard(), const SizedBox(height: 16), _buildStatusCard(), const SizedBox(height: 16), _buildOilRecommendation(), const SizedBox(height: 16), _buildFormCard()]);
                    }
                    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Column(children: [_buildProfileCard(), const SizedBox(height: 16), _buildStatusCard()])),
                      const SizedBox(width: 16),
                      Expanded(child: Column(children: [_buildFormCard(), const SizedBox(height: 16), _buildOilRecommendation()])),
                    ]);
                  }),
                  const SizedBox(height: 18),
                  const _SafetyNote(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return _CardShell(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeading(eyebrow: 'JADWAL PERAWATAN', title: 'Atur pengingat oli'),
            const SizedBox(height: 22),
            _OdometerField(controller: _currentController, label: 'Kilometer saat ini', hint: 'Contoh: 12500', textInputAction: TextInputAction.next, validator: (value) => requiredNumber(value, 'Isi kilometer saat ini.')),
            const SizedBox(height: 16),
            _OdometerField(
              controller: _lastOilController,
              label: 'Ganti oli terakhir di kilometer',
              hint: 'Contoh: 10000',
              textInputAction: TextInputAction.next,
              validator: (value) {
                final error = requiredNumber(value, 'Isi kilometer ganti oli terakhir.');
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
              hint: '2000',
              textInputAction: TextInputAction.done,
              validator: (value) {
                final error = requiredNumber(value, 'Isi jarak pengingat.');
                if (error != null) return error;
                if (int.parse(value!.trim()) <= 0) return 'Jarak pengingat harus lebih besar dari 0 km.';
                return null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSaving ? null : _saveMotorData,
              style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), textStyle: const TextStyle(fontWeight: FontWeight.w700)),
              child: Text(_isSaving ? 'Menyimpan…' : 'Simpan data motor'),
            ),
            const SizedBox(height: 12),
            const Text('Data disimpan di perangkat ini dan tidak dikirim ke server.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final profile = widget.profile;
    if (profile == null) return const SizedBox.shrink();
    return _CardShell(child: Row(children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: sage, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.two_wheeler_rounded, color: green)),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(profile.driverName, style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 3),
        Text('${profile.brand} ${profile.model} · ${profile.year}', style: const TextStyle(color: muted, fontSize: 13)),
      ])),
    ]));
  }

  Widget _buildStatusCard() {
    final data = _motorData;
    final schedule = data == null ? null : const OilScheduleCalculator().calculate(data);
    final remaining = schedule?.distanceRemaining;
    final due = schedule?.isDue ?? false;
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
            ? remaining == 0 ? 'Jadwal ganti oli sudah tercapai.' : 'Jadwal ganti oli sudah terlewat.'
            : 'menuju jadwal ganti oli berikutnya';

    return _CardShell(
      color: due ? const Color(0xFFFFF8F5) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: _SectionHeading(eyebrow: 'PENGINGAT BERIKUTNYA', title: 'Ganti oli')),
              Icon(Icons.oil_barrel_outlined, color: due ? danger : green, size: 25),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(color: due ? const Color(0xFFF5E4DF) : sage, borderRadius: BorderRadius.circular(30)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(due ? Icons.priority_high_rounded : Icons.check_rounded, color: due ? danger : green, size: 16),
              const SizedBox(width: 6),
              Text(due ? 'Perlu diperhatikan' : 'Jadwal terpantau', style: TextStyle(color: due ? danger : green, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 14),
          Text(reminder, style: TextStyle(color: due ? danger : ink, fontSize: remaining != null && remaining.abs() >= 100000 ? 26 : 32, height: 1.15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(caption, style: const TextStyle(color: muted, fontSize: 14)),
          const SizedBox(height: 22),
          Container(height: 1, color: line),
          const SizedBox(height: 16),
          _SummaryRow(label: 'Odometer sekarang', value: data == null ? '—' : formatKm(data.currentOdometer)),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Ganti oli terakhir', value: data == null ? '—' : formatKm(data.lastOilOdometer)),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Tanggal servis', value: data?.lastOilChangeDate == null ? 'Belum dicatat' : _formatDate(data!.lastOilChangeDate!)),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Target berikutnya', value: schedule == null ? '—' : formatKm(schedule.nextOdometer)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: data == null ? null : _recordOilChange,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Catat ganti oli'),
            style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), textStyle: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 10),
          Text(data == null ? 'Tombol aktif setelah data motor disimpan.' : 'Ganti oli terakhir dicatat di ${formatKm(data.lastOilOdometer)}.', textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildOilRecommendation() {
    return _CardShell(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionHeading(eyebrow: 'REKOMENDASI DUMMY', title: 'Pilihan oli'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: const Color(0xFFF5F6F0), borderRadius: BorderRadius.circular(17)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: sage, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.opacity_rounded, color: green)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_recommendedOilTitle, style: const TextStyle(color: ink, fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text('Contoh rekomendasi. Selalu cocokkan spesifikasi dengan buku manual motor.', style: TextStyle(color: muted, fontSize: 12, height: 1.4)),
            ])),
          ]),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.open_in_new_rounded, size: 17),
          label: const Text('Lihat contoh produk'),
          style: OutlinedButton.styleFrom(foregroundColor: green, minimumSize: const Size.fromHeight(44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
        ),
        const SizedBox(height: 8),
        const Text('Tautan produk belum diaktifkan.', style: TextStyle(color: muted, fontSize: 11)),
      ]),
    );
  }

  String get _recommendedOilTitle {
    final profile = widget.profile;
    final isScooter = profile?.model.toLowerCase().contains('matic') == true ||
        profile?.model.toLowerCase().contains('gear') == true ||
        profile?.model.toLowerCase().contains('scoopy') == true ||
        profile?.model.toLowerCase().contains('beat') == true;
    return isScooter ? 'Contoh oli matic 10W-40' : 'Contoh oli mesin 10W-40';
  }

  String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({this.profile, this.onEditProfile, this.onSignOut});
  final DriverMotorProfile? profile;
  final VoidCallback? onEditProfile;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.route_rounded, color: Colors.white)), const SizedBox(width: 11), const Text('Rawat Motor', style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w800)), const Spacer(), if (onEditProfile != null) IconButton(tooltip: 'Edit profil', onPressed: onEditProfile, icon: const Icon(Icons.edit_outlined, color: green)), if (onSignOut != null) IconButton(tooltip: 'Keluar dari akun demo', onPressed: onSignOut, icon: const Icon(Icons.logout_rounded, color: muted))]),
          const SizedBox(height: 24),
          const Text('DASHBOARD PERAWATAN', style: TextStyle(color: green, fontSize: 10, letterSpacing: 1.3, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          Text(profile == null ? 'Hai, siap jalan?' : 'Hai, ${profile!.driverName}!', style: const TextStyle(color: ink, fontSize: 30, height: 1.1, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Pantau jadwal servis motormu di satu tempat.', style: TextStyle(color: muted, height: 1.5, fontSize: 14)),
        ],
      );
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, this.color = Colors.white});
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24), border: Border.all(color: line), boxShadow: const [BoxShadow(color: Color(0x0B20352C), blurRadius: 24, offset: Offset(0, 8))]), child: child);
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.eyebrow, required this.title});
  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(eyebrow, style: const TextStyle(color: green, fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(title, style: const TextStyle(color: ink, fontSize: 19, fontWeight: FontWeight.w800))])),
        ],
      );
}

class _OdometerField extends StatelessWidget {
  const _OdometerField({required this.controller, required this.label, required this.hint, required this.textInputAction, required this.validator});
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputAction textInputAction;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: TextInputType.number,
            textInputAction: textInputAction,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(hintText: hint, suffixText: 'km', prefixIcon: const Icon(Icons.speed_rounded, color: muted, size: 19)),
          ),
        ],
      );
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFFF0EEE7), borderRadius: BorderRadius.circular(16)),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline_rounded, color: muted, size: 18),
          SizedBox(width: 10),
          Expanded(child: Text('Pengingat ini membantu mencatat jadwal. Ikuti juga rekomendasi buku manual motormu.', style: TextStyle(color: muted, fontSize: 12, height: 1.45))),
        ]),
      );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: const TextStyle(color: muted, fontSize: 13)), const SizedBox(width: 12), Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w700)))],
      );
}
