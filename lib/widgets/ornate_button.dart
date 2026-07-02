import 'package:flutter/material.dart';
import '../app/theme.dart';
import 'pressable.dart';

/// The carved stone/gold pill button reused across the whole app (Play,
/// Spin, Let's Play, Exchange, etc.) — rendered with the real exported
/// Figma texture (`btn_pill_variant_a.png`), scaled to fill the button's
/// bounds (matching Figma's own image-fill approach for this component).
class OrnateButton extends StatelessWidget {
  const OrnateButton({
    super.key,
    required this.label,
    this.onTap,
    this.height = 60,
    this.fontSize = 28,
    this.enabled = true,
    this.width,
    this.leading,
    this.trailing,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;
  final bool enabled;
  /// Defaults to filling the available width — every Figma occurrence of
  /// this button is a wide pill, not a text-hugging chip.
  final double? width;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Pressable(
        enabled: enabled,
        onTap: onTap,
        child: SizedBox(
          width: width ?? double.infinity,
          height: height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/btn_pill_variant_a.png',
                  // The source texture's aspect ratio (~3.6:1) already closely
                  // matches every pill button's target aspect ratio in the
                  // design, so a direct scaled fill (matching Figma's own
                  // image-fill approach) looks crisp without needing a
                  // nine-slice, which degenerates when a button is narrower
                  // than twice its carved end-cap width.
                  fit: BoxFit.fill,
                  errorBuilder: (_, _, _) => DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(height / 2),
                      border: Border.all(color: const Color(0xFF3B2A16), width: 2),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFB08A55), Color(0xFF6E4A28), Color(0xFF8C6535)],
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 8)],
                  Text(
                    label,
                    style: AppTextStyles.displayShadowed(size: fontSize, weight: FontWeight.w600),
                  ),
                  if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Solid orange gradient CTA (Play / IAP buy buttons — node `go` / `BuyBtn`).
class SolidGradientButton extends StatelessWidget {
  const SolidGradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.height = 58,
    this.fontSize = 30,
    this.colors = const [AppColors.playBtnTop, AppColors.playBtnBottom],
    this.borderRadius = 5,
    this.enabled = true,
    this.width,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;
  final List<Color> colors;
  final double borderRadius;
  final bool enabled;
  /// Defaults to filling the available width, matching the wide CTA pills
  /// used throughout the Figma file.
  final double? width;
  /// Rewarded-video CTAs show a small play icon in the button itself, per
  /// dev instructions ("значок с видео в этой кнопке").
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Pressable(
        enabled: enabled,
        onTap: onTap,
        child: Container(
          width: width ?? double.infinity,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
            border: Border.all(color: const Color(0xFF3B2A16), width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.display(size: fontSize, weight: FontWeight.w500),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, color: AppColors.cream, size: fontSize * 0.8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
