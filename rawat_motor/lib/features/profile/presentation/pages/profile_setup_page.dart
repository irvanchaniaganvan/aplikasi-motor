import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/driver_motor_profile.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({required this.onSave, this.initialProfile, super.key});
  final Future<void> Function(DriverMotorProfile profile) onSave;
  final DriverMotorProfile? initialProfile;

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController(text: DateTime.now().year.toString());
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    if (profile != null) {
      _name.text = profile.driverName;
      _brand.text = profile.brand;
      _model.text = profile.model;
      _year.text = profile.year.toString();
    }
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
      await widget.onSave(DriverMotorProfile(
        driverName: _name.text.trim(),
        brand: _brand.text.trim(),
        model: _model.text.trim(),
        year: int.parse(_year.text),
      ));
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil gagal disimpan. Coba lagi.')),
        );
      }
    }
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
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.route_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: 11),
                          const Text('Rawat Motor', style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFE9EFE3), Color(0xFFF7F2E9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('MULAI PERJALANAN', style: TextStyle(color: green, letterSpacing: 1.2, fontSize: 10, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 9),
                              const Text('Kenalan dulu,\nyuk.', style: TextStyle(color: ink, fontSize: 30, height: 1.08, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 10),
                              Text('Biar pengingat perawatan lebih pas untuk kamu dan motor kesayanganmu.', style: TextStyle(color: ink.withValues(alpha: 0.72), height: 1.45)),
                            ])),
                            const SizedBox(width: 12),
                            const Icon(Icons.two_wheeler_rounded, color: green, size: 68),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: line)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          const _StepLabel(),
                          const SizedBox(height: 18),
                          _field(_name, 'Nama pengendara', 'Contoh: Irvan', icon: Icons.person_outline_rounded),
                          const SizedBox(height: 14),
                          _field(_brand, 'Merek motor', 'Contoh: Yamaha', icon: Icons.two_wheeler_outlined),
                          const SizedBox(height: 14),
                          _field(_model, 'Model motor', 'Contoh: Gear 125', icon: Icons.directions_bike_outlined),
                          const SizedBox(height: 14),
                          _field(_year, 'Tahun motor', 'Contoh: 2024', digitsOnly: true, icon: Icons.calendar_month_outlined),
                          const SizedBox(height: 22),
                          FilledButton.icon(
                            onPressed: _saving ? null : _submit,
                            icon: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.arrow_forward_rounded),
                            label: Text(_saving ? 'Menyimpan…' : 'Simpan dan lanjutkan'),
                            style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), textStyle: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 14),
                      const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.lock_outline_rounded, size: 14, color: muted), SizedBox(width: 6), Text('Profil tersimpan aman di perangkat ini', style: TextStyle(color: muted, fontSize: 12))]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _field(TextEditingController controller, String label, String hint, {bool digitsOnly = false, IconData? icon}) =>
      TextFormField(
        controller: controller,
        keyboardType: digitsOnly ? TextInputType.number : TextInputType.text,
        inputFormatters: digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: icon == null ? null : Icon(icon, color: muted, size: 20)),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Bagian ini perlu diisi.';
          if (digitsOnly) {
            final year = int.tryParse(value);
            if (year == null || year < 1950 || year > DateTime.now().year + 1) {
              return 'Masukkan tahun motor yang valid.';
            }
          }
          return null;
        },
      );
}

class _StepLabel extends StatelessWidget {
  const _StepLabel();

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 27, height: 27, alignment: Alignment.center, decoration: const BoxDecoration(color: sage, shape: BoxShape.circle), child: const Text('1', style: TextStyle(color: green, fontWeight: FontWeight.w800))),
        const SizedBox(width: 10),
        const Text('Profil pengendara & motor', style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w800)),
      ]);
}
