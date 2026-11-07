import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

enum VehiclePhotoErrorKind { permission, picker, unreadable, save }

class VehiclePhotoException implements Exception {
  const VehiclePhotoException(this.kind, [this.cause]);

  final VehiclePhotoErrorKind kind;
  final Object? cause;
}

/// Layanan untuk memilih, mengompres, menyalin, dan menghapus foto kendaraan.
class VehiclePhotoService {
  VehiclePhotoService({
    ImagePicker? picker,
    Future<PlatformFile?> Function()? pickDesktopFile,
    Future<Directory> Function()? getDocumentsDirectory,
  }) : _picker = picker ?? ImagePicker(),
       _pickDesktopFile = pickDesktopFile ?? _defaultPickDesktopFile,
       _getDocumentsDirectory =
           getDocumentsDirectory ?? getApplicationDocumentsDirectory;

  final ImagePicker _picker;
  final Future<PlatformFile?> Function() _pickDesktopFile;
  final Future<Directory> Function() _getDocumentsDirectory;

  /// Apakah kamera didukung pada platform saat ini.
  /// Desktop (Windows/Linux/macOS) hanya mendukung pemilihan file galeri.
  bool get isCameraSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  static Future<PlatformFile?> _defaultPickDesktopFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    return result?.files.firstOrNull;
  }

  /// Memilih foto dari galeri atau kamera, memperkecil ke maks 1280px (bawaan picker),
  /// lalu menyalin ke folder dokumen lokal aplikasi.
  ///
  /// Mengembalikan path absolut baru, atau `null` jika dibatalkan.
  Future<String?> pickAndSavePhoto({
    required ImageSource source,
    required String profileId,
    String? oldPhotoPath,
  }) async {
    Uint8List bytes;
    String originalName;
    try {
      if (source == ImageSource.camera && !isCameraSupported) {
        throw const VehiclePhotoException(VehiclePhotoErrorKind.picker);
      }
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        final file = await _pickDesktopFile();
        if (file == null) return null;
        originalName = file.name;
        final data = file.bytes;
        if (data != null) {
          bytes = data;
        } else if (file.path != null) {
          try {
            bytes = await File(file.path!).readAsBytes();
          } catch (error) {
            throw VehiclePhotoException(
              VehiclePhotoErrorKind.unreadable,
              error,
            );
          }
        } else {
          throw const VehiclePhotoException(VehiclePhotoErrorKind.unreadable);
        }
      } else {
        final picked = await _picker.pickImage(
          source: source,
          maxWidth: 1280,
          maxHeight: 1280,
          imageQuality: 85,
        );
        if (picked == null) return null;
        originalName = picked.name;
        try {
          bytes = await picked.readAsBytes();
        } catch (error) {
          throw VehiclePhotoException(VehiclePhotoErrorKind.unreadable, error);
        }
      }
    } on VehiclePhotoException {
      rethrow;
    } on PlatformException catch (error) {
      if (error.code.toLowerCase().contains('permission') ||
          error.code.toLowerCase().contains('denied')) {
        throw VehiclePhotoException(VehiclePhotoErrorKind.permission, error);
      }
      throw VehiclePhotoException(VehiclePhotoErrorKind.picker, error);
    } catch (error) {
      throw VehiclePhotoException(VehiclePhotoErrorKind.picker, error);
    }

    final extension = originalName.split('.').last.toLowerCase();
    if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
      throw const VehiclePhotoException(VehiclePhotoErrorKind.unreadable);
    }
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      codec.dispose();
    } catch (error) {
      throw VehiclePhotoException(VehiclePhotoErrorKind.unreadable, error);
    }

    final Directory appDocDir;
    try {
      appDocDir = await _getDocumentsDirectory();
    } catch (error) {
      throw VehiclePhotoException(VehiclePhotoErrorKind.save, error);
    }
    late final String targetPath;
    try {
      final vehiclePhotosDir = Directory('${appDocDir.path}/vehicle_photos');
      if (!await vehiclePhotosDir.exists()) {
        await vehiclePhotosDir.create(recursive: true);
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      targetPath =
          '${vehiclePhotosDir.path}/vehicle_${profileId}_$timestamp.$extension';
      final targetFile = File(targetPath);
      await targetFile.writeAsBytes(bytes, flush: true);
    } catch (error) {
      throw VehiclePhotoException(VehiclePhotoErrorKind.save, error);
    }

    if (oldPhotoPath != null &&
        oldPhotoPath.isNotEmpty &&
        oldPhotoPath != targetPath) {
      await deletePhoto(oldPhotoPath);
    }

    return targetPath;
  }

  /// Menghapus file foto lama dari disk jika ada.
  Future<void> deletePhoto(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Abaikan jika file gagal dihapus atau sudah tidak ada.
    }
  }

  /// Menghasilkan pesan kesalahan ramah saat izin ditolak atau proses gagal.
  static String resolveErrorMessage(Object error) {
    if (error is VehiclePhotoException) {
      return switch (error.kind) {
        VehiclePhotoErrorKind.permission => 'Izin akses foto atau kamera ditolak. Kamu bisa mengaktifkannya lewat Pengaturan perangkat.',
        VehiclePhotoErrorKind.picker => 'Pemilih foto belum bisa dibuka. Coba lagi atau pilih file gambar dari perangkat.',
        VehiclePhotoErrorKind.unreadable => 'Foto tidak dapat dibaca. Pilih gambar JPG, JPEG, PNG, atau WEBP lain.',
        VehiclePhotoErrorKind.save =>
          'Foto belum berhasil disimpan. Coba pilih foto lain.',
      };
    }
    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      if (code.contains('permission') || code.contains('denied')) {
        return 'Izin akses foto atau kamera ditolak. Kamu bisa mengaktifkannya lewat Pengaturan perangkat.';
      }
    }
    final text = error.toString().toLowerCase();
    if (text.contains('permission') || text.contains('denied')) {
      return 'Izin akses kamera atau galeri ditolak. Kamu bisa mengaktifkannya lewat Pengaturan perangkat.';
    }
    if (text.contains('format') ||
        text.contains('image') ||
        text.contains('read')) {
      return 'Gagal memuat foto. Pastikan format gambar didukung.';
    }
    return 'Pemilih foto belum bisa dibuka. Coba lagi atau pilih file gambar dari perangkat.';
  }
}
