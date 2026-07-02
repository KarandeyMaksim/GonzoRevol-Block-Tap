import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_scale.dart';
import '../../app/theme.dart';
import '../../widgets/screen_background.dart';
import '../letsplay/lets_play_screen.dart';

/// Node `0:3` — loading screen with a progress bar and a randomized
/// headline/subtitle pair (7 variants), then an automatic transition to
/// "Let's Play".
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  // Exact copy from the Figma loading-screen variants (7 randomized pairs).
  static const _tips = [
    ('HOLD ON…', "WE'RE ALMOST THERE!"),
    ('WELCOME!', 'GET READY TO WIN!'),
    ('LOADING YOUR LUCK…', ''),
    ('HI!', "LET'S MAKE TODAY LUCKY!"),
    ('HI THERE!', 'PREPARING YOUR LUCK…'),
    ('WELCOME!', "LET'S GET STARTED!"),
    ('READY?', "LET'S MAKE IT A WIN!"),
  ];

  late final AnimationController _progressCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  late final (String, String) _headline;

  @override
  void initState() {
    super.initState();
    _headline = _tips[Random().nextInt(_tips.length)];
    _progressCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goNext();
      }
    });
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LetsPlayScreen()));
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesignCanvas(
      child: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                const Spacer(flex: 3),
                Image.asset(
                  'assets/images/logo.png',
                  height: 280,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Text('GonzoRevol', style: AppTextStyles.displayShadowed(size: 40)),
                ),
                const Spacer(flex: 2),
                Text(
                  _headline.$1,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displayShadowed(size: 26, color: AppColors.gold2),
                ),
                const SizedBox(height: 8),
                Text(
                  _headline.$2,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(size: 14, color: AppColors.cream),
                ),
                const SizedBox(height: 26),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedBuilder(
                    animation: _progressCtrl,
                    builder: (context, _) => LinearProgressIndicator(
                      value: _progressCtrl.value,
                      minHeight: 14,
                      backgroundColor: AppColors.exchangeBarBase,
                      color: AppColors.gold2,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
