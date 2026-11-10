import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Orb AI: lingkaran gradien ringan dengan ikon sparkle.
class AiOrb extends StatelessWidget {
  const AiOrb({super.key, this.size = 56, this.iconSize});

  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = RawatinColors.of(context);
    final orbSize = size;
    return Container(
      width: orbSize,
      height: orbSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.accent],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.35),
            blurRadius: orbSize * 0.45,
            offset: Offset(0, orbSize * 0.15),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: orbSize * 0.16,
            left: orbSize * 0.18,
            child: Container(
              width: orbSize * 0.18,
              height: orbSize * 0.18,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Icon(
            AppIcons.sparkle,
            color: colors.white,
            size: iconSize ?? orbSize * 0.5,
          ),
        ],
      ),
    );
  }
}
