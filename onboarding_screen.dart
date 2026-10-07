import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/glass.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    (Icons.camera_alt_rounded, 'Snap or upload', 'Take a photo or pick one from your gallery. Stand straight, good light.'),
    (Icons.checkroom_rounded, 'Pick a garment', 'Browse tops and bottoms and tap the piece you want to try.'),
    (Icons.compare_rounded, 'Before vs After', 'See the result side by side, fade between looks, and save it.'),
  ];

  void _finish() => Navigator.pushReplacement(context, fadeRoute(const HomeScreen()));

  void _next() {
    if (_index == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _pages.length - 1;
    return Scaffold(
      body: GradientBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: last ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(onPressed: last ? null : _finish, child: const Text('Skip')),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) {
                    final p = _pages[i];
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (_, child) {
                        var d = 0.0;
                        if (_controller.hasClients && _controller.position.haveDimensions) {
                          d = ((_controller.page ?? i.toDouble()) - i).abs().clamp(0.0, 1.0);
                        }
                        return Opacity(
                          opacity: 1 - d * .8,
                          child: Transform.scale(scale: 1 - d * .15, child: child),
                        );
                      },
                      // FIX: scales down and scrolls when space is tight,
                      // so it can never overflow.
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final compact = c.maxHeight < 440;
                          final iconSize = compact ? 48.0 : 96.0;
                          final iconPad = compact ? 20.0 : 44.0;
                          final gap = compact ? 16.0 : 40.0;
                          return SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: c.maxHeight),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GlassCard(
                                    radius: compact ? 36 : 64,
                                    padding: EdgeInsets.all(iconPad),
                                    child: ShaderMask(
                                      shaderCallback: (r) => const LinearGradient(
                                        colors: [AppColors.accent, AppColors.accent2],
                                      ).createShader(r),
                                      child: Icon(p.$1, size: iconSize, color: Colors.white),
                                    ),
                                  ),
                                  SizedBox(height: gap),
                                  Text(p.$2,
                                      style: TextStyle(
                                          fontSize: compact ? 22 : 28,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 12),
                                  Text(p.$3,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 16,
                                          height: 1.4,
                                          color: Colors.white.withAlpha(170))),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                      (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: i == _index ? 28 : 8,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.accent : Colors.white.withAlpha(70),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              Padding(
                // FIX: slightly tighter so short windows keep more room.
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    onPressed: _next,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(last ? 'Get started' : 'Next',
                          key: ValueKey(last),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}