import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/maintenance/data/repositories/local_motor_data_repository.dart';
import 'features/maintenance/domain/use_cases/load_motor_data.dart';
import 'features/maintenance/domain/use_cases/save_motor_data.dart';
import 'features/maintenance/presentation/pages/oil_reminder_page.dart';
import 'features/profile/data/repositories/local_profile_repository.dart';
import 'features/profile/presentation/pages/profile_setup_page.dart';
import 'features/profile/presentation/pages/local_account_page.dart';
import 'features/profile/domain/entities/driver_motor_profile.dart';

void main() {
  runApp(const RawatMotorApp());
}

class RawatMotorApp extends StatelessWidget {
  const RawatMotorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final profileRepository = LocalProfileRepository(SharedPreferencesAsync());
    final motorDataRepository = LocalMotorDataRepository(SharedPreferencesAsync());
    return MaterialApp(
      title: 'Rawat Motor',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: FutureBuilder<List<Object?>>(
        future: Future.wait<Object?>([
          profileRepository.load(),
          profileRepository.loadAccountEmail(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return const Scaffold(body: Center(child: Text('Profil gagal dimuat.')));
          }
          final profile = snapshot.data![0] as DriverMotorProfile?;
          final email = snapshot.data![1] as String?;
          if (email == null) {
            return LocalAccountPage(onContinue: (value) async {
              await profileRepository.saveAccountEmail(value);
              if (context.mounted) {
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ProfileSetupPage(onSave: (saved) async {
                  await profileRepository.save(saved);
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OilReminderPage(
                    loadMotorData: LoadMotorData(motorDataRepository),
                    saveMotorData: SaveMotorData(motorDataRepository),
                    profile: saved,
                    onEditProfile: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileSetupPage(initialProfile: saved, onSave: (updated) async { await profileRepository.save(updated); if (context.mounted) Navigator.of(context).pop(); }))),
                    onSignOut: () => _signOut(context, profileRepository, motorDataRepository),
                  )));
                })));
              }
            });
          }
          if (profile == null) {
            return ProfileSetupPage(onSave: (saved) async {
              await profileRepository.save(saved);
              if (context.mounted) {
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OilReminderPage(
                  loadMotorData: LoadMotorData(motorDataRepository),
                  saveMotorData: SaveMotorData(motorDataRepository),
                  profile: saved,
                  onEditProfile: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileSetupPage(initialProfile: saved, onSave: (updated) async { await profileRepository.save(updated); if (context.mounted) Navigator.of(context).pop(); }))),
                  onSignOut: () => _signOut(context, profileRepository, motorDataRepository),
                )));
              }
            });
          }
          return OilReminderPage(
            loadMotorData: LoadMotorData(motorDataRepository),
            saveMotorData: SaveMotorData(motorDataRepository),
            profile: profile,
            onEditProfile: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileSetupPage(
                initialProfile: profile,
                onSave: (updated) async {
                  await profileRepository.save(updated);
                  if (context.mounted) Navigator.of(context).pop();
                },
              )));
            },
            onSignOut: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Keluar dari akun demo?'),
                  content: const Text('Data profil dan pengingat di perangkat ini akan dihapus.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
                    FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Keluar')),
                  ],
                ),
              );
              if (confirmed != true) return;
              await profileRepository.clearAccount();
              await profileRepository.clearProfile();
              await motorDataRepository.clear();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => LocalAccountPage(onContinue: (newEmail) async {
                  await profileRepository.saveAccountEmail(newEmail);
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ProfileSetupPage(onSave: (newProfile) async {
                    await profileRepository.save(newProfile);
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OilReminderPage(
                      loadMotorData: LoadMotorData(motorDataRepository),
                      saveMotorData: SaveMotorData(motorDataRepository),
                      profile: newProfile,
                    )));
                  })));
                })),
                (_) => false,
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> _signOut(
  BuildContext context,
  LocalProfileRepository profileRepository,
  LocalMotorDataRepository motorDataRepository,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Keluar dari akun demo?'),
      content: const Text('Data profil dan pengingat di perangkat ini akan dihapus.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Keluar')),
      ],
    ),
  );
  if (confirmed != true) return;
  await profileRepository.clearAccount();
  await profileRepository.clearProfile();
  await motorDataRepository.clear();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => LocalAccountPage(onContinue: (email) async {
      await profileRepository.saveAccountEmail(email);
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ProfileSetupPage(onSave: (profile) async {
        await profileRepository.save(profile);
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OilReminderPage(
          loadMotorData: LoadMotorData(motorDataRepository),
          saveMotorData: SaveMotorData(motorDataRepository),
          profile: profile,
          onEditProfile: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileSetupPage(initialProfile: profile, onSave: (updated) async { await profileRepository.save(updated); if (context.mounted) Navigator.of(context).pop(); }))),
          onSignOut: () => _signOut(context, profileRepository, motorDataRepository),
        )));
      })));
    })),
    (_) => false,
  );
}
