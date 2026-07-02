import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Small circular brand badge for a payout method. Recreated natively
/// (color + glyph) rather than bundling every payment-network logo asset.
class PaymentIcon extends StatelessWidget {
  const PaymentIcon({super.key, required this.methodId, this.size = 50, this.dimmed = false, this.selected = false});

  final String methodId;
  final double size;
  final bool dimmed;
  final bool selected;

  /// Real brand marks cropped straight from the Figma payment-method sheet.
  /// Only methods that file actually depicts get a photographic badge —
  /// everything else keeps the recreated colour+glyph badge below so we
  /// never show a made-up logo for a brand we don't have art for.
  static const _realIcons = <String, String>{
    'paypal': 'assets/images/payments/paypal.png',
    'visa': 'assets/images/payments/visa.png',
    'mastercard': 'assets/images/payments/mastercard.png',
    'usdt_trc20': 'assets/images/payments/usdt.png',
    'usdt_erc20': 'assets/images/payments/usdt.png',
    'google_pay': 'assets/images/payments/google_pay.png',
    'samsung_pay': 'assets/images/payments/samsung_pay.png',
    'payeer': 'assets/images/payments/payeer.png',
    'btc': 'assets/images/payments/btc.png',
    'bank_transfer': 'assets/images/payments/sepa.png',
    'apple_pay': 'assets/images/payments/apple_pay.png',
    'applepay_cash': 'assets/images/payments/cashapp.png',
  };

  static const _colors = <String, Color>{
    'paypal': Color(0xFF0070BA),
    'visa': Color(0xFF1A1F71),
    'mastercard': Color(0xFFEB001B),
    'usdt_trc20': Color(0xFF26A17B),
    'usdt_erc20': Color(0xFF26A17B),
    'google_pay': Color(0xFFFFFFFF),
    'samsung_pay': Color(0xFF1428A0),
    'payeer': Color(0xFF1877C9),
    'btc': Color(0xFFF7931A),
    'eth': Color(0xFF627EEA),
    'mir': Color(0xFF4DB45E),
    'qiwi': Color(0xFFFF8C00),
    'webmoney': Color(0xFF2A5ADA),
    'skrill': Color(0xFF862165),
    'neteller': Color(0xFF6EBE49),
    'perfect_money': Color(0xFF00559B),
    'advcash': Color(0xFF1B4F9C),
    'litecoin': Color(0xFF345D9D),
    'tron': Color(0xFFEB0029),
    'bank_transfer': Color(0xFF4A4A4A),
    'apple_pay': Color(0xFF000000),
    'applepay_cash': Color(0xFF00C853),
    'paysafecard': Color(0xFFEE7203),
    'unionpay': Color(0xFFE21836),
    'jeton': Color(0xFF6A1B9A),
    'astropay': Color(0xFFFF5C00),
  };

  static const _labels = <String, String>{
    'paypal': 'P',
    'visa': 'V',
    'mastercard': 'MC',
    'usdt_trc20': 'T',
    'usdt_erc20': 'T',
    'google_pay': 'G',
    'samsung_pay': 'Pay',
    'payeer': 'P',
    'btc': '₿',
    'eth': 'Ξ',
    'mir': 'MIR',
    'qiwi': 'Q',
    'webmoney': 'WM',
    'skrill': 'S',
    'neteller': 'N',
    'perfect_money': 'PM',
    'advcash': 'AC',
    'litecoin': 'Ł',
    'tron': 'TRX',
    'bank_transfer': 'B',
    'apple_pay': '',
    'applepay_cash': '\$',
    'paysafecard': 'PSC',
    'unionpay': 'UP',
    'jeton': 'J',
    'astropay': 'A',
  };

  @override
  Widget build(BuildContext context) {
    final realAsset = _realIcons[methodId];
    return Opacity(
      opacity: dimmed ? 0.4 : 1,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: realAsset != null ? Colors.white : null,
          border: Border.all(color: selected ? AppColors.gold2 : Colors.white24, width: selected ? 3 : 1.5),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))],
        ),
        alignment: Alignment.center,
        child: realAsset != null
            ? ClipOval(
                child: Padding(
                  padding: EdgeInsets.all(size * 0.06),
                  child: Image.asset(realAsset, fit: BoxFit.contain, errorBuilder: (_, _, _) => _fallback(size)),
                ),
              )
            : _fallback(size),
      ),
    );
  }

  Widget _fallback(double size) {
    final color = _colors[methodId] ?? AppColors.gold1;
    final label = _labels[methodId] ?? '?';
    final textColor = color.computeLuminance() > 0.6 ? Colors.black : Colors.white;
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: switch (methodId) {
            'apple_pay' => Icon(Icons.apple, color: textColor, size: size * 0.5),
            // The Greek Xi glyph doesn't render on every platform font —
            // a diamond glyph is close enough to Ethereum's real mark.
            'eth' => Icon(Icons.diamond, color: textColor, size: size * 0.42),
            _ => Text(
                label,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: size * 0.32),
              ),
          },
        ),
      ),
    );
  }
}
