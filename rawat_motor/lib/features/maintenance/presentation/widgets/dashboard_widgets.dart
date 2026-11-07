import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../profile/domain/entities/driver_motor_profile.dart';
import 'common_widgets.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({this.profile, super.key});
  final DriverMotorProfile? profile;

  @override
  Widget build(BuildContext context) => RawatinScreenIntro(
    eyebrow: 'RINGKASAN PERAWATAN',
    title: profile == null ? 'Kondisi motormu' : 'Hai, ${profile!.driverName}!',
    description: 'Jadwal dan catatan perawatan dalam satu tempat.',
  );
}

class CountUpOdometer extends StatelessWidget {
  const CountUpOdometer({
    required this.value,
    required this.style,
    super.key,
  });
  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: reduceMotion ? Duration.zero : AppMotion.odometer,
      curve: Curves.easeOutCubic,
      builder: (context, animated, child) => Text(
        formatNumber(animated.round()),
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: style,
      ),
    );
  }
}

class HeroStat extends StatelessWidget {
  const HeroStat({
    required this.label,
    required this.value,
    required this.color,
    required this.soft,
    required this.icon,
    super.key,
  });

  final String label;
  final int value;
  final Color color;
  final Color soft;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadii.sm),
      border: Border.all(color: color.withValues(alpha: 0.32), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          '$value',
          style: AppType.metric.copyWith(
            color: Colors.white,
            fontSize: 14,
            fontFeatures: const [],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class FinishBanner extends StatelessWidget {
  const FinishBanner({
    required this.title,
    required this.subtitle,
    super.key,
  });
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.safe.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: colors.safe.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.safe.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(AppIcons.checkCircle, color: colors.safeSoft, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.white.withValues(alpha: 0.75),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HeroBackdropPainter extends CustomPainter {
  const HeroBackdropPainter({required this.stripe, required this.accent});
  final Color stripe;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);

    // 1. Garis aksen presisi telemetry di tepi atas instrumen cluster (3px)
    final topBarPaint = Paint()
      ..shader = LinearGradient(
        colors: [stripe, accent.withValues(alpha: 0.8), Colors.transparent],
        stops: const [0.0, 0.45, 0.85],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 3));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 3), topBarPaint);

    // 2. Ambient radial glow halus di sudut kanan atas
    final glowCenter = Offset(size.width * 0.9, size.height * 0.2);
    final glowRadius = size.width * 0.65;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          stripe.withValues(alpha: 0.14),
          stripe.withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius));
    canvas.drawCircle(glowCenter, glowRadius, glowPaint);

    // 3. Lengkung takometer/spedometer digital yang bersih dan presisi
    final gaugeCenter = Offset(size.width * 0.88, size.height * 0.2);
    final outerRing = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(gaugeCenter, 115, outerRing);
    canvas.drawCircle(gaugeCenter, 132, outerRing);

    final telemetryArc = Paint()
      ..color = accent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: gaugeCenter, radius: 124),
      math.pi * 0.65,
      math.pi * 0.45,
      false,
      telemetryArc,
    );
  }

  @override
  bool shouldRepaint(covariant HeroBackdropPainter oldDelegate) =>
      oldDelegate.stripe != stripe || oldDelegate.accent != accent;
}
