import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Editor foto 1:1 dengan pengalaman seperti pengaturan foto profil.
///
/// Foto selalu menutupi frame crop sejak awal. Pengguna dapat menggeser foto
/// dengan satu jari atau memperbesar dengan pinch, lalu menekan centang untuk
/// mengunci posisi. Tombol kembali membatalkan tanpa mengubah foto lama.
class VehiclePhotoCropPage extends StatefulWidget {
  const VehiclePhotoCropPage({required this.bytes, super.key});

  final Uint8List bytes;

  @override
  State<VehiclePhotoCropPage> createState() => _VehiclePhotoCropPageState();
}

class _VehiclePhotoCropPageState extends State<VehiclePhotoCropPage> {
  ui.Image? _image;
  Object? _error;
  double _cropSize = 1;
  double _baseScale = 1;
  double _zoom = 1;
  Offset _offset = Offset.zero;
  double _gestureZoom = 1;
  Offset _gestureImagePoint = Offset.zero;
  bool _layoutScheduled = false;
  bool _saving = false;
  bool _hasInitialLayout = false;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _image = frame.image);
      _updateLayout(_cropSize);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  void _updateLayout(double size) {
    final image = _image;
    if (image == null || size <= 1) return;
    final scale = size / image.width > size / image.height
        ? size / image.width
        : size / image.height;
    final shouldCenter = !_hasInitialLayout;
    _cropSize = size;
    _baseScale = scale;
    _hasInitialLayout = true;
    if (shouldCenter) {
      _offset = Offset(
        (size - image.width * scale) / 2,
        (size - image.height * scale) / 2,
      );
    } else {
      _offset = _clampOffset(_offset, size, scale * _zoom);
    }
  }

  Offset _clampOffset(Offset offset, double size, double scale) {
    final image = _image;
    if (image == null) return offset;
    final width = image.width * scale;
    final height = image.height * scale;
    return Offset(
      width <= size ? (size - width) / 2 : offset.dx.clamp(size - width, 0),
      height <= size ? (size - height) / 2 : offset.dy.clamp(size - height, 0),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (_image == null || !_hasInitialLayout) return;
    _gestureZoom = _zoom;
    _gestureImagePoint =
        (details.localFocalPoint - _offset) / (_baseScale * _zoom);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_image == null || !_hasInitialLayout) return;
    final nextZoom = (_gestureZoom * details.scale).clamp(1.0, 4.0);
    final nextOffset =
        details.localFocalPoint - _gestureImagePoint * (_baseScale * nextZoom);
    setState(() {
      _zoom = nextZoom;
      _offset = _clampOffset(nextOffset, _cropSize, _baseScale * _zoom);
    });
  }

  Future<void> _save() async {
    final image = _image;
    if (image == null || !_hasInitialLayout || _saving) return;
    setState(() => _saving = true);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final effectiveScale = _baseScale * _zoom;
    final source = Rect.fromLTWH(
      -_offset.dx / effectiveScale,
      -_offset.dy / effectiveScale,
      _cropSize / effectiveScale,
      _cropSize / effectiveScale,
    );
    const outputSize = 1024.0;
    canvas.drawImageRect(
      image,
      source,
      const Rect.fromLTWH(0, 0, outputSize, outputSize),
      Paint()..filterQuality = FilterQuality.high,
    );
    final picture = recorder.endRecording();
    final output = await picture.toImage(1024, 1024);
    final data = await output.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    output.dispose();
    if (!mounted) return;
    if (data == null) {
      setState(() => _saving = false);
      return;
    }
    Navigator.of(context).pop(Uint8List.fromList(data.buffer.asUint8List()));
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Batal',
          icon: const Icon(Icons.close_rounded),
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text('Sesuaikan foto'),
        actions: [
          IconButton(
            tooltip: 'Gunakan foto ini',
            onPressed: image == null || !_hasInitialLayout || _saving
                ? null
                : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: _error != null
          ? const Center(
              child: Text(
                'Foto tidak dapat dibaca.',
                style: TextStyle(color: Colors.white),
              ),
            )
          : image == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight - 96;
                final size = availableHeight <= 0
                    ? constraints.maxWidth
                    : constraints.maxWidth < availableHeight
                    ? constraints.maxWidth
                    : availableHeight;
                if (size != _cropSize && !_layoutScheduled) {
                  _layoutScheduled = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _layoutScheduled = false;
                        _updateLayout(size);
                      });
                    }
                  });
                }
                final cropRect = Rect.fromCenter(
                  center: Offset(constraints.maxWidth / 2, size / 2 + 12),
                  width: size,
                  height: size,
                );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _PhotoCanvasPainter(
                        image: image,
                        cropRect: cropRect,
                        offset: _offset,
                        scale: _baseScale * _zoom,
                      ),
                    ),
                    CustomPaint(
                      painter: _CropOverlayPainter(cropRect: cropRect),
                    ),
                    Positioned.fromRect(
                      rect: cropRect,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onScaleStart: _onScaleStart,
                        onScaleUpdate: _onScaleUpdate,
                      ),
                    ),
                    const Positioned(
                      left: 24,
                      right: 24,
                      bottom: 28,
                      child: Text(
                        'Geser foto untuk mengatur posisi, lalu cubit untuk memperbesar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _PhotoCanvasPainter extends CustomPainter {
  const _PhotoCanvasPainter({
    required this.image,
    required this.cropRect,
    required this.offset,
    required this.scale,
  });

  final ui.Image image;
  final Rect cropRect;
  final Offset offset;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(
        cropRect.left + offset.dx,
        cropRect.top + offset.dy,
        image.width * scale,
        image.height * scale,
      ),
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _PhotoCanvasPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect ||
      oldDelegate.offset != offset ||
      oldDelegate.scale != scale;
}

class _CropOverlayPainter extends CustomPainter {
  const _CropOverlayPainter({required this.cropRect});

  final Rect cropRect;

  @override
  void paint(Canvas canvas, Size size) {
    final shade = Paint()..color = Colors.black.withValues(alpha: 0.62);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, cropRect.top), shade);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        cropRect.bottom,
        size.width,
        size.height - cropRect.bottom,
      ),
      shade,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, cropRect.top, cropRect.left, cropRect.height),
      shade,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        cropRect.right,
        cropRect.top,
        size.width - cropRect.right,
        cropRect.height,
      ),
      shade,
    );
    canvas.drawRect(
      cropRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect;
}
