import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Simbol Rawatin: monogram R geometris dengan kaki yang membentuk rute.
///
/// Sumber desain ada di `assets/brand/rawatin_logo.svg`. Geometri di
/// [RawatinLogoPainter] sengaja memakai koordinat 512 yang sama agar logo di
/// header dan ikon launcher selalu identik.
class RawatinLogo extends StatelessWidget {
  const RawatinLogo({
    super.key,
    this.size = 48,
    this.showShadow = true,
    this.semanticLabel = 'Logo Rawatin',
  });

  final double size;
  final bool showShadow;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    image: true,
    child: Container(
      width: size,
      height: size,
      decoration: showShadow
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(size * .22),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.shadow,
                  blurRadius: size * .3,
                  offset: Offset(0, size * .1),
                ),
              ],
            )
          : null,
      child: CustomPaint(
        painter: const RawatinLogoPainter(),
        size: Size.square(size),
      ),
    ),
  );
}

/// Menggambar logo pada kanvas berukuran 512 x 512.
class RawatinLogoPainter extends CustomPainter {
  const RawatinLogoPainter();

  static const double viewBox = 512;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / viewBox;
    canvas.save();
    canvas.scale(scale);

    final background = Paint()..color = AppPalette.ink;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, viewBox, viewBox),
        const Radius.circular(112),
      ),
      background,
    );

    final white = Paint()
      ..color = AppPalette.canvas
      ..style = PaintingStyle.fill;

    // Kaki R digambar lebih dulu agar menyatu dengan mangkuk huruf.
    final leg = Path()
      ..moveTo(250, 282)
      ..lineTo(330, 282)
      ..lineTo(416, 408)
      ..lineTo(336, 408)
      ..close();
    canvas.drawPath(leg, white);

    // Aksen brass kecil mengisyaratkan jalur tanpa membuat simbol ramai.
    canvas.drawLine(
      const Offset(322, 318),
      const Offset(379, 402),
      Paint()
        ..color = AppPalette.accent
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // Batang vertikal R.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(136, 104, 64, 304),
        const Radius.circular(8),
      ),
      white,
    );

    // Mangkuk R: bentuk D lalu lubang warna latar.
    final bowl = Path()
      ..moveTo(200, 104)
      ..lineTo(302, 104)
      ..cubicTo(364, 104, 404, 144, 404, 202)
      ..cubicTo(404, 260, 364, 300, 302, 300)
      ..lineTo(200, 300)
      ..close();
    canvas.drawPath(bowl, white);

    final hole = Path()
      ..moveTo(200, 164)
      ..lineTo(298, 164)
      ..cubicTo(320, 164, 334, 178, 334, 202)
      ..cubicTo(334, 226, 320, 240, 298, 240)
      ..lineTo(200, 240)
      ..close();
    canvas.drawPath(
      hole,
      Paint()
        ..color = AppPalette.ink
        ..style = PaintingStyle.fill,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RawatinLogoPainter oldDelegate) => false;
}
