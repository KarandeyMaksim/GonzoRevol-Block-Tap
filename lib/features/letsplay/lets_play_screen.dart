import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/design_scale.dart';
import '../../app/theme.dart';
import '../../core/audio_service.dart';
import '../../core/constants.dart';
import '../../widgets/ornate_button.dart';
import '../../widgets/screen_background.dart';
import '../game/game_screen.dart';

/// Node `0:267` ("Splash screen" / Let's Play) — pixel-matched to Figma:
/// logo at (51,90) 360x162, hero art at (50,252) 330x450, the "LET'S PLAY"
/// pill at (51,705) 328x78, and the two disclaimer lines (black Roboto)
/// pinned at y=830 / y=861 on the 430x932 canvas.
class LetsPlayScreen extends ConsumerStatefulWidget {
  const LetsPlayScreen({super.key});

  @override
  ConsumerState<LetsPlayScreen> createState() => _LetsPlayScreenState();
}

class _LetsPlayScreenState extends ConsumerState<LetsPlayScreen> {
  @override
  void initState() {
    super.initState();
    AudioService.instance.startMusic();
  }

  @override
  Widget build(BuildContext context) {
    return DesignCanvas(
      child: ScreenBackground(
        child: Stack(
          children: [
            Positioned(
              left: 51,
              top: 90,
              width: 360,
              height: 162,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Text(
                  'GonzoRevol Block Tap',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displayShadowed(size: 30, color: AppColors.gold2),
                ),
              ),
            ),
            Positioned(
              left: 50,
              top: 252,
              width: 330,
              height: 450,
              child: Image.asset(
                'assets/images/hero_letsplay.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            Positioned(
              left: 51,
              top: 705,
              width: 328,
              height: 78,
              child: OrnateButton(
                label: "LET'S PLAY",
                width: 328,
                height: 78,
                fontSize: 36,
                onTap: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GameScreen()));
                },
              ),
            ),
            Positioned(
              // Figma centers this node vertically at y=830; it wraps to two
              // lines at 20px, so the box top is offset up by ~half that
              // wrapped height to keep the visual center pinned at 830.
              left: 51,
              top: 806,
              width: 328,
              child: Text(
                'By tapping “Let’s Play” you confirm that you 18+ and',
                textAlign: TextAlign.center,
                style: AppTextStyles.body(size: 20, color: Colors.black),
              ),
            ),
            Positioned(
              left: 51,
              top: 852,
              width: 328,
              child: _LegalLine(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.body(size: 16, color: Colors.black);
    final linkStyle = style.copyWith(decoration: TextDecoration.underline);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          const TextSpan(text: 'our '),
          TextSpan(
            text: 'Terms of Use',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchUrl(Uri.parse(AppConstants.termsOfUseUrl), mode: LaunchMode.externalApplication),
          ),
          const TextSpan(text: ' & '),
          TextSpan(
            text: 'Privacy Policy',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchUrl(Uri.parse(AppConstants.privacyPolicyUrl), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
