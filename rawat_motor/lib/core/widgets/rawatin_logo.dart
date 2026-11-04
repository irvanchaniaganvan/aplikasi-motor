import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Logo ringkas Rawatin yang tetap terbaca pada ukuran kecil.
class RawatinLogo extends StatelessWidget {
  const RawatinLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: green,
      borderRadius: BorderRadius.circular(size * .29),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1820352C),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.two_wheeler_rounded, color: Colors.white, size: size * .59),
        Positioned(
          right: size * .08,
          top: size * .08,
          child: Container(
            width: size * .25,
            height: size * .25,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE8D7),
              shape: BoxShape.circle,
              border: Border.all(color: green, width: size * .035),
            ),
            child: Icon(Icons.check_rounded, color: green, size: size * .17),
          ),
        ),
      ],
    ),
  );
}
