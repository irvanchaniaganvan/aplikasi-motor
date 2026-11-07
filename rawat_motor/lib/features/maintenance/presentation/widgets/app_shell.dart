import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/rawatin_logo.dart';
import '../../../profile/domain/entities/driver_motor_profile.dart';

class RawatinSidebar extends StatelessWidget {
  const RawatinSidebar({
    required this.selected,
    required this.onSelect,
    this.profile,
    this.onOpenSettings,
    super.key,
  });
  final int selected;
  final ValueChanged<int> onSelect;
  final DriverMotorProfile? profile;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Container(
      width: 252,
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        border: Border(right: BorderSide(color: colors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      const RawatinBrandMark(),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RAWATIN',
                              style: AppType.cardTitle.copyWith(
                                color: colors.ink,
                                fontSize: 21,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              'PERAWATAN MOTOR',
                              style: AppType.eyebrow.copyWith(
                                color: colors.muted,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 8),
                  child: Text(
                    'NAVIGASI',
                    style: AppType.eyebrow.copyWith(
                      color: colors.muted,
                      fontSize: 9,
                    ),
                  ),
                ),
                _navItem(0, AppIcons.home, 'Beranda', colors),
                _navItem(1, AppIcons.history, 'Riwayat', colors),
                _navItem(2, Icons.route_rounded, 'Perjalanan', colors),
                _actionItem(
                  AppIcons.settings,
                  'Pengaturan motor',
                  onOpenSettings,
                  colors,
                ),
              ],
            ),
          ),
          const Spacer(),
          if (profile != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(color: colors.line),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: colors.primarySoft,
                      foregroundColor: colors.primaryDark,
                      child: Text(
                        profile!.driverName.isEmpty
                            ? '?'
                            : profile!.driverName[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile!.driverName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.ink,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${profile!.brand} ${profile!.model}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: colors.muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _navItem(
    int index,
    IconData icon,
    String label,
    RawatinColors colors,
  ) {
    final active = selected == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          selected: active,
          selectedTileColor: colors.primarySoft,
          selectedColor: colors.primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          minLeadingWidth: 22,
          leading: Icon(
            icon,
            color: active ? colors.primaryDark : colors.muted,
            size: 20,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: active ? colors.primaryDark : colors.inkSoft,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
          onTap: () => onSelect(index),
          dense: true,
        ),
      ),
    );
  }

  Widget _actionItem(
    IconData icon,
    String label,
    VoidCallback? onTap,
    RawatinColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          minLeadingWidth: 22,
          leading: Icon(icon, color: colors.muted, size: 20),
          title: Text(
            label,
            style: TextStyle(
              color: colors.inkSoft,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          onTap: onTap,
          dense: true,
        ),
      ),
    );
  }
}

class RawatinBrandMark extends StatelessWidget {
  const RawatinBrandMark({super.key});

  @override
  Widget build(BuildContext context) => const RawatinLogo(size: 38);
}

class RawatinTopBar extends StatelessWidget {
  const RawatinTopBar({
    required this.title,
    this.profile,
    this.onEditProfile,
    this.onSignOut,
    this.vehicleCount = 1,
    this.onSelectVehicle,
    this.onAddVehicle,
    this.onManageVehicles,
    this.vehicles = const [],
    this.onOpenSettings,
    super.key,
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
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    final compact = MediaQuery.sizeOf(context).width < 560;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 16),
          child: Row(
            children: [
              if (compact) ...[
                const RawatinLogo(size: 28, showShadow: false),
                const SizedBox(width: 9),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'RAWATIN',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: AppType.eyebrow.copyWith(
                        color: colors.primary,
                        fontSize: 9.5,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.cardTitle.copyWith(
                        color: colors.ink,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Pengaturan motor',
                onPressed: onOpenSettings,
                icon: Icon(AppIcons.settings, color: colors.inkSoft),
              ),
              if (profile != null) ...[
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
                  child: compact
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            AppIcons.vehicle,
                            size: 22,
                            color: colors.inkSoft,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 130),
                              child: Text(
                                '${profile!.brand} ${profile!.model}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.ink,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(AppIcons.chevronDown, color: colors.muted),
                          ],
                        ),
                ),
                if (!compact) ...[
                  const SizedBox(width: AppSpacing.sm),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      profile!.driverName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.muted, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(width: 2),
                RawatinAccountMenu(
                  profile: profile!,
                  onEditProfile: onEditProfile,
                  onSignOut: onSignOut,
                ),
              ] else
                RawatinAccountMenu(
                  profile: null,
                  onEditProfile: onEditProfile,
                  onSignOut: onSignOut,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class RawatinAccountMenu extends StatelessWidget {
  const RawatinAccountMenu({
    required this.profile,
    this.onEditProfile,
    this.onSignOut,
    super.key,
  });

  final DriverMotorProfile? profile;
  final VoidCallback? onEditProfile;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return PopupMenuButton<String>(
      tooltip: 'Menu akun',
      icon: CircleAvatar(
        radius: 18,
        backgroundColor: colors.primarySoft,
        foregroundColor: colors.primaryDark,
        child: Text(
          profile?.driverName.isNotEmpty == true
              ? profile!.driverName[0].toUpperCase()
              : 'U',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
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
    );
  }
}
