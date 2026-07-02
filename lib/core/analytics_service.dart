import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:flutter/foundation.dart';
import 'constants.dart';

/// Thin, crash-safe wrapper around AppMetrica so every call site in the app
/// doesn't need to worry about the SDK failing to activate (e.g. no network
/// on first cold start, or running in a debug/emulator without Play services).
///
/// Every event is nested one level deep under [_gameName], exactly matching
/// the two-level shape shown in "Метрика.md":
///   reportEventWithMap('purchase_success', { game_name: { item_id, price, type } })
class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  /// This app only has a single game screen, so it doubles as both the
  /// nesting key and the `game_name` param value for the game-loop events.
  static const _gameName = 'block_tap';

  bool _activated = false;

  Future<void> activate() async {
    if (_activated) return;
    try {
      await AppMetrica.activate(AppMetricaConfig(
        AppConstants.appMetricaApiKey,
        sessionsAutoTrackingEnabled: true,
        crashReporting: true,
        flutterCrashReporting: true,
        logs: kDebugMode,
      ));
      _activated = true;
    } catch (e) {
      debugPrint('AppMetrica activation failed: $e');
    }
  }

  Future<void> _report(String name, [Map<String, Object>? attrs]) async {
    try {
      await AppMetrica.reportEventWithMap(name, {_gameName: attrs ?? {}});
    } catch (e) {
      debugPrint('AppMetrica event "$name" failed: $e');
    }
  }

  void gameStart({required int bet, required String risk}) =>
      _report('game_start', {'game_name': _gameName, 'bet': bet, 'risk': risk});

  void gameWin({required int amount, required int bet}) =>
      _report('game_win', {'game_name': _gameName, 'amount': amount, 'bet': bet});

  void gameLoss({required int bet}) => _report('game_loss', {'game_name': _gameName, 'bet': bet});

  void betChange(int bet) => _report('bet_change', {'game_name': _gameName, 'bet': bet});

  void paywallView(String source) => _report('paywall_view', {'source': source});

  void paywallClose(String source) => _report('paywall_close', {'source': source});

  void purchaseClick(String itemId, {String type = 'coin'}) =>
      _report('purchase_click', {'item_id': itemId, 'type': type});

  void purchaseSuccess(String itemId, {required double price, String type = 'coin'}) =>
      _report('purchase_success', {'item_id': itemId, 'price': price, 'type': type});

  void purchaseError(String itemId, String error, {String type = 'coin'}) =>
      _report('purchase_error', {'item_id': itemId, 'type': type, 'error': error});

  void settingsOpen() => _report('settings_open');

  void appClose() => _report('app_close');

  void rewardedAdShown(String placement) => _report('rewarded_ad_shown', {'placement': placement});

  void rewardedAdReward(String placement) => _report('rewarded_ad_reward', {'placement': placement});

  void wheelSpin(bool boost) => _report('wheel_spin', {'boost': boost});

  void withdrawalRequest(double amountUsd) => _report('withdrawal_request', {'amount_usd': amountUsd});
}
