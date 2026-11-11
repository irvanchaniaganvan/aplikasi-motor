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

    final topProgress = segment(.10, .58);
    final innerProgress = segment(.20, .70);
    final legProgress = segment(.32, .82);

    // Path muncul sepanjang garisnya, seperti animasi pembentukan logo.
    final topLine = Path()
      ..moveTo(82, 132)
      ..lineTo(300, 132)
      ..cubicTo(366, 132, 402, 166, 402, 218)
      ..cubicTo(402, 270, 365, 300, 312, 300)
      ..lineTo(268, 300);
    final innerLine = Path()
      ..moveTo(112, 190)
      ..lineTo(296, 190)
      ..cubicTo(322, 190, 342, 204, 342, 226)
      ..cubicTo(342, 248, 324, 264, 300, 264)
      ..lineTo(268, 264);
    final frontLeg = Path()
      ..moveTo(218, 282)
      ..cubicTo(254, 282, 278, 299, 306, 332)
      ..lineTo(370, 402);
    final rearLeg = Path()
      ..moveTo(170, 326)
      ..cubicTo(204, 326, 228, 341, 250, 368)
      ..lineTo(284, 408);
    _drawPathProgress(canvas, topLine, topProgress, orange);
    _drawPathProgress(canvas, innerLine, innerProgress, orange);
    _drawPathProgress(canvas, frontLeg, legProgress, orange);
    _drawPathProgress(canvas, rearLeg, legProgress, orange);

    // Dua trail titik masuk dari tepi dan bertemu pada pangkal logo.
    final trailProgress = (progress / .46).clamp(0.0, 1.0);
    final trailOpacity = ((.52 - progress) / .12).clamp(0.0, 1.0);
    _drawTrail(
      canvas,
      const Offset(-92, 132),
      const Offset(82, 132),
      trailProgress,
      trailOpacity,
    );
    _drawTrail(
      canvas,
      const Offset(-110, 326),
      const Offset(170, 326),
      trailProgress,
      trailOpacity,
    );

    canvas.restore();
  }

  void _drawPathProgress(
    Canvas canvas,
    Path path,
    double progress,
    Paint paint,
  ) {
    if (progress <= 0) return;
    final metric = path.computeMetrics().first;
    canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
  }

  void _drawTrail(
    Canvas canvas,
    Offset start,
    Offset end,
    double progress,
    double opacity,
  ) {
    if (progress <= 0 || opacity <= 0) return;
    final current = Offset.lerp(start, end, progress)!;
    final direction = (end - start) / (end - start).distance;
    final distance = (current - start).distance;
    for (var offset = 0.0; offset < distance; offset += 22) {
      final fade = (1 - offset / 220).clamp(0.0, 1.0);
      canvas.drawCircle(
        current - direction * offset,
        4.5 * fade,
        Paint()
          ..color = AppPalette.accent.withValues(alpha: fade * .5 * opacity),
      );
    }
    canvas.drawCircle(
      current,
      13,
      Paint()
        ..color = AppPalette.accent.withValues(alpha: .20 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawCircle(
      current,
      4,
      Paint()..color = const Color(0xFFFFC44D).withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(covariant RawatinLogoPainter oldDelegate) =>
      oldDelegate.animationProgress != animationProgress;
}
