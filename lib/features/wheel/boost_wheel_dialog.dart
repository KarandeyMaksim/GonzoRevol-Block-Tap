import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/ads_service.dart';
import '../../core/analytics_service.dart';
import '../../core/audio_service.dart';
import '../../widgets/ornate_button.dart';

/// Small post-win "Boost Reward" mini-wheel: spins for a x1–x10 multiplier,
/// then requires a rewarded ad watch to actually credit the extra amount.
class BoostWheelDialog extends StatefulWidget {
  const BoostWheelDialog({super.key, this.baseAmount = 0});
  final int baseAmount;

  @override
  State<BoostWheelDialog> createState() => _BoostWheelDialogState();
}

class _BoostWheelDialogState extends State<BoostWheelDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  int? _multiplier;
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    final target = Random().nextInt(10) + 1;
    _multiplier = target;
    AudioService.instance.wheelSpin(duration: _ctrl.duration!);
    _ctrl.forward().whenComplete(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    AudioService.instance.stopWheelSpin();
    super.dispose();
  }

  double get _targetRotation {
    final segment = (2 * pi) / 10;
    final target = (_multiplier! - 1) * segment;
    return 6 * 2 * pi + target;
  }

  Future<void> _claim() async {
    setState(() => _claiming = true);
    AnalyticsService.instance.rewardedAdShown('boost_wheel');
    final watched = await AdsService.instance.showRewarded();
    if (watched) {
      AnalyticsService.instance.rewardedAdReward('boost_wheel');
    }
    if (!mounted) return;
    final extra = watched ? (widget.baseAmount * (_multiplier! - 1)) : 0;
    Navigator.of(context).pop(extra);
  }

  @override
  Widget build(BuildContext context) {
    final spinning = _ctrl.isAnimating;
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgTealDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold2, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('BOOST REWARD', style: AppTextStyles.displayShadowed(size: 24)),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                final rotation = Curves.easeOutCubic.transform(_ctrl.value) * _targetRotation;
                return Transform.rotate(angle: rotation, child: child);
              },
              child: _MultiplierWheelPainter(),
            ),
            const SizedBox(height: 16),
            if (!spinning)
              Text('x${_multiplier!}', style: AppTextStyles.displayShadowed(size: 36, color: AppColors.gold2)),
            const SizedBox(height: 16),
            if (!spinning)
              _claiming
                  ? const CircularProgressIndicator(color: AppColors.gold2)
                  : SolidGradientButton(
                      label: 'Claim!',
                      fontSize: 24,
                      icon: Icons.play_circle_fill,
                      onTap: _claim,
                    ),
          ],
        ),
      ),
    );
  }
}

class _MultiplierWheelPainter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: CustomPaint(painter: _WheelPainter()),
    );
  }
}

class _WheelPainter extends CustomPainter {
  static const colors = [
    Color(0xFF2D3D35),
    Color(0xFF3C6B54),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final segmentAngle = (2 * pi) / 10;
    for (var i = 0; i < 10; i++) {
      final paint = Paint()..color = colors[i % 2];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * segmentAngle - pi / 2,
        segmentAngle,
        true,
        paint,
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'x${i + 1}',
          style: AppTextStyles.body(size: 14, color: AppColors.cream, weight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final angle = (i + 0.5) * segmentAngle - pi / 2;
      final pos = center + Offset(cos(angle), sin(angle)) * (radius * 0.68);
      textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
    }
    canvas.drawCircle(center, radius, Paint()
      ..color = AppColors.gold2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4);
    canvas.drawCircle(center, 14, Paint()..color = AppColors.gold1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
