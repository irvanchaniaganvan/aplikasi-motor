import 'dart:io';

import 'package:flutter/material.dart';

/// Penampil foto kendaraan fullscreen dengan zoom, pan, dan double-tap zoom.
class VehiclePhotoViewer extends StatelessWidget {
  const VehiclePhotoViewer({required this.photoPath, super.key});

  final String photoPath;

  static Future<void> show(BuildContext context, String? photoPath) async {
    if (photoPath == null || photoPath.trim().isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => VehiclePhotoViewer(photoPath: photoPath.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = File(photoPath);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Foto kendaraan'),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          boundaryMargin: const EdgeInsets.all(80),
          child: file.existsSync()
              ? Image.file(file, fit: BoxFit.contain)
              : const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Foto tidak dapat dibuka.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
      ),
    );
  }
}
