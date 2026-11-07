import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Avatar foto kendaraan dengan fallback ikon motor bertema Rawatin.
///
/// Memastikan area ketuk minimal 48dp jika dapat diketuk ([onTap] tidak null),
/// serta menangani status pemuatan dan error file gambar lokal.
class VehicleAvatar extends StatelessWidget {
  const VehicleAvatar({
    this.photoPath,
    this.size = 48,
    this.iconSize,
    this.onTap,
    this.showEditBadge = false,
    this.useNeutralPlaceholder = false,
    this.semanticLabel = 'Foto kendaraan',
    super.key,
  });

  /// Path absolut file foto di penyimpanan lokal perangkat.
  final String? photoPath;

  /// Diameter lingkaran avatar.
  final double size;

  /// Ukuran ikon motor fallback. Jika null, otomatis proporsional dengan [size].
  final double? iconSize;

  /// Aksi ketika avatar diketuk.
  final VoidCallback? onTap;

  /// Menampilkan lencana kamera kecil di pojok kanan bawah jika bernilai true.
  final bool showEditBadge;

  /// Menampilkan placeholder foto netral alih-alih ikon motor jika kosong.
  /// Cocok untuk Beranda, tempat foto pengguna menjadi identitas utama.
  final bool useNeutralPlaceholder;

  /// Label aksesibilitas untuk screen reader.
  final String semanticLabel;

  Widget _buildFallback(BuildContext context, RawatinColors colors) {
    if (useNeutralPlaceholder) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.surfaceSoft,
          shape: BoxShape.circle,
          border: Border.all(color: colors.line),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.add_a_photo_outlined,
          size: iconSize ?? (size * 0.42),
          color: colors.muted,
        ),
      );
    }
    final effectiveIconSize = iconSize ?? (size * 0.48);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.primarySoft,
        shape: BoxShape.circle,
        border: Border.all(color: colors.line),
      ),
      alignment: Alignment.center,
      child: Icon(
        AppIcons.vehicle,
        size: effectiveIconSize,
        color: colors.primaryDark,
      ),
    );
  }

  Widget _buildImage(BuildContext context, RawatinColors colors, String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return _buildFallback(context, colors);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.line),
      ),
      child: ClipOval(
        child: Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallback(context, colors),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    final hasPhoto = photoPath != null && photoPath!.trim().isNotEmpty;

    Widget avatar = hasPhoto
        ? _buildImage(context, colors, photoPath!.trim())
        : _buildFallback(context, colors);

    if (showEditBadge) {
      final badgeSize = (size * 0.32).clamp(24.0, 36.0);
      avatar = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colors.surface, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: badgeSize * 0.52,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return Semantics(
        label: semanticLabel,
        button: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: EdgeInsets.all(size < 48 ? (48 - size) / 2 : 0),
                child: Center(child: avatar),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: semanticLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Center(child: avatar),
      ),
    );
  }
}
