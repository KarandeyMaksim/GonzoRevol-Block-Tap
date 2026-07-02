import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_scale.dart';
import '../../app/theme.dart';
import '../../core/analytics_service.dart';
import '../../core/constants.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';
import '../../widgets/ornate_button.dart';
import '../../widgets/pressable.dart';
import '../../widgets/screen_background.dart';
import '../../widgets/screen_header.dart';
import 'add_payout_method_screen.dart';
import 'connect_method_dialog.dart';
import 'payment_icon.dart';

/// Node `0:...` "Exchange" screen — converts in-game coins into USD once
/// enough coins have been wagered (progress bar fills as bets are placed),
/// then lets the player cash out the USD balance to a connected payout
/// method. Matches the Figma reference ("Exchange.png").
class ExchangeScreen extends ConsumerStatefulWidget {
  const ExchangeScreen({super.key});

  @override
  ConsumerState<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends ConsumerState<ExchangeScreen> {
  double _amount = 1;
  String? _selectedMethod;

  /// Curated quick-select subset shown on this screen, matching the exact
  /// brands + order depicted in the Figma reference.
  static const _quickMethods = ['paypal', 'visa', 'usdt_trc20', 'google_pay', 'btc', 'eth'];

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    // Tracks the live coin balance itself (not a separate wagering counter):
    // "1/10000", then once past 10 000 it targets the next multiple, e.g.
    // "12300/20000" — per "Инструкция для разработчиков.md" §13.
    final exchangeTarget = game.exchangeTarget;
    final progress = game.balance / exchangeTarget;
    final connected = game.connectedPayoutMethods.keys.toList();
    _selectedMethod ??= connected.isNotEmpty ? connected.first : null;

    return DesignCanvas(
      child: ScreenBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
            child: Column(
              children: [
                const ScreenHeader(title: 'Exchange'),
                const SizedBox(height: 26),
                OrnateButton(
                  label: '+ Add payout method',
                  height: 60,
                  fontSize: 18,
                  trailing: const Icon(Icons.arrow_forward, color: AppColors.cream, size: 20),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddPayoutMethodScreen())),
                ),
                const SizedBox(height: 34),
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0, 1),
                          minHeight: 17,
                          // Filled = coins wagered so far (dark maroon); the
                          // lighter salmon is the remaining distance to the
                          // next payout tier — matches the reference exactly.
                          backgroundColor: AppColors.exchangeBarFilled,
                          color: AppColors.exchangeBarBase,
                        ),
                      ),
                      Positioned(
                        right: -22,
                        top: -3,
                        child: Image.asset(
                          'assets/images/icon_coin_solo.png',
                          width: 23,
                          height: 23,
                          errorBuilder: (_, _, _) => const Icon(Icons.circle, color: AppColors.gold2, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${game.balance}/$exchangeTarget', style: AppTextStyles.body(size: 14, color: AppColors.cream)),
                    OrnateButton(
                      label: 'Play to Start',
                      width: 150,
                      height: 40,
                      fontSize: 14,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                OrnateButton(
                  label: '${AppConstants.exchangeStep} -> \$${AppConstants.exchangeUsdPerStep.toStringAsFixed(0)}',
                  height: 46,
                  fontSize: 18,
                  enabled: game.canExchange,
                  onTap: () {
                    final ok = controller.exchange(AppConstants.exchangeUsdPerStep, AppConstants.exchangeStep);
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Converted to \$5!')));
                    }
                  },
                ),
                const SizedBox(height: 30),
                const Divider(color: Colors.black45),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _quickMethods.map((id) {
                    final m = PayoutMethodDef.all.firstWhere((e) => e.id == id);
                    final isConnected = game.connectedPayoutMethods.containsKey(m.id);
                    final selected = _selectedMethod == m.id;
                    return Pressable(
                      onTap: isConnected
                          ? () => setState(() => _selectedMethod = m.id)
                          : () => ConnectMethodDialog.show(context, m),
                      child: PaymentIcon(methodId: m.id, size: 44, dimmed: !isConnected, selected: selected),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFB6E8C4), Color(0xFF66826E)]),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Balance', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                      Text('${game.usdBalance.toStringAsFixed(2)} \$', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 18)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('\$ 1', style: AppTextStyles.body(size: 14, color: AppColors.cream, weight: FontWeight.w600)),
                    Text('\$ 100', style: AppTextStyles.body(size: 14, color: AppColors.cream, weight: FontWeight.w600)),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.exchangeSliderTrack,
                    inactiveTrackColor: AppColors.exchangeSliderTrack,
                    thumbColor: AppColors.bgTealDark,
                  ),
                  child: Slider(
                    value: _amount,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    label: '\$${_amount.round()}',
                    onChanged: (v) => setState(() => _amount = v),
                  ),
                ),
                const SizedBox(height: 20),
                OrnateButton(
                  label: 'Exchange',
                  height: 58,
                  fontSize: 26,
                  enabled: game.usdBalance >= _amount && _selectedMethod != null,
                  onTap: () {
                    final ok = controller.withdrawUsd(_amount);
                    if (ok) {
                      AnalyticsService.instance.withdrawalRequest(_amount);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Withdrawal of \$${_amount.round()} requested!')));
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  game.usdBalance < 100 ? 'Get \$${(100 - game.usdBalance).toStringAsFixed(0)} more to exchange.' : 'Ready to exchange.',
                  style: AppTextStyles.body(size: 13, color: AppColors.cream),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
