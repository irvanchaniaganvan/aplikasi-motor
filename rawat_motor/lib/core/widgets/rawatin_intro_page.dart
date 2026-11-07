import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'rawatin_logo.dart';

/// Intro singkat setelah Flutter siap, melengkapi native splash tanpa membuat
/// pengguna menunggu terlalu lama.
class RawatinIntroPage extends StatefulWidget {
  const RawatinIntroPage({required this.onFinished, super.key});

  final VoidCallback onFinished;

  @override
  State<RawatinIntroPage> createState() => _RawatinIntroPageState();
}

class _RawatinIntroPageState extends State<RawatinIntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _wordmarkOpacity;
  late final Animation<Offset> _wordmarkOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..forward();
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, .52, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: .78, end: 1).animate(curve);
    _wordmarkOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(.38, .82, curve: Curves.easeOut),
      ),
    );
    _wordmarkOffset =
        Tween<Offset>(begin: const Offset(0, .12), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(.38, .9, curve: Curves.easeOutCubic),
          ),
        );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.ink,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _logoOpacity,
                child: ScaleTransition(scale: _logoScale, child: child),
              ),
              const SizedBox(height: 22),
              FadeTransition(
                opacity: _wordmarkOpacity,
                child: SlideTransition(
                  position: _wordmarkOffset,
                  child: const Column(
                    children: [
                      Text(
                        'RAWATIN',
                        style: TextStyle(
                          color: AppPalette.canvas,
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Merawat dengan lebih teratur.',
                        style: TextStyle(
                          color: AppPalette.accent,
                          fontSize: 12,
                          letterSpacing: .3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          child: const RawatinLogo(size: 112, showShadow: false),
        ),
      ),
    );
  }
}
