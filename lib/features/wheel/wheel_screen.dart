import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_scale.dart';
import '../../app/theme.dart';
import '../../core/ads_service.dart';
import '../../core/analytics_service.dart';
import '../../core/audio_service.dart';
import '../../providers/providers.dart';
import '../../widgets/ornate_button.dart';
import '../../widgets/pulsing.dart';
import '../../widgets/screen_background.dart';
import '../../widgets/screen_header.dart';

class WheelSegment {
  const WheelSegment(this.label, this.coins, {this.freeSpins = 0, this.isFail = false});
  final String label;
  final int coins;
  final int freeSpins;
  final bool isFail;

  // Order matches the pre-drawn `wheel_disc.png` art, clockwise starting
  // from the segment under the pointer (12 o'clock / top).
  static const segments = [
    WheelSegment('10 000', 10000),
    WheelSegment('100', 100),
    WheelSegment('FAIL', 0, isFail: true),
    WheelSegment('500', 500),
    WheelSegment('1 000', 1000),
    WheelSegment('200', 200),
    WheelSegment('3 SPINS', 0, freeSpins: 3),
    WheelSegment('300', 300),
    WheelSegment('FAIL', 0, isFail: true),
    WheelSegment('5 000', 5000),
    WheelSegment('150', 150),
    WheelSegment('800', 800),
  ];
}

class WheelScreen extends ConsumerStatefulWidget {
  const WheelScreen({super.key});

  @override
  ConsumerState<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends ConsumerState<WheelScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
  int? _resultIndex;
  bool _resolved = true;
  Timer? _cooldownTicker;

  @override
  void initState() {
    super.initState();
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _cooldownTicker?.cancel();
    AudioService.instance.stopWheelSpin();
    super.dispose();
  }

  double get _rotation {
    if (_resultIndex == null) return 0;
    final segAngle = (2 * pi) / WheelSegment.segments.length;
    final target = 2 * pi - (_resultIndex! * segAngle) - segAngle / 2;
    return 8 * 2 * pi + target;
  }

  void _spin() {
    final game = ref.read(gameControllerProvider);
    if (!game.isWheelReady) return;

    setState(() {
      _resolved = false;
      _resultIndex = Random().nextInt(WheelSegment.segments.length);
    });
    AudioService.instance.wheelSpin(duration: _ctrl.duration!);
    AnalyticsService.instance.wheelSpin(false);
    ref.read(gameControllerProvider.notifier).startWheelCooldown();

    _ctrl.forward(from: 0).whenComplete(() {
      setState(() => _resolved = true);
    });
  }

  Future<void> _claim() async {
    final seg = WheelSegment.segments[_resultIndex!];
    if (seg.isFail) {
      setState(() => _resultIndex = null);
      return;
    }
    final watched = await AdsService.instance.showRewarded();
    if (watched) {
      AnalyticsService.instance.rewardedAdReward('wheel_of_luck');
      final controller = ref.read(gameControllerProvider.notifier);
      if (seg.coins > 0) controller.addCoins(seg.coins);
      if (seg.freeSpins > 0) controller.addFreeSpins(seg.freeSpins);
    }
    if (mounted) setState(() => _resultIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameControllerProvider);
    final ready = game.isWheelReady;
    final remaining = ready ? Duration.zero : game.wheelCooldownUntil!.difference(DateTime.now());

    return DesignCanvas(
      child: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 51),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const ScreenHeader(title: 'Wheel of Luck'),
                const SizedBox(height: 60),
                SizedBox(
                  width: 300,
                  height: 300,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedBuilder(
                        animation: _ctrl,
                        builder: (context, child) {
                          final angle = Curves.easeOutCubic.transform(_ctrl.value) * _rotation;
                          return Transform.rotate(angle: angle, child: child);
                        },
                        child: Image.asset(
                          'assets/images/wheel_disc.png',
                          width: 300,
                          height: 300,
                          errorBuilder: (_, _, _) => CustomPaint(size: const Size(300, 300), painter: _WheelSegmentsPainter()),
                        ),
                      ),
                      Positioned(
                        top: -18,
                        child: Image.asset(
                          'assets/images/wheel_pointer.png',
                          width: 60,
                          errorBuilder: (_, _, _) => const Icon(Icons.arrow_drop_down, color: AppColors.gold2, size: 40),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_resultIndex != null && _resolved)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Text(
                          WheelSegment.segments[_resultIndex!].isFail ? 'No luck this time!' : 'You won ${WheelSegment.segments[_resultIndex!].label}!',
                          style: AppTextStyles.display(size: 22),
                        ),
                        const SizedBox(height: 10),
                        // Per "Реклама в приложениях.md" §2: the claim CTA
                        // pulses gently to draw the eye toward the rewarded
                        // video (fail case just needs a plain "OK").
                        Pulsing(
                          enabled: !WheelSegment.segments[_resultIndex!].isFail,
                          child: SolidGradientButton(
                            label: WheelSegment.segments[_resultIndex!].isFail ? 'OK' : 'Watch & Claim',
                            onTap: _claim,
                            fontSize: 22,
                            icon: WheelSegment.segments[_resultIndex!].isFail ? null : Icons.play_circle_fill,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      Pulsing(
                        enabled: ready && _resolved,
                        child: OrnateButton(
                          label: ready ? 'SPIN' : _formatDuration(remaining),
                          enabled: ready && _resolved,
                          onTap: _spin,
                        ),
                      ),
                      if (ready && _resolved) ...[
                        const SizedBox(height: 8),
                        Text('Tap', style: AppTextStyles.body(size: 14, color: AppColors.cream)),
                      ],
                    ],
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _WheelSegmentsPainter extends CustomPainter {
  static const colorA = Color(0xFF2D3D35);
  static const colorB = Color(0xFF3C6B54);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final segments = WheelSegment.segments;
    final segAngle = (2 * pi) / segments.length;

    for (var i = 0; i < segments.length; i++) {
      final paint = Paint()..color = i.isEven ? colorA : colorB;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), i * segAngle - pi / 2, segAngle, true, paint);
    }

    for (var i = 0; i < segments.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: segments[i].label,
          style: AppTextStyles.display(size: 13, weight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 60);
      final angle = (i + 0.5) * segAngle - pi / 2;
      canvas.save();
      final pos = center + Offset(cos(angle), sin(angle)) * (radius * 0.68);
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle + pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    canvas.drawCircle(center, radius, Paint()
      ..color = AppColors.gold2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8);
    canvas.drawCircle(center, 26, Paint()..color = AppColors.gold1);
    canvas.drawCircle(center, 26, Paint()
      ..color = AppColors.bgTealDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
