import 'package:flutter/services.dart';

/// Debounced haptic feedback — fires only on meaningful round-resolution
/// events (win/loss/purchase), never per-cube placement, per dev instructions.
class VibrationService {
  VibrationService._();
  static final instance = VibrationService._();

  bool enabled = true;
  DateTime _lastFire = DateTime.fromMillisecondsSinceEpoch(0);
  static const _minGap = Duration(milliseconds: 400);

  void _fire(void Function() action) {
    if (!enabled) return;
    final now = DateTime.now();
    if (now.difference(_lastFire) < _minGap) return;
    _lastFire = now;
    action();
  }

  void light() => _fire(() => HapticFeedback.lightImpact());
  void medium() => _fire(() => HapticFeedback.mediumImpact());
  void heavy() => _fire(() => HapticFeedback.heavyImpact());
  void selection() => _fire(() => HapticFeedback.selectionClick());
}
