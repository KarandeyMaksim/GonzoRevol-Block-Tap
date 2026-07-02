import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/analytics_service.dart';
import '../core/audio_service.dart';
import '../core/vibration_service.dart';
import '../data/models.dart';
import '../domain/board_engine.dart';
import 'providers.dart';

enum RoundPhase { idle, playing, won, lost }

class RoundState {
  const RoundState({
    required this.phase,
    required this.grid,
    required this.tray,
    required this.secondsRemaining,
    required this.roundSeconds,
    this.winAmount = 0,
    this.usedFreeSpin = false,
  });

  final RoundPhase phase;
  final List<List<int?>> grid;
  final List<TrayPiece?> tray;
  final int secondsRemaining;
  final int roundSeconds;
  final int winAmount;
  final bool usedFreeSpin;

  factory RoundState.initial() => RoundState(
        phase: RoundPhase.idle,
        grid: List.generate(boardSize, (_) => List<int?>.filled(boardSize, null)),
        tray: const [null, null, null],
        secondsRemaining: 90,
        roundSeconds: 90,
      );

  RoundState copyWith({
    RoundPhase? phase,
    List<List<int?>>? grid,
    List<TrayPiece?>? tray,
    int? secondsRemaining,
    int? winAmount,
    bool? usedFreeSpin,
  }) {
    return RoundState(
      phase: phase ?? this.phase,
      grid: grid ?? this.grid,
      tray: tray ?? this.tray,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      roundSeconds: roundSeconds,
      winAmount: winAmount ?? this.winAmount,
      usedFreeSpin: usedFreeSpin ?? this.usedFreeSpin,
    );
  }
}

final roundControllerProvider = StateNotifierProvider<RoundController, RoundState>((ref) {
  return RoundController(ref);
});

class RoundController extends StateNotifier<RoundState> {
  RoundController(this._ref) : super(RoundState.initial());

  final Ref _ref;
  final BoardEngine _engine = BoardEngine();
  Timer? _timer;
  final _random = Random();

  static const int roundDuration = 90;

  bool get canStartRound {
    final game = _ref.read(gameControllerProvider);
    return state.phase != RoundPhase.playing && game.balance >= game.bet;
  }

  void startRound({bool useFreeSpin = false}) {
    final gameController = _ref.read(gameControllerProvider.notifier);
    final game = _ref.read(gameControllerProvider);

    if (state.phase == RoundPhase.playing) return;

    var spent = false;
    if (useFreeSpin && game.freeSpins > 0) {
      spent = gameController.consumeFreeSpin();
    }
    if (!spent) {
      if (game.balance < game.bet) return;
      gameController.spendCoins(game.bet);
    }

    _engine.reset();
    final tray = _engine.dealTray();

    state = RoundState(
      phase: RoundPhase.playing,
      grid: _cloneGrid(_engine.grid),
      tray: tray,
      secondsRemaining: roundDuration,
      roundSeconds: roundDuration,
      usedFreeSpin: spent,
    );

    AnalyticsService.instance.gameStart(bet: game.bet, risk: game.betRisk.label);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.phase != RoundPhase.playing) {
        _timer?.cancel();
        return;
      }
      final next = state.secondsRemaining - 1;
      if (next <= 0) {
        _timer?.cancel();
        // Time's up: bank whatever was earned so far, or lose if nothing
        // was ever cleared.
        if (state.winAmount > 0) {
          collect();
        } else {
          _resolveLoss();
        }
      } else {
        state = state.copyWith(secondsRemaining: next);
      }
    });
  }

  bool canPlace(TrayPiece piece, int row, int col) => _engine.canPlace(piece.shape, row, col);

  bool placePiece(int trayIndex, int row, int col) {
    if (state.phase != RoundPhase.playing) return false;
    final piece = state.tray[trayIndex];
    if (piece == null) return false;
    if (!_engine.canPlace(piece.shape, row, col)) return false;

    final result = _engine.place(piece.shape, row, col, piece.skin);
    AudioService.instance.place();

    final newTray = List<TrayPiece?>.from(state.tray);
    newTray[trayIndex] = null;

    state = state.copyWith(grid: _cloneGrid(_engine.grid), tray: newTray);

    // Clearing a line banks extra winnings but does NOT end the round — the
    // player keeps placing pieces (matching the reference game) until the
    // board genuinely can't fit anything left in the tray.
    if (result.linesCleared > 0) {
      _accumulateWin(result.linesCleared);
    }

    final trayExhausted = newTray.every((p) => p == null);

    if (trayExhausted) {
      // All 3 pieces placed: deal a fresh tray and keep playing, unless the
      // board is now too full for any new piece.
      final freshTray = _engine.dealTray();
      if (_engine.hasAnyMove(freshTray)) {
        state = state.copyWith(tray: freshTray);
      } else {
        _resolveLoss();
      }
      return true;
    }

    final remainingPieces = newTray.whereType<TrayPiece>().toList();
    final noMoves = !_engine.hasAnyMove(remainingPieces);
    if (noMoves) {
      _resolveLoss();
    }

    return true;
  }

  /// A line clear adds to the round's pending winnings but keeps play going
  /// — the player can either keep pushing their luck or tap Collect.
  void _accumulateWin(int linesCleared) {
    final game = _ref.read(gameControllerProvider);
    final (min, max) = game.betRisk.multiplierRange;
    final multiplier = min + _random.nextDouble() * (max - min);
    final multiLineBonus = 1 + (linesCleared - 1) * 0.5;
    final increment = max2(1, (game.bet * multiplier * multiLineBonus).round());

    VibrationService.instance.medium();
    AudioService.instance.win();
    state = state.copyWith(winAmount: state.winAmount + increment);
  }

  /// Banks the currently pending winnings and ends the round as a win. Can
  /// be triggered by the player tapping "Collect" mid-round, or by the round
  /// timer running out while ahead.
  void collect() {
    if (state.phase != RoundPhase.playing || state.winAmount <= 0) return;
    _timer?.cancel();
    final game = _ref.read(gameControllerProvider);
    final amount = state.winAmount;

    _ref.read(gameControllerProvider.notifier).grantWinnings(amount);
    AnalyticsService.instance.gameWin(amount: amount, bet: game.bet);

    state = state.copyWith(phase: RoundPhase.won, winAmount: amount);
  }

  void _resolveLoss() {
    _timer?.cancel();
    final game = _ref.read(gameControllerProvider);
    AnalyticsService.instance.gameLoss(bet: game.bet);
    AudioService.instance.lose();
    VibrationService.instance.heavy();
    _ref.read(gameControllerProvider.notifier).checkLowBalanceAfterLoss();
    state = state.copyWith(phase: RoundPhase.lost, winAmount: 0);
  }

  void finishRound() {
    _timer?.cancel();
    state = RoundState.initial();
  }

  static int max2(int a, int b) => a > b ? a : b;

  List<List<int?>> _cloneGrid(List<List<int?>> grid) => grid.map((row) => List<int?>.from(row)).toList();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
