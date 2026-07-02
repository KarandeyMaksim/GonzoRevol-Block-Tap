import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_scale.dart';
import '../../app/theme.dart';
import '../../core/audio_service.dart';
import '../../data/models.dart';
import '../../domain/board_engine.dart' show boardSize;
import '../../providers/providers.dart';
import '../../providers/round_controller.dart';
import '../../widgets/ornate_button.dart';
import '../../widgets/pressable.dart';
import '../../widgets/pulsing.dart';
import '../daily_bonus/daily_bonus_dialog.dart';
import '../settings/settings_screen.dart';
import '../shop/shop_screen.dart';
import '../wheel/wheel_screen.dart';
import '../wheel/boost_wheel_dialog.dart';
import '../withdrawal/exchange_screen.dart';
import 'board_widget.dart';
import 'piece_tray_widget.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  // Figma node `0:287`: the board frame is 358x358 on the 430-wide canvas.
  static const double _boardSizePx = 358;

  RoundPhase _lastPhase = RoundPhase.idle;
  final TextEditingController _betCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    AudioService.instance.startMusic();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowDailyBonus());
    _betCtrl.text = ref.read(gameControllerProvider).bet.toString();
  }

  void _maybeShowDailyBonus() {
    final controller = ref.read(gameControllerProvider.notifier);
    if (controller.isDailyBonusAvailable) {
      showDialog(
        context: context,
        barrierDismissible: false,
        // DailyBonusDialog renders its own full-bleed DesignCanvas (same
        // scaling contract as every other screen); showDialog's default
        // useSafeArea:true would otherwise shrink the constraints it
        // measures against, making it scale/position differently from the
        // rest of the app (letterboxed instead of a true full-screen
        // takeover).
        useSafeArea: false,
        builder: (_) => const DailyBonusDialog(),
      );
    }
  }

  @override
  void dispose() {
    _betCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameControllerProvider);
    final round = ref.watch(roundControllerProvider);

    ref.listen(roundControllerProvider, (prev, next) {
      if (next.phase != _lastPhase) {
        _lastPhase = next.phase;
        if (next.phase == RoundPhase.won) {
          _showResultOverlay(won: true, amount: next.winAmount);
        } else if (next.phase == RoundPhase.lost) {
          _showResultOverlay(won: false, amount: 0);
        }
      }
    });

    return DesignCanvas(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bg_main.png',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: AppColors.bgTealDark),
          ),
          // Figma: below the board the jungle backdrop gives way to a dark
          // stone floor (the ground the explorer + bet panel stand on) —
          // not a continuation of the teal jungle gradient.
          Positioned(
            left: 0,
            right: 0,
            top: 548,
            bottom: 0,
            child: Image.asset(
              'assets/images/bg_game_floor.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(color: const Color(0xFF4A4542)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _TopBar(balance: game.balance),
                  const SizedBox(height: 10),
                  _TimerOrStatus(round: round, game: game),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.bottomLeft,
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: BoardWidget(
                            grid: round.grid,
                            boardSizePx: _boardSizePx,
                            canPlace: (piece, r, c) => ref.read(roundControllerProvider.notifier).canPlace(piece, r, c),
                            onDrop: (idx, r, c) => ref.read(roundControllerProvider.notifier).placePiece(idx, r, c),
                          ),
                        ),
                        // Explorer character (Figma: 93x218, stands bottom-left
                        // of the board, on the rocky ground below it).
                        Positioned(
                          left: -4,
                          bottom: -8,
                          child: IgnorePointer(
                            child: Image.asset(
                              'assets/images/hero_game.png',
                              height: 150,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (round.phase == RoundPhase.playing) ...[
                    // Match the board's own cell size so a dragged piece keeps
                    // the exact same scale from the tray to the drop target.
                    PieceTray(tray: round.tray, cellSize: (_boardSizePx - BoardWidget.framePadding * 2) / boardSize),
                    const SizedBox(height: 10),
                  ],
                  _BottomPanel(betController: _betCtrl),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResultOverlay({required bool won, required int amount}) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _RoundResultOverlay(won: won, amount: amount),
    ).then((_) {
      ref.read(roundControllerProvider.notifier).finishRound();
    });
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.balance});
  final int balance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Figma node `0:287`: 144x54 balance pill, then 4x 53px icons with a
    // 13px gap after the pill and 7px gaps between icons (sums exactly to
    // the 390px usable width once the icons are 53px, not 44px).
    return Row(
      children: [
        _BalancePill(balance: balance),
        const SizedBox(width: 13),
        _NavIcon(asset: 'assets/images/icon_shop.png', fallback: Icons.storefront, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopScreen()))),
        const SizedBox(width: 7),
        _NavIcon(asset: 'assets/images/icon_withdraw.png', fallback: Icons.account_balance_wallet, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExchangeScreen()))),
        const SizedBox(width: 7),
        _NavIcon(
          asset: 'assets/images/icon_wheel.png',
          fallback: Icons.donut_large,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WheelScreen())),
          badge: const _WheelCooldownBadge(),
        ),
        const SizedBox(width: 7),
        _NavIcon(asset: 'assets/images/icon_settings.png', fallback: Icons.settings, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()))),
      ],
    );
  }
}

class _BalancePill extends StatelessWidget {
  const _BalancePill({required this.balance});
  final int balance;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 144,
      height: 54,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/btn_pill_light.png',
              fit: BoxFit.fill,
              errorBuilder: (_, _, _) => DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(color: const Color(0xFF3B2A16), width: 2),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB08A55), Color(0xFF6E4A28)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 11,
            top: 11,
            width: 32,
            height: 32,
            child: Image.asset(
              'assets/images/icon_coin_solo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(left: 30, right: 10),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  _formatBalance(balance),
                  style: AppTextStyles.displayShadowed(size: 24),
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatBalance(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.asset, required this.fallback, required this.onTap, this.badge});
  final String asset;
  final IconData fallback;
  final VoidCallback onTap;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _icon(),
          if (badge != null) Positioned(top: -4, right: -4, child: badge!),
        ],
      ),
    );
  }

  Widget _icon() {
    return SizedBox(
        width: 53,
        height: 53,
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFCBA45C), Color(0xFF7A5326)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0xFF3B2A16), width: 2),
            ),
            child: Icon(fallback, color: AppColors.cream, size: 24),
          ),
        ),
      );
  }
}

/// Small countdown pill shown on the wheel nav icon whenever the 12h
/// cooldown is active, so the timer is visible on the main screen too (not
/// just inside the Wheel of Luck screen) — per dev instructions §8.
class _WheelCooldownBadge extends ConsumerStatefulWidget {
  const _WheelCooldownBadge();

  @override
  ConsumerState<_WheelCooldownBadge> createState() => _WheelCooldownBadgeState();
}

class _WheelCooldownBadgeState extends ConsumerState<_WheelCooldownBadge> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameControllerProvider);
    if (game.isWheelReady) return const SizedBox.shrink();
    final remaining = game.wheelCooldownUntil!.difference(DateTime.now());
    if (remaining.isNegative) return const SizedBox.shrink();
    final label = remaining.inHours >= 1 ? '${remaining.inHours}h' : '${remaining.inMinutes.clamp(1, 59)}m';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.bgTealDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold2, width: 1),
      ),
      child: Text(label, style: AppTextStyles.display(size: 10, weight: FontWeight.w700, color: AppColors.gold2)),
    );
  }
}

class _TimerOrStatus extends StatelessWidget {
  const _TimerOrStatus({required this.round, required this.game});
  final RoundState round;
  final GameData game;

  @override
  Widget build(BuildContext context) {
    if (round.phase == RoundPhase.playing) {
      final m = (round.secondsRemaining ~/ 60).toString().padLeft(2, '0');
      final s = (round.secondsRemaining % 60).toString().padLeft(2, '0');
      return _timerRow('$m:$s');
    }
    if (game.hasActiveBonus) {
      return Text('BONUS +${game.bonusPercent}%', style: AppTextStyles.displayShadowed(size: 22, color: AppColors.gold2));
    }
    if (game.freeSpins > 0) {
      return Text('${game.freeSpins} FREE SPINS', style: AppTextStyles.displayShadowed(size: 20));
    }
    return const SizedBox(height: 40);
  }

  // Figma node `0:287`: "01:23" in Gemunu Libre Regular @40, with a small
  // gold clock medallion to its right.
  Widget _timerRow(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text, style: AppTextStyles.displayShadowed(size: 40, weight: FontWeight.w400)),
        const SizedBox(width: 8),
        Image.asset(
          'assets/images/icon_clock_small.png',
          width: 26,
          height: 26,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _BottomPanel extends ConsumerWidget {
  const _BottomPanel({required this.betController});
  final TextEditingController betController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final round = ref.watch(roundControllerProvider);
    final roundNotifier = ref.read(roundControllerProvider.notifier);
    final gameNotifier = ref.read(gameControllerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.trayPanel,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.trayPanelBorder, width: 2),
      ),
      child: switch (round.phase) {
        RoundPhase.won => SolidGradientButton(
            label: 'Collect  +${round.winAmount}',
            colors: const [AppColors.collectBtnTop, AppColors.collectBtnMid],
            fontSize: 26,
            onTap: () => roundNotifier.finishRound(),
          ),
        RoundPhase.lost => Text(
            'Round lost — try again!',
            textAlign: TextAlign.center,
            style: AppTextStyles.display(size: 22),
          ),
        RoundPhase.playing => round.winAmount > 0
            ? Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Current win', style: AppTextStyles.body(size: 12, color: AppColors.cream)),
                        Text('+${round.winAmount}', style: AppTextStyles.displayShadowed(size: 24, color: AppColors.gold2)),
                      ],
                    ),
                  ),
                  SolidGradientButton(
                    label: 'Collect',
                    width: 140,
                    height: 48,
                    fontSize: 22,
                    colors: const [AppColors.collectBtnTop, AppColors.collectBtnMid],
                    onTap: () => roundNotifier.collect(),
                  ),
                ],
              )
            : Text(
                'Drag pieces onto the board',
                textAlign: TextAlign.center,
                style: AppTextStyles.body(size: 15, color: AppColors.cream),
              ),
        RoundPhase.idle => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Figma: one continuous gold gradient bar (46px tall) spanning
              // the full row, with the MIN/MAX pills overlapping its ends
              // and the editable bet amount sitting directly on top of it —
              // not three separate side-by-side elements.
              SizedBox(
                height: 46,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(child: _BetField(controller: betController, onChanged: gameNotifier.setBet)),
                    Positioned(
                      left: 0,
                      child: _MiniPill(
                        label: 'MIN',
                        onTap: () {
                          betController.text = '1';
                          gameNotifier.setBet(1);
                        },
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: _MiniPill(
                        label: 'MAX',
                        onTap: () {
                          final max = gameNotifier.maxAllowedBet;
                          betController.text = max.toString();
                          gameNotifier.setBet(max);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _RiskDropdown(
                value: game.betRisk,
                onChanged: (risk) => gameNotifier.setBetRisk(risk),
              ),
              const SizedBox(height: 12),
              SolidGradientButton(
                label: 'Play',
                fontSize: 40,
                enabled: game.balance >= game.bet,
                onTap: () => roundNotifier.startRound(),
              ),
              if (game.freeSpins > 0) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => roundNotifier.startRound(useFreeSpin: true),
                  child: Text(
                    'Use a free spin (${game.freeSpins} left)',
                    style: AppTextStyles.body(size: 13, color: AppColors.gold2),
                  ),
                ),
              ],
            ],
          ),
      },
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 53,
        height: 34,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF225A31)),
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF7BBF53),
          boxShadow: const [
            BoxShadow(color: Color(0xFF276427), blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.display(size: 15, color: AppColors.cream, weight: FontWeight.w400).copyWith(
            color: AppColors.cream.withValues(alpha: 0.73),
          ),
        ),
      ),
    );
  }
}

class _BetField extends StatelessWidget {
  const _BetField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 53), // clear the MIN/MAX pills overlapping the ends
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold1, width: 2),
        gradient: LinearGradient(
          colors: [AppColors.gold1.withValues(alpha: .82), AppColors.gold2.withValues(alpha: .82), AppColors.gold3.withValues(alpha: .82)],
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: AppTextStyles.display(size: 28, weight: FontWeight.w400),
        decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true),
        onChanged: (v) {
          final n = int.tryParse(v);
          if (n != null && n > 0) onChanged(n);
        },
      ),
    );
  }
}

class _RiskDropdown extends StatelessWidget {
  const _RiskDropdown({required this.value, required this.onChanged});
  final BetRisk value;
  final ValueChanged<BetRisk> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppColors.dropdownBg, borderRadius: BorderRadius.circular(3)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BetRisk>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.dropdownBg,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.cream),
          style: AppTextStyles.display(size: 26, weight: FontWeight.w400),
          items: BetRisk.values
              .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
              .toList(),
          onChanged: (r) {
            if (r != null) onChanged(r);
          },
        ),
      ),
    );
  }
}

class _RoundResultOverlay extends ConsumerStatefulWidget {
  const _RoundResultOverlay({required this.won, required this.amount});
  final bool won;
  final int amount;

  @override
  ConsumerState<_RoundResultOverlay> createState() => _RoundResultOverlayState();
}

class _RoundResultOverlayState extends ConsumerState<_RoundResultOverlay> {
  bool _showBoost = false;
  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    if (widget.won) {
      // The per-line-clear "win" cue only fires mid-round; the actual
      // "you won the round" moment (this overlay) needs its own fanfare
      // regardless of whether a clear happened right before it.
      AudioService.instance.win();
      // Per "Реклама в приложениях.md" §3: show "You win! <amount>" for 2s,
      // then reveal the pulsing Boost Reward CTA.
      _autoClose = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showBoost = true);
      });
    } else {
      // Loss cue is already triggered by RoundController._resolveLoss() at
      // the moment the phase flips, so nothing extra to play here.
      _autoClose = Timer(const Duration(milliseconds: 1500), _close);
    }
  }

  void _close() {
    if (mounted) Navigator.of(context).pop();
  }

  void _onTap() {
    // Per dev instructions §14/§12: the 1.5s win/loss notice must be
    // dismissible early by tapping anywhere. For a win, "dismissing" means
    // skipping straight to the boost-wheel prompt rather than the timer
    // doing it automatically.
    if (widget.won && !_showBoost) {
      _autoClose?.cancel();
      setState(() => _showBoost = true);
      return;
    }
    if (!widget.won) _close();
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bgTealDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gold2, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.won ? 'YOU WIN!' : 'ROUND LOST',
                style: AppTextStyles.displayShadowed(size: 32, color: widget.won ? AppColors.gold2 : AppColors.cream),
              ),
              if (widget.won) ...[
                const SizedBox(height: 8),
                Text('+\$${widget.amount}', style: AppTextStyles.display(size: 26)),
              ],
              const SizedBox(height: 20),
              if (widget.won && _showBoost)
                _PulsingBoostButton(
                  onTap: () async {
                    Navigator.of(context).pop();
                    final claimed = await showDialog<int>(
                      context: context,
                      builder: (_) => BoostWheelDialog(baseAmount: widget.amount),
                    );
                    if (claimed != null) {
                      ref.read(gameControllerProvider.notifier).grantWinnings(claimed);
                    }
                  },
                )
              else
                Text(
                  widget.won ? 'Tap to continue…' : 'Tap to try again',
                  style: AppTextStyles.body(size: 14, color: AppColors.cream),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingBoostButton extends StatelessWidget {
  const _PulsingBoostButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pulsing(
      child: SolidGradientButton(
        label: 'BOOST REWARD',
        fontSize: 20,
        colors: const [AppColors.gold3, AppColors.gold1],
        icon: Icons.play_circle_fill,
        onTap: onTap,
      ),
    );
  }
}
