// Alat bantu, bukan tes perilaku aplikasi.
//
// Jalankan sekali setelah logo berubah:
//   flutter test tool/generate_icons_test.dart
//
// Semua ikon launcher digambar ulang dari RawatinLogoPainter yang sama dengan
// logo di header, sehingga hanya ada satu sumber geometri di dalam kode.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawatin/core/widgets/rawatin_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate launcher icons dari RawatinLogoPainter', () async {
    Future<Uint8List> render(int size) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const painter = RawatinLogoPainter();
      canvas.scale(size / RawatinLogoPainter.viewBox);
      painter.paint(
        canvas,
        const Size(RawatinLogoPainter.viewBox, RawatinLogoPainter.viewBox),
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(size, size);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      picture.dispose();
      return data!.buffer.asUint8List();
    }

    Future<void> writePng(String path, int size) async {
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(await render(size));
    }

    const android = {
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
      'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
    };
    for (final entry in android.entries) {
      await writePng(entry.key, entry.value);
    }

    const iosDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    const ios = {
      'Icon-App-20x20@1x.png': 20,
      'Icon-App-20x20@2x.png': 40,
      'Icon-App-20x20@3x.png': 60,
      'Icon-App-29x29@1x.png': 29,
      'Icon-App-29x29@2x.png': 58,
      'Icon-App-29x29@3x.png': 87,
      'Icon-App-40x40@1x.png': 40,
      'Icon-App-40x40@2x.png': 80,
      'Icon-App-40x40@3x.png': 120,
      'Icon-App-60x60@2x.png': 120,
      'Icon-App-60x60@3x.png': 180,
      'Icon-App-76x76@1x.png': 76,
      'Icon-App-76x76@2x.png': 152,
      'Icon-App-83.5x83.5@2x.png': 167,
      'Icon-App-1024x1024@1x.png': 1024,
    };
    for (final entry in ios.entries) {
      await writePng('$iosDir/${entry.key}', entry.value);
    }

    await writePng('assets/brand/rawatin_icon.png', 1024);

    const icoSizes = [16, 24, 32, 48, 64, 128, 256];
    final pngs = <Uint8List>[
      for (final size in icoSizes) await render(size),
    ];
    final ico = _buildIco(icoSizes, pngs);
    final icoFile = File('windows/runner/resources/app_icon.ico');
    await icoFile.writeAsBytes(ico);
  });
}

Uint8List _buildIco(List<int> sizes, List<Uint8List> pngs) {
  final headerSize = 6 + (16 * sizes.length);
  final bytes = BytesBuilder();
  bytes.add([0, 0, 1, 0, sizes.length & 0xFF, (sizes.length >> 8) & 0xFF]);

  var offset = headerSize;
  for (var index = 0; index < sizes.length; index++) {
    final size = sizes[index];
    final png = pngs[index];
    bytes.add([
      size >= 256 ? 0 : size,
      size >= 256 ? 0 : size,
      0,
      0,
      1,
      0,
      32,
      0,
    ]);
    bytes.add(_uint32(png.length));
    bytes.add(_uint32(offset));
    offset += png.length;
  }
  for (final png in pngs) {
    bytes.add(png);
  }
  return bytes.toBytes();
}

Uint8List _uint32(int value) {
  final data = ByteData(4)..setUint32(0, value, Endian.little);
  return data.buffer.asUint8List();
}
