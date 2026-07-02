import 'package:flutter/material.dart';

/// Gentle grow/shrink loop used to draw the player's eye to a call-to-action
/// (Spin, Watch & Claim, Boost Reward) — per dev instructions ("всегда
/// добавляем пульсацию (больше меньше) чтобы брало на себя внимание").
class Pulsing extends StatefulWidget {
  const Pulsing({
    super.key,
    required this.child,
    this.enabled = true,
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.duration = const Duration(milliseconds: 650),
  });

  final Widget child;
  final bool enabled;
  final double minScale;
  final double maxScale;
  final Duration duration;

  @override
  State<Pulsing> createState() => _PulsingState();
}

class _PulsingState extends State<Pulsing> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant Pulsing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.enabled && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return ScaleTransition(
      scale: Tween(begin: widget.minScale, end: widget.maxScale).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}
