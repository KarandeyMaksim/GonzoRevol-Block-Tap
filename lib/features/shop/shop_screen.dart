import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/design_scale.dart';
import '../../app/theme.dart';
import '../../core/ads_service.dart';
import '../../core/analytics_service.dart';
import '../../core/constants.dart';
import '../../core/iap_service.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';
import '../../widgets/pressable.dart';
import '../../widgets/screen_background.dart';
import '../../widgets/screen_header.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  bool _claimingAd = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.paywallView('shop');
    IapService.instance.onPurchaseSuccess = _onPurchaseSuccess;
    IapService.instance.onPurchaseError = _onPurchaseError;
  }

  @override
  void dispose() {
    AnalyticsService.instance.paywallClose('shop');
    super.dispose();
  }

  void _onPurchaseSuccess(String productId) {
    final pkg = ShopPackage.all.firstWhere((p) => p.id == productId, orElse: () => ShopPackage.starter);
    ref.read(gameControllerProvider.notifier).applyShopPackage(pkg);
    AnalyticsService.instance.purchaseSuccess(productId, price: _priceFor(pkg));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${pkg.title} purchased!')));
    }
  }

  void _onPurchaseError(String productId, String error) {
    AnalyticsService.instance.purchaseError(productId, error);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purchase unavailable: $error')));
    }
  }

  /// Real store price when the SKU is live, else the Figma-listed price
  /// (dev-mode grant flow, before the listing exists on either store).
  double _priceFor(ShopPackage pkg) =>
      IapService.instance.productFor(pkg.id)?.rawPrice ??
      double.tryParse(pkg.priceLabel.replaceAll(RegExp(r'[^0-9.]'), '')) ??
      0;

  Future<void> _buy(ShopPackage pkg) async {
    AnalyticsService.instance.purchaseClick(pkg.id);
    if (!IapService.instance.available || IapService.instance.productFor(pkg.id) == null) {
      // Store listing not published yet — TZ has no backend either, so grant
      // the package directly to keep the flow fully testable end-to-end.
      ref.read(gameControllerProvider.notifier).applyShopPackage(pkg);
      AnalyticsService.instance.purchaseSuccess(pkg.id, price: _priceFor(pkg));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${pkg.title} granted (store not live yet — dev mode).')),
      );
      return;
    }
    await IapService.instance.buy(pkg.id);
  }

  Future<void> _watchAdForCoins() async {
    setState(() => _claimingAd = true);
    AnalyticsService.instance.rewardedAdShown('shop_free_coins');
    final watched = await AdsService.instance.showRewarded();
    if (watched) {
      AnalyticsService.instance.rewardedAdReward('shop_free_coins');
      ref.read(gameControllerProvider.notifier).addCoins(1000);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('+1000 coins!')));
    }
    if (mounted) setState(() => _claimingAd = false);
  }

  @override
  Widget build(BuildContext context) {
    // Figma shop frame (430x932): compact Starter/Premium cards sit in the
    // upper-middle area; VIP + legal links are pinned to the bottom. Using
    // fixed positions prevents the cards from stretching with Column/Expanded.
    const side = 24.0;
    const cardGap = 12.0;
    const cardWidth = (430 - side * 2 - cardGap) / 2; // 185
    const packageTop = 168.0; // below header + free-coins row
    const packageHeight = 280.0;

    return DesignCanvas(
      child: ScreenBackground(
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(left: side, right: side, top: 40, child: ScreenHeader(title: 'Shop')),
              Positioned(
                left: side,
                right: side,
                top: 88,
                child: _FreeCoinsCard(loading: _claimingAd, onTap: _watchAdForCoins),
              ),
              Positioned(
                left: side,
                top: packageTop,
                width: cardWidth,
                height: packageHeight,
                child: _PackageCard(pkg: ShopPackage.starter, onBuy: () => _buy(ShopPackage.starter)),
              ),
              Positioned(
                left: side + cardWidth + cardGap,
                top: packageTop,
                width: cardWidth,
                height: packageHeight,
                child: _PackageCard(pkg: ShopPackage.premium, onBuy: () => _buy(ShopPackage.premium)),
              ),
              Positioned(
                left: side,
                right: side,
                bottom: 56,
                child: _VipCard(onBuy: () => _buy(ShopPackage.vip)),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ShopLinkText('Terms of Use', AppConstants.termsOfUseUrl),
                    const SizedBox(width: 16),
                    _ShopLinkText('Privacy Policy', AppConstants.privacyPolicyUrl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FreeCoinsCard extends StatelessWidget {
  const _FreeCoinsCard({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      enabled: !loading,
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.shopCardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.shopCardBorder, width: 2),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/images/img_coins_pile.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(Icons.monetization_on, color: AppColors.gold1, size: 34),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '1000 FREE COINS',
                style: _shopTitleStyle(size: 18, color: AppColors.shopCardTitle),
              ),
            ),
            loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.play_circle_fill, color: AppColors.shopCardTitle, size: 32),
          ],
        ),
      ),
    );
  }
}

TextStyle _shopTitleStyle({required double size, required Color color}) =>
    AppTextStyles.display(size: size, color: color, weight: FontWeight.w800);

/// Per dev instructions: ToS/Privacy must be reachable from every screen
/// with $ purchases, not just Settings and Let's Play.
class _ShopLinkText extends StatelessWidget {
  const _ShopLinkText(this.label, this.url);
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Text(
        label,
        style: AppTextStyles.body(size: 12, color: AppColors.cream).copyWith(decoration: TextDecoration.underline),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.pkg, required this.onBuy});
  final ShopPackage pkg;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    // Figma: Starter shows a loose coin pile, Premium a tied coin bag.
    final art = pkg.id == ShopPackage.starter.id ? 'assets/images/img_coins_pile.png' : 'assets/images/icon_coin_bag.png';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.shopCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.shopCardBorder, width: 2),
      ),
      child: Column(
        children: [
          Image.asset(
            art,
            height: 52,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(Icons.savings, size: 48, color: AppColors.gold1),
          ),
          const SizedBox(height: 6),
          Text(
            pkg.title.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _shopTitleStyle(size: 15, color: AppColors.shopCardTitle),
          ),
          const SizedBox(height: 6),
          _bullet('${_fmt(pkg.coins)} Coins'),
          _bullet('${pkg.freeSpins} Free Spins'),
          _bullet('+${pkg.bonusPercent}% Bonus on Every Win for ${pkg.bonusDays} Days'),
          const Spacer(),
          _BuyButton(label: pkg.priceLabel, onTap: onBuy),
        ],
      ),
    );
  }

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Text(
          '• $text',
          textAlign: TextAlign.center,
          style: AppTextStyles.display(size: 11, color: AppColors.shopCardTitle, weight: FontWeight.w700),
        ),
      );

  static String _fmt(int v) => v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
}

class _VipCard extends StatelessWidget {
  const _VipCard({required this.onBuy});
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final pkg = ShopPackage.vip;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.shopCardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.shopCardBorder, width: 2),
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/images/icon_treasure_chest.png',
                width: 64,
                height: 64,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(Icons.inventory_2_rounded, size: 60, color: AppColors.gold1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VIP PACK', style: AppTextStyles.display(size: 18, color: AppColors.cream, weight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('• ${pkg.coins} Coins   • ${pkg.freeSpins} Free Spins', style: AppTextStyles.display(size: 12, color: AppColors.shopCardTitle, weight: FontWeight.w700)),
                    Text('• +${pkg.bonusPercent}% Bonus for ${pkg.bonusDays} Days   • Priority Withdrawal', style: AppTextStyles.display(size: 12, color: AppColors.shopCardTitle, weight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _BuyButton(label: pkg.priceLabel, onTap: onBuy),
            ],
          ),
        ),
        Positioned(
          top: -6,
          right: 8,
          child: Transform.rotate(
            angle: 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]), borderRadius: BorderRadius.circular(4)),
              child: const Text('EXCLUSIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
            ),
          ),
        ),
      ],
    );
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: AppColors.buyBtnBorder),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.buyBtnTop, AppColors.buyBtnBottom]),
        ),
        child: Text(label, style: AppTextStyles.display(size: 18, weight: FontWeight.w800)),
      ),
    );
  }
}
