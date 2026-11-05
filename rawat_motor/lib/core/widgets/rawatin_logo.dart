import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Logo sementara Rawatin: huruf R geometris dengan garis kecepatan.
///
/// Sumber desain ada di `assets/brand/rawatin_logo.svg`. Geometri di
/// [RawatinLogoPainter] sengaja memakai koordinat 512 yang sama agar logo di
/// header dan ikon launcher selalu identik. Saat logo final dari Figma siap,
/// ganti SVG lalu sesuaikan satu painter ini.
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

    final background = Paint()..color = AppPalette.primary;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, viewBox, viewBox),
        const Radius.circular(112),
      ),
      background,
    );

    final speedPaint = Paint()
      ..color = AppPalette.accent
      ..style = PaintingStyle.fill;
    _roundedBar(canvas, speedPaint, 64, 324, 48, 14);
    _roundedBar(canvas, speedPaint, 64, 360, 34, 14);
    _roundedBar(canvas, speedPaint, 64, 396, 20, 14);

    final white = Paint()
      ..color = AppPalette.surface
      ..style = PaintingStyle.fill;

    // Kaki R digambar lebih dulu agar menyatu dengan mangkuk huruf.
    final leg = Path()
      ..moveTo(250, 282)
      ..lineTo(330, 282)
      ..lineTo(416, 408)
      ..lineTo(336, 408)
      ..close();
    canvas.drawPath(leg, white);

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
        ..color = AppPalette.primary
        ..style = PaintingStyle.fill,
    );

    canvas.restore();
  }

  void _roundedBar(
    Canvas canvas,
    Paint paint,
    double x,
    double y,
    double width,
    double height,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, width, height),
        Radius.circular(height / 2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant RawatinLogoPainter oldDelegate) => false;
}
