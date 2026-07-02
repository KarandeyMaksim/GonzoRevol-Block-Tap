import 'package:flutter/material.dart';
import '../app/theme.dart';

/// The shared jungle-temple background image used by every screen in the
/// Figma file (node `bg`, reused identically across all frames).
class ScreenBackground extends StatelessWidget {
  const ScreenBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/bg_main.png',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(color: AppColors.bgTealDark),
        ),
        child,
      ],
    );
  }
}
