import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/rawatin_logo.dart';

enum LocalAccountMode { signIn, create }

class LocalAccountPage extends StatefulWidget {
  const LocalAccountPage({
    required this.onSubmit,
    this.initialMode = LocalAccountMode.signIn,
    this.initialEmail,
    super.key,
  });

  final Future<String?> Function(
    LocalAccountMode mode,
    String email,
    String password,
  )
  onSubmit;
  final LocalAccountMode initialMode;
  final String? initialEmail;

  @override
  State<LocalAccountPage> createState() => _LocalAccountPageState();
}

class _LocalAccountPageState extends State<LocalAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late LocalAccountMode _mode;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    if (widget.initialEmail != null) _email.text = widget.initialEmail!;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final error = await widget.onSubmit(
        _mode,
        _email.text.trim(),
        _password.text,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Terjadi kesalahan. Coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreating = _mode == LocalAccountMode.create;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const RawatinLogo(size: 56),
                    const SizedBox(height: 24),
                    const Text(
                      'Rawatin',
                      style: TextStyle(
                        color: green,
                        fontSize: 13,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isCreating
                          ? 'Buat akun baru.'
                          : 'Selamat datang kembali.',
                      style: const TextStyle(
                        color: ink,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isCreating
                          ? 'Akun demo lokal untuk menyimpan profil dan jadwal perawatan motormu.'
                          : 'Masuk dengan akun yang sudah terdaftar di perangkat ini.',
                      style: const TextStyle(color: muted, height: 1.45),
                    ),
                    if (isCreating) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Satu akun lokal didukung per perangkat. Jika pernah mendaftar di sini, pilih Masuk.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SegmentedButton<LocalAccountMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: LocalAccountMode.signIn,
                          label: Text('Masuk'),
                        ),
                        ButtonSegment(
                          value: LocalAccountMode.create,
                          label: Text('Buat akun'),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _mode = selection.first;
                          _error = null;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Masukkan email yang valid.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Kata sandi',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        helperText: isCreating ? 'Minimal 4 karakter.' : null,
                      ),
                      validator: (value) =>
                          value == null || value.trim().length < 4
                          ? 'Gunakan minimal 4 karakter untuk demo.'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5E4DF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: danger,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: green,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        _busy
                            ? 'Memproses…'
                            : isCreating
                            ? 'Buat akun'
                            : 'Masuk',
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Mode demo: akun dan data hanya tersimpan di perangkat ini. Ini belum merupakan autentikasi sungguhan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
