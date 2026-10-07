import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Frosted, translucent card.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final int alpha; // 0-255 white tint

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.alpha = 36,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(alpha),
            borderRadius: r,
            border: Border.all(color: Colors.white.withAlpha(46)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Gradient background with soft glowing blobs.
class GradientBackdrop extends StatelessWidget {
  final Widget child;
  const GradientBackdrop({super.key, required this.child});

  Widget _blob(Color c, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [c.withAlpha(110), c.withAlpha(0)]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgTop, AppColors.bgMid, AppColors.bgBottom],
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -80, right: -60, child: _blob(AppColors.accent, 260)),
            Positioned(bottom: -100, left: -80, child: _blob(AppColors.accent2, 300)),
            Positioned.fill(child: child),
          ],
        ),
      ),
    );
  }
}
