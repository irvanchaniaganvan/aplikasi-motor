import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'rawatin_logo.dart';

/// Intro singkat setelah Flutter siap, melengkapi native splash dengan ritme
/// tenang tanpa membuat pengguna menunggu terlalu lama.
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
  late final Animation<Offset> _wordmarkOffset;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineOffset;

  static const _wordmark = 'RAWATIN';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..forward();
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, .30, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: .78, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, .34, curve: Curves.easeOutCubic),
      ),
    );
    _wordmarkOffset =
        Tween<Offset>(begin: const Offset(0, .12), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(.30, .43, curve: Curves.easeOutCubic),
          ),
        );
    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(.77, .95, curve: Curves.easeOutCubic),
      ),
    );
    _taglineOffset =
        Tween<Offset>(begin: const Offset(0, .18), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(.77, .96, curve: Curves.easeOutCubic),
          ),
        );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) widget.onFinished();
    });
  }

  double _characterProgress(int index) {
    const typingStart = .34;
    const characterStep = .052;
    const characterDuration = .065;
    final start = typingStart + index * characterStep;
    final progress = ((_controller.value - start) / characterDuration).clamp(
      0.0,
      1.0,
    );
    return Curves.easeOutCubic.transform(progress);
  }

  Widget _buildSmoothWordmark() {
    return SizedBox(
      width: 190,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < _wordmark.length; index++) ...[
            if (index > 0) const SizedBox(width: 2),
            _buildWordmarkCharacter(index),
          ],
        ],
      ),
    );
  }

  Widget _buildWordmarkCharacter(int index) {
    final progress = _characterProgress(index);
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, 5 * (1 - progress)),
        child: Text(
          _wordmark[index],
          style: const TextStyle(
            color: AppPalette.canvas,
            fontSize: 25,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
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
              SlideTransition(
                position: _wordmarkOffset,
                child: Column(
                  children: [
                    _buildSmoothWordmark(),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: _taglineOpacity,
                      child: SlideTransition(
                        position: _taglineOffset,
                        child: const Text(
                          'Kamu yang gas, Rawatin yang ingat.',
                          style: TextStyle(
                            color: AppPalette.accent,
                            fontSize: 12,
                            letterSpacing: .3,
                          ),
                        ),
                      ),
                    ),
                  ],
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
