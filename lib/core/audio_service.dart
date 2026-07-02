import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Central place for all placeholder CC0 SFX/music. Swap the asset paths
/// here later without touching any call site.
class AudioService {
  AudioService._();
  static final instance = AudioService._();

  final AudioPlayer _music = AudioPlayer(playerId: 'music');
  final AudioPlayer _sfx = AudioPlayer(playerId: 'sfx');
  final AudioPlayer _wheel = AudioPlayer(playerId: 'wheel');

  double musicVolume = 0.7;
  double sfxVolume = 0.7;
  bool _musicStarted = false;
  Timer? _wheelRateTicker;

  Future<void> init() async {
    await _music.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> startMusic() async {
    if (_musicStarted) return;
    _musicStarted = true;
    try {
      await _music.setVolume(musicVolume);
      await _music.play(AssetSource('audio/music_loop.wav'));
    } catch (e) {
      debugPrint('Music start failed: $e');
    }
  }

  Future<void> setMusicVolume(double v) async {
    musicVolume = v;
    try {
      await _music.setVolume(v);
    } catch (_) {}
  }

  Future<void> setSfxVolume(double v) async => sfxVolume = v;

  Future<void> _play(String fileName) async {
    if (sfxVolume <= 0) return;
    try {
      await _sfx.play(AssetSource('audio/$fileName'), volume: sfxVolume);
    } catch (e) {
      debugPrint('SFX "$fileName" failed: $e');
    }
  }

  Future<void> tap() => _play('tap.wav');
  Future<void> place() => _play('place.wav');
  Future<void> win() => _play('win.wav');
  Future<void> lose() => _play('lose.wav');
  Future<void> coin() => _play('coin.wav');

  /// Plays the wheel-spin loop while gradually reducing its playback rate
  /// (same easeOutCubic feel as the disc's own rotation animation), so the
  /// sound audibly "winds down" in sync with the wheel slowing to a stop —
  /// per dev instructions §8 ("постепенное замедление вращения и звука").
  Future<void> wheelSpin({required Duration duration}) async {
    _wheelRateTicker?.cancel();
    if (sfxVolume <= 0) return;
    try {
      await _wheel.setReleaseMode(ReleaseMode.loop);
      await _wheel.setPlaybackRate(1.0);
      await _wheel.play(AssetSource('audio/wheel_spin.wav'), volume: sfxVolume);
    } catch (e) {
      debugPrint('SFX "wheel_spin.wav" failed: $e');
      return;
    }

    const tick = Duration(milliseconds: 60);
    final totalTicks = (duration.inMilliseconds / tick.inMilliseconds).ceil();
    var elapsedTicks = 0;
    _wheelRateTicker = Timer.periodic(tick, (timer) async {
      elapsedTicks++;
      final t = (elapsedTicks / totalTicks).clamp(0.0, 1.0);
      // Mirror Curves.easeOutCubic's fast-start/slow-finish shape so the
      // pitch/tempo drop tracks the disc's visual deceleration.
      final eased = 1 - pow(1 - t, 3);
      final rate = (1.0 - eased * 0.65).clamp(0.35, 1.0).toDouble();
      try {
        await _wheel.setPlaybackRate(rate);
      } catch (_) {}
      if (t >= 1.0) {
        timer.cancel();
        try {
          await _wheel.stop();
          await _wheel.setReleaseMode(ReleaseMode.release);
        } catch (_) {}
      }
    });
  }

  void stopWheelSpin() {
    _wheelRateTicker?.cancel();
    _wheel.stop();
  }
}
