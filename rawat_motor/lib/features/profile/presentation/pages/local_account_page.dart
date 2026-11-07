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
    final colors = RawatinColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const RawatinLogo(size: 48),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RAWATIN',
                                style: AppType.eyebrow.copyWith(
                                  color: colors.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Merawat dengan lebih teratur.',
                                style: TextStyle(
                                  color: colors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      isCreating
                          ? 'Buat akun baru.'
                          : 'Selamat datang kembali.',
                      style: AppType.km.copyWith(
                        color: colors.ink,
                        fontSize: 34,
                        height: 1.02,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      isCreating
                          ? 'Akun demo lokal untuk menyimpan profil dan jadwal perawatan motormu.'
                          : 'Masuk dengan akun yang sudah terdaftar di perangkat ini.',
                      style: TextStyle(
                        color: colors.muted,
                        height: 1.45,
                        fontSize: 13.5,
                      ),
                    ),
                    if (isCreating) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _Note(
                        icon: AppIcons.infoOutline,
                        text: 'Satu akun lokal didukung per perangkat. Jika pernah mendaftar di sini, pilih Masuk.',
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                        border: Border.all(color: colors.line),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow,
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [colors.primary, colors.accent],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
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
                                const SizedBox(height: AppSpacing.xl),
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(
                                      AppIcons.mail,
                                      color: colors.muted,
                                      size: 20,
                                    ),
                                  ),
                                  validator: (value) =>
                                      value == null || !value.contains('@')
                                      ? 'Masukkan email yang valid.'
                                      : null,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextFormField(
                                  controller: _password,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: 'Kata sandi',
                                    prefixIcon: Icon(
                                      AppIcons.lock,
                                      color: colors.muted,
                                      size: 20,
                                    ),
                                    helperText: isCreating
                                        ? 'Minimal 4 karakter.'
                                        : null,
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().length < 4
                                      ? 'Gunakan minimal 4 karakter untuk demo.'
                                      : null,
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  Container(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.md,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.dueSoft,
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.md,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          AppIcons.warning,
                                          color: colors.due,
                                          size: 18,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            _error!,
                                            style: TextStyle(
                                              color: colors.due,
                                              fontSize: 12,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.xl),
                                FilledButton(
                                  onPressed: _busy ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                  ),
                                  child: Text(
                                    _busy
                                        ? 'Memproses…'
                                        : isCreating
                                        ? 'Buat akun'
                                        : 'Masuk',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(AppIcons.lock, color: colors.muted, size: 14),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Mode demo: akun dan data hanya tersimpan di perangkat ini. Ini belum merupakan autentikasi sungguhan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.muted,
                              fontSize: 11.5,
                              height: 1.45,
                            ),
                          ),
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
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.check, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: colors.muted, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
