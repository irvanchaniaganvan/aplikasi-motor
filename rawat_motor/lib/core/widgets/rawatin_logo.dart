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
    this.animationProgress = 1,
  });

  final double size;
  final bool showShadow;
  final String semanticLabel;
  final double animationProgress;

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
        painter: RawatinLogoPainter(animationProgress: animationProgress),
        size: Size.square(size),
      ),
    ),
  );
}

/// Menggambar logo pada kanvas berukuran 512 x 512.
class RawatinLogoPainter extends CustomPainter {
  const RawatinLogoPainter({this.animationProgress = 1});

  static const double viewBox = 512;
  final double animationProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / viewBox;
    canvas.save();
    canvas.scale(scale);

    final progress = animationProgress.clamp(0.0, 1.0);
    final backgroundProgress = (progress / .08).clamp(0.0, 1.0);
    final background = Paint()
      ..color = AppPalette.ink.withValues(alpha: backgroundProgress);
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

    double segment(double start, double end) =>
        ((progress - start) / (end - start)).clamp(0.0, 1.0);

    final stemProgress = segment(0, .32);
    final bowlProgress = segment(.18, .65);
    final legProgress = segment(.52, .88);
    final accentProgress = segment(.70, 1);

    // Batang vertikal digambar dari atas ke bawah.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 104, viewBox, 104 + 304 * stemProgress));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(136, 104, 64, 304),
        const Radius.circular(8),
      ),
      white,
    );
    canvas.restore();

    // Mangkuk R terbuka dari kiri ke kanan, seperti garis yang sedang ditarik.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, 200 + 204 * bowlProgress, viewBox));
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

    // Kaki diagonal R menyusul dari pangkal menuju ujung.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 282, viewBox, 282 + 126 * legProgress));
    final leg = Path()
      ..moveTo(250, 282)
      ..lineTo(330, 282)
      ..lineTo(416, 408)
      ..lineTo(336, 408)
      ..close();
    canvas.drawPath(leg, white);
    canvas.restore();

    // Aksen brass mengikuti kaki R sebagai garis penutup.
    final accentStart = const Offset(322, 318);
    final accentEnd = Offset.lerp(
      accentStart,
      const Offset(379, 402),
      accentProgress,
    )!;
    canvas.drawLine(
      accentStart,
      accentEnd,
      Paint()
        ..color = AppPalette.accent
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RawatinLogoPainter oldDelegate) =>
      oldDelegate.animationProgress != animationProgress;
}
