import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/glass.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2400), () {
      // TODO: skip onboarding if already seen (persist a flag, e.g. shared_preferences).
      if (mounted) Navigator.pushReplacement(context, fadeRoute(const OnboardingScreen()));
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    final fade = CurvedAnimation(parent: _c, curve: const Interval(0, .6, curve: Curves.easeOut));
    return Scaffold(
      body: GradientBackdrop(
        child: Center(
          child: FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassCard(
                    radius: 48,
                    padding: const EdgeInsets.all(32),
                    child: ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        colors: [AppColors.accent, AppColors.accent2],
                      ).createShader(r),
                      child: const Icon(Icons.checkroom_rounded, size: 72, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('TRY-ON',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 8)),
                  const SizedBox(height: 6),
                  Text('Virtual fitting room',
                      style: TextStyle(color: Colors.white.withAlpha(150), letterSpacing: 1.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
