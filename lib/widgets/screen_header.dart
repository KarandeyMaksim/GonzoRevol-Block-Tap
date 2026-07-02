import 'package:flutter/material.dart';
import '../app/theme.dart';
import 'pressable.dart';

/// Back-arrow + centered uppercase title reused by every secondary screen
/// (Settings, Shop, Wheel of Luck, Exchange, Add payout method...).
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTextStyles.display(size: 24, weight: FontWeight.w600),
          ),
          Positioned(
            left: 0,
            child: Pressable(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: const Icon(Icons.arrow_back, color: AppColors.cream, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
