import 'package:flutter/material.dart';

import '../../app/design_scale.dart';
import '../../app/theme.dart';
import '../../widgets/screen_background.dart';

/// "PLEASE WAIT" / "Тех. работы" maintenance card (Figma: an ornate plaque
/// floating over the shared jungle backdrop, matching the Settings/Daily
/// Bonus popup style). No remote-config/backend exists in this project to
/// trigger it automatically, so it is reachable via a hidden debug entry
/// point (tap the Settings title 5 times) for QA/demo purposes.
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DesignCanvas(
      child: ScreenBackground(
        child: SafeArea(
          child: Center(
            child: SizedBox(
              width: 344,
              height: 470,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
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
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 44, 28, 36),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text('PLEASE WAIT', textAlign: TextAlign.center, style: AppTextStyles.displayShadowed(size: 28)),
                        const SizedBox(height: 18),
                        Image.asset(
                          'assets/images/img_maintenance.png',
                          height: 150,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(Icons.build_circle, size: 96, color: AppColors.gold2),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          "The good news: once we're back, every user will receive a special "
                          "loyalty bonus. Hang tight, we're almost there!",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body(size: 15, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: Text('Back', style: AppTextStyles.display(size: 18, color: AppColors.gold2)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
