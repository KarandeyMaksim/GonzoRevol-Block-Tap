import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:startapp_sdk/startapp.dart';

/// Wraps start.io rewarded video ads only. Interstitials and banners are
/// intentionally never requested, per "Реклама в приложениях.md".
class AdsService {
  AdsService._();
  static final instance = AdsService._();

  final StartAppSdk _sdk = StartAppSdk();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _sdk.setTestAdsEnabled(kDebugMode);
    } catch (e) {
      debugPrint('StartApp init failed: $e');
    }
  }

  /// Shows a rewarded video ad. Returns true only if the user watched it to
  /// completion (or at least it was displayed and hidden without an explicit
  /// failure) and the reward should be granted.
  Future<bool> showRewarded() async {
    final completer = Completer<bool>();
    var completedVideo = false;

    try {
      final ad = await _sdk.loadRewardedVideoAd(
        onVideoCompleted: () => completedVideo = true,
        onAdHidden: () {
          if (!completer.isCompleted) completer.complete(completedVideo);
        },
        onAdNotDisplayed: () {
          if (!completer.isCompleted) completer.complete(false);
        },
      );
      final shown = await ad.show();
      if (!shown) {
        if (!completer.isCompleted) completer.complete(false);
      }
    } catch (e) {
      debugPrint('StartApp rewarded show failed: $e');
      if (!completer.isCompleted) completer.complete(false);
    }

    Future.delayed(const Duration(seconds: 60), () {
      if (!completer.isCompleted) completer.complete(completedVideo);
    });

    return completer.future;
  }
}
