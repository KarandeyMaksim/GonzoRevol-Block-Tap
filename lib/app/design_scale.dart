import 'package:flutter/material.dart';
import 'theme.dart';

/// Wraps a screen built against the fixed Figma canvas (430x932) and scales
/// it uniformly to fit the real device viewport, preserving exact
/// proportions and positioning as specified by the design.
class DesignCanvas extends StatelessWidget {
  const DesignCanvas({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.bgTealDark,
  });

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scaleX = constraints.maxWidth / DesignConstants.canvasWidth;
          final scaleY = constraints.maxHeight / DesignConstants.canvasHeight;
          final scale = scaleX < scaleY ? scaleX : scaleY;
          return Center(
            child: SizedBox(
              width: DesignConstants.canvasWidth * scale,
              height: DesignConstants.canvasHeight * scale,
              child: OverflowBox(
                minWidth: DesignConstants.canvasWidth,
                maxWidth: DesignConstants.canvasWidth,
                minHeight: DesignConstants.canvasHeight,
                maxHeight: DesignConstants.canvasHeight,
                child: Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    width: DesignConstants.canvasWidth,
                    height: DesignConstants.canvasHeight,
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
