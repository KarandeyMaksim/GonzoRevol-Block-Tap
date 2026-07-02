import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_scale.dart';
import '../../app/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/pressable.dart';
import '../../widgets/screen_background.dart';

/// "Daily bonus!" full-screen popup (Figma node `0:279`), pixel-matched:
/// stone plaque at (51,248) 328x435, coin-bag icon at (135,389) 161x162,
/// title/subtitle centered at y=319.5/361, the dark "+1000" pill at
/// (x-center,512) 195x54, and the light "GET FREE GOLD" pill at
/// (x-center,591) 291x78. Grants +1000 coins once every ~24h.
class DailyBonusDialog extends ConsumerWidget {
  const DailyBonusDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: DesignCanvas(
        child: ScreenBackground(
          child: Stack(
            children: [
              const Positioned(
                left: 51,
                top: 248,
                width: 328,
                height: 435,
                child: _Plaque(),
              ),
              Positioned(
                left: 135,
                top: 389,
                width: 161,
                height: 162,
                child: Image.asset(
                  'assets/images/icon_coin_bag.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(Icons.card_giftcard, size: 90, color: AppColors.gold2),
                ),
              ),
              Positioned(
                left: 51,
                top: 301,
                width: 328,
                child: Text(
                  'DAILY BONUS!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displayShadowed(size: 36),
                ),
              ),
              Positioned(
                left: 51,
                top: 349,
                width: 328,
                child: Text(
                  'we give you daily bonus!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displayShadowed(size: 24),
                ),
              ),
              Positioned(
                left: 215 - 195 / 2,
                top: 512,
                width: 195,
                height: 54,
                child: _PillButton(
                  asset: 'assets/images/btn_pill_dark.png',
                  label: '+1000',
                  fontSize: 26,
                  onTap: null,
                ),
              ),
              Positioned(
                left: 215 - 291 / 2,
                top: 591,
                width: 291,
                height: 78,
                child: Pressable(
                  onTap: () {
                    ref.read(gameControllerProvider.notifier).claimDailyBonusIfAvailable();
                    Navigator.of(context).pop();
                  },
                  // Text is baked into the Figma asset itself for this label.
                  child: Image.asset(
                    'assets/images/btn_pill_orange.png',
                    fit: BoxFit.fill,
                    errorBuilder: (_, _, _) => const _PillButton(
                      asset: 'assets/images/btn_pill_light.png',
                      label: 'GET FREE GOLD',
                      fontSize: 28,
                      onTap: null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Plaque extends StatelessWidget {
  const _Plaque();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/board_plaque.png',
      fit: BoxFit.fill,
      errorBuilder: (_, _, _) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B5A3E), Color(0xFF3A2F20)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold2, width: 3),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.asset, required this.label, required this.fontSize, required this.onTap});

  final String asset;
  final String label;
  final double fontSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.asset(
              asset,
              fit: BoxFit.fill,
              errorBuilder: (_, _, _) => DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.bgTealDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold1, width: 2),
                ),
              ),
            ),
          ),
          Text(label, style: AppTextStyles.displayShadowed(size: fontSize)),
        ],
      ),
    );
  }
}
