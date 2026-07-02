import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/analytics_service.dart';
import '../core/audio_service.dart';
import '../core/constants.dart';
import '../core/vibration_service.dart';
import '../data/game_repository.dart';
import '../data/models.dart';

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  throw UnimplementedError('Overridden in main() once SharedPreferences is ready');
});

final gameControllerProvider = StateNotifierProvider<GameController, GameData>((ref) {
  return GameController(ref.watch(gameRepositoryProvider));
});

class GameController extends StateNotifier<GameData> {
  GameController(this._repo) : super(_repo.load()) {
    AudioService.instance.setMusicVolume(state.settings.musicVolume);
    AudioService.instance.setSfxVolume(state.settings.soundVolume);
    VibrationService.instance.enabled = state.settings.vibrationEnabled;
  }

  final GameRepository _repo;

  Future<void> _persist() => _repo.save(state);

  void setBet(int bet) {
    final maxBet = maxAllowedBet;
    final clamped = bet.clamp(1, maxBet == 0 ? 1 : maxBet);
    state = _clone(bet: clamped);
    AnalyticsService.instance.betChange(clamped);
    _persist();
  }

  int get maxAllowedBet => (state.balance * 0.9).floor();

  void setBetRisk(BetRisk risk) {
    state = _clone(betRisk: risk);
    _persist();
  }

  bool spendCoins(int amount) {
    if (state.balance < amount) return false;
    state = _clone(balance: state.balance - amount);
    _checkLowBalance();
    _persist();
    return true;
  }

  void addCoins(int amount) {
    state = _clone(balance: state.balance + amount);
    _checkLowBalance();
    _persist();
  }

  void grantWinnings(int amount) {
    var total = amount;
    if (state.hasActiveBonus) {
      total += (amount * state.bonusPercent / 100).round();
    }
    state = _clone(balance: state.balance + total, totalWinnings: state.totalWinnings + total);
    _persist();
  }

  void _checkLowBalance() {
    if (state.balance < AppConstants.lowBalanceThreshold) {
      state = _clone(balance: state.balance + AppConstants.lowBalanceBonus);
    }
  }

  void checkLowBalanceAfterLoss() {
    if (state.balance < AppConstants.lowBalanceThreshold) {
      state = _clone(balance: state.balance + AppConstants.lowBalanceBonus);
      _persist();
    }
  }

  void applyShopPackage(ShopPackage pkg) {
    state = _clone(
      balance: state.balance + pkg.coins,
      freeSpins: state.freeSpins + pkg.freeSpins,
      bonusPercent: pkg.bonusPercent,
      bonusExpiry: DateTime.now().add(Duration(days: pkg.bonusDays)),
    );
    _persist();
  }

  void addFreeSpins(int n) {
    state = _clone(freeSpins: state.freeSpins + n);
    _persist();
  }

  bool consumeFreeSpin() {
    if (state.freeSpins <= 0) return false;
    state = _clone(freeSpins: state.freeSpins - 1);
    _persist();
    return true;
  }

  void startWheelCooldown() {
    state = _clone(wheelCooldownUntil: DateTime.now().add(AppConstants.wheelCooldown));
    _persist();
  }

  bool claimDailyBonusIfAvailable() {
    final last = state.lastDailyBonusClaim;
    final now = DateTime.now();
    final isNewDay = last == null || now.difference(last) > const Duration(hours: 20);
    if (!isNewDay) return false;
    state = _clone(balance: state.balance + 1000, lastDailyBonusClaim: now);
    _persist();
    return true;
  }

  bool get isDailyBonusAvailable {
    final last = state.lastDailyBonusClaim;
    if (last == null) return true;
    return DateTime.now().difference(last) > const Duration(hours: 20);
  }

  void connectPayoutMethod(String id, String detail) {
    final map = Map<String, String>.from(state.connectedPayoutMethods)..[id] = detail;
    state = _clone(connectedPayoutMethods: map);
    _persist();
  }

  bool withdrawUsd(double amount) {
    if (state.usdBalance < amount) return false;
    state = _clone(usdBalance: state.usdBalance - amount);
    _persist();
    return true;
  }

  bool exchange(double usdAmount, int coinCost) {
    if (state.balance < coinCost) return false;
    state = _clone(
      balance: state.balance - coinCost,
      usdBalance: state.usdBalance + usdAmount,
    );
    _checkLowBalance();
    _persist();
    return true;
  }

  void updateSettings(GameSettings settings) {
    state = _clone(settings: settings);
    AudioService.instance.setMusicVolume(settings.musicVolume);
    AudioService.instance.setSfxVolume(settings.soundVolume);
    VibrationService.instance.enabled = settings.vibrationEnabled;
    _persist();
  }

  GameData _clone({
    int? balance,
    double? usdBalance,
    int? bet,
    BetRisk? betRisk,
    int? bonusPercent,
    DateTime? bonusExpiry,
    int? freeSpins,
    DateTime? wheelCooldownUntil,
    Map<String, String>? connectedPayoutMethods,
    GameSettings? settings,
    DateTime? lastDailyBonusClaim,
    int? totalWinnings,
  }) {
    return GameData(
      balance: balance ?? state.balance,
      usdBalance: usdBalance ?? state.usdBalance,
      bet: bet ?? state.bet,
      betRisk: betRisk ?? state.betRisk,
      bonusPercent: bonusPercent ?? state.bonusPercent,
      bonusExpiry: bonusExpiry ?? state.bonusExpiry,
      freeSpins: freeSpins ?? state.freeSpins,
      wheelCooldownUntil: wheelCooldownUntil ?? state.wheelCooldownUntil,
      connectedPayoutMethods: connectedPayoutMethods ?? state.connectedPayoutMethods,
      settings: settings ?? state.settings,
      lastDailyBonusClaim: lastDailyBonusClaim ?? state.lastDailyBonusClaim,
      totalWinnings: totalWinnings ?? state.totalWinnings,
    );
  }
}

final leaderboardProvider = Provider<List<LeaderboardEntry>>((ref) {
  final names = [
    'JungleKing', 'GonzoFan88', 'TempleRunner', 'AztecGold', 'BlockMaster',
    'LuckySpinner', 'CoinHunter99', 'RevolRider', 'StoneCarver', 'ExplorerJoe',
  ];
  final scores = [58200, 52250, 47890, 41200, 38650, 33120, 29870, 25400, 21100, 18900];
  return List.generate(names.length, (i) => LeaderboardEntry(i + 1, names[i], scores[i]));
});
