import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class LocalAccountPage extends StatefulWidget {
  const LocalAccountPage({required this.onContinue, super.key});
  final Future<void> Function(String email) onContinue;

  @override
  State<LocalAccountPage> createState() => _LocalAccountPageState();
}

class _LocalAccountPageState extends State<LocalAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    await widget.onContinue(_email.text.trim());
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Container(width: 56, height: 56, alignment: Alignment.center, decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.route_rounded, color: Colors.white, size: 30)),
                    const SizedBox(height: 24),
                    const Text('Rawat Motor', style: TextStyle(color: green, fontSize: 13, letterSpacing: 1, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text('Mulai dengan akunmu.', style: TextStyle(color: ink, fontSize: 30, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text('Buat akun demo lokal atau masuk untuk melanjutkan.', style: TextStyle(color: muted, height: 1.45)),
                    const SizedBox(height: 26),
                    TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)), validator: (value) => value == null || !value.contains('@') ? 'Masukkan email yang valid.' : null),
                    const SizedBox(height: 14),
                    TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Kata sandi', prefixIcon: Icon(Icons.lock_outline_rounded)), validator: (value) => value == null || value.trim().length < 4 ? 'Gunakan minimal 4 karakter untuk demo.' : null),
                    const SizedBox(height: 20),
                    FilledButton(onPressed: _busy ? null : _continue, style: FilledButton.styleFrom(backgroundColor: green, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: Text(_busy ? 'Memproses…' : 'Buat akun / Masuk')),
                    const SizedBox(height: 14),
                    const Text('Mode demo: akun hanya tersimpan di perangkat ini. Ini belum merupakan autentikasi sungguhan.', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12, height: 1.45)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}
