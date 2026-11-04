import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/maintenance/data/repositories/local_motor_data_repository.dart';
import 'features/maintenance/domain/use_cases/load_motor_data.dart';
import 'features/maintenance/domain/use_cases/save_motor_data.dart';
import 'features/maintenance/presentation/pages/oil_reminder_page.dart';
import 'features/profile/data/repositories/local_profile_repository.dart';
import 'features/profile/domain/entities/driver_motor_profile.dart';
import 'features/profile/presentation/pages/local_account_page.dart';
import 'features/profile/presentation/pages/profile_setup_page.dart';

void main() {
  runApp(const RawatinApp());
}

class RawatinApp extends StatelessWidget {
  const RawatinApp({super.key});

  @override
  Widget build(BuildContext context) {
    final profileRepository = LocalProfileRepository(SharedPreferencesAsync());
    final motorDataRepository = LocalMotorDataRepository(SharedPreferencesAsync());
    return MaterialApp(
      title: 'Rawatin',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: FutureBuilder<List<Object?>>(
        future: Future.wait<Object?>([
          profileRepository.load(),
          profileRepository.loadAccountEmail(),
          profileRepository.isSignedIn(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return const Scaffold(body: Center(child: Text('Data akun gagal dimuat.')));
          }
          final profile = snapshot.data![0] as DriverMotorProfile?;
          final email = snapshot.data![1] as String?;
          final signedIn = snapshot.data![2] as bool;

          if (!signedIn || email == null) {
            return _buildAccountPage(
              context: context,
              profileRepository: profileRepository,
              motorDataRepository: motorDataRepository,
              accountEmail: email,
            );
          }
          if (profile == null) {
            return _buildProfileSetupPage(
              context: context,
              profileRepository: profileRepository,
              motorDataRepository: motorDataRepository,
            );
          }
          return _buildDashboard(
            context: context,
            profileRepository: profileRepository,
            motorDataRepository: motorDataRepository,
            profile: profile,
          );
        },
      ),
    );
  }
}

Widget _buildAccountPage({
  required BuildContext context,
  required LocalProfileRepository profileRepository,
  required LocalMotorDataRepository motorDataRepository,
  String? accountEmail,
}) {
  return LocalAccountPage(
    initialMode: accountEmail == null
        ? LocalAccountMode.create
        : LocalAccountMode.signIn,
    initialEmail: accountEmail,
    onSubmit: (mode, email, password) async {
      if (mode == LocalAccountMode.create) {
        final existing = await profileRepository.loadAccountEmail();
        if (existing != null) {
          return 'Akun lokal sudah ada. Pilih Masuk untuk melanjutkan.';
        }
        await profileRepository.saveAccountCredentials(email, password);
        if (!context.mounted) return null;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => _buildProfileSetupPage(
            context: context,
            profileRepository: profileRepository,
            motorDataRepository: motorDataRepository,
          ),
        ));
        return null;
      }

      final storedEmail = await profileRepository.loadAccountEmail();
      if (storedEmail == null) {
        return 'Belum ada akun lokal. Pilih Buat akun dulu.';
      }
      if (storedEmail.toLowerCase() != email.trim().toLowerCase()) {
        return 'Email atau kata sandi salah.';
      }
      final storedPassword = await profileRepository.loadAccountPassword();
      if (storedPassword != null && storedPassword != password) {
        return 'Email atau kata sandi salah.';
      }
      if (storedPassword == null) {
        // Akun lama belum punya kata sandi; simpan kata sandi pertama.
        await profileRepository.saveAccountPassword(password);
      }
      await profileRepository.setSignedIn(true);
      final profile = await profileRepository.load();
      if (!context.mounted) return null;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => profile == null
            ? _buildProfileSetupPage(
                context: context,
                profileRepository: profileRepository,
                motorDataRepository: motorDataRepository,
              )
            : _buildDashboard(
                context: context,
                profileRepository: profileRepository,
                motorDataRepository: motorDataRepository,
                profile: profile,
              ),
      ));
      return null;
    },
  );
}

Widget _buildProfileSetupPage({
  required BuildContext context,
  required LocalProfileRepository profileRepository,
  required LocalMotorDataRepository motorDataRepository,
}) {
  return ProfileSetupPage(
    onSave: (profile) async {
      await profileRepository.save(profile);
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => _buildDashboard(
          context: context,
          profileRepository: profileRepository,
          motorDataRepository: motorDataRepository,
          profile: profile,
        ),
      ));
    },
  );
}

Widget _buildDashboard({
  required BuildContext context,
  required LocalProfileRepository profileRepository,
  required LocalMotorDataRepository motorDataRepository,
  required DriverMotorProfile profile,
}) {
  return OilReminderPage(
    loadMotorData: LoadMotorData(motorDataRepository),
    saveMotorData: SaveMotorData(motorDataRepository),
    profile: profile,
    onEditProfile: () {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProfileSetupPage(
          initialProfile: profile,
          onSave: (updated) async {
            await profileRepository.save(updated);
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ));
    },
    onSignOut: () => _signOut(
      context: context,
      profileRepository: profileRepository,
      motorDataRepository: motorDataRepository,
    ),
  );
}

Future<void> _signOut({
  required BuildContext context,
  required LocalProfileRepository profileRepository,
  required LocalMotorDataRepository motorDataRepository,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Keluar dari akun?'),
      content: const Text('Kamu bisa masuk lagi dengan akun yang sama. Profil dan data perawatan tetap tersimpan di perangkat ini.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Keluar')),
      ],
    ),
  );
  if (confirmed != true) return;

  final email = await profileRepository.loadAccountEmail();
  await profileRepository.setSignedIn(false);
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => _buildAccountPage(
        context: context,
        profileRepository: profileRepository,
        motorDataRepository: motorDataRepository,
        accountEmail: email,
      ),
    ),
    (_) => false,
  );
}
