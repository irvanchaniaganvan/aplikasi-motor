import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Simbol Rawatin: monogram R bergaya racing dengan garis-garis kecepatan.
///
/// Sumber desain ada di `assets/brand/rawatin_logo.svg`. Geometri di
/// [RawatinLogoPainter] memakai koordinat kanvas 512 supaya logo UI dan ikon
/// launcher tetap konsisten.
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

    final orange = Paint()
      ..color = AppPalette.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round;

    double segment(double start, double end) =>
        ((progress - start) / (end - start)).clamp(0.0, 1.0);

    final topProgress = segment(0, .38);
    final legProgress = segment(.55, .9);

    // Dua garis cepat membentuk kepala R; clip menjaga animasi intro bertahap.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, viewBox * topProgress, viewBox));
    final topLine = Path()
      ..moveTo(82, 132)
      ..lineTo(300, 132)
      ..cubicTo(366, 132, 402, 166, 402, 218)
      ..cubicTo(402, 270, 365, 300, 312, 300)
      ..lineTo(268, 300);
    canvas.drawPath(topLine, orange);
    final innerLine = Path()
      ..moveTo(112, 190)
      ..lineTo(296, 190)
      ..cubicTo(322, 190, 342, 204, 342, 226)
      ..cubicTo(342, 248, 324, 264, 300, 264)
      ..lineTo(268, 264);
    canvas.drawPath(innerLine, orange);
    canvas.restore();

    // Sepasang garis diagonal menutup monogram seperti kaki huruf R.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 260, viewBox, 260 + 180 * legProgress));
    final frontLeg = Path()
      ..moveTo(218, 282)
      ..cubicTo(254, 282, 278, 299, 306, 332)
      ..lineTo(370, 402);
    canvas.drawPath(frontLeg, orange);
    final rearLeg = Path()
      ..moveTo(170, 326)
      ..cubicTo(204, 326, 228, 341, 250, 368)
      ..lineTo(284, 408);
    canvas.drawPath(rearLeg, orange);
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RawatinLogoPainter oldDelegate) =>
      oldDelegate.animationProgress != animationProgress;
}
