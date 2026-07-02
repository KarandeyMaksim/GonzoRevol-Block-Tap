import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/design_scale.dart';
import '../../app/theme.dart';
import '../../core/analytics_service.dart';
import '../../core/constants.dart';
import '../../providers/providers.dart';
import '../../widgets/ornate_button.dart';
import '../../widgets/pressable.dart';
import '../../widgets/screen_background.dart';
import '../../widgets/screen_header.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../maintenance/maintenance_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _titleTaps = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.settingsOpen();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final settings = game.settings;

    return DesignCanvas(
      child: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 51),
            child: Column(
              children: [
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () {
                    _titleTaps++;
                    if (_titleTaps >= 5) {
                      _titleTaps = 0;
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MaintenanceScreen()));
                    }
                  },
                  child: const ScreenHeader(title: 'Settings'),
                ),
                const SizedBox(height: 30),
                _Panel(
                  children: [
                    _SliderRow(
                      label: 'Sound',
                      value: settings.soundVolume,
                      onChanged: (v) => controller.updateSettings(settings.copyWith(soundVolume: v)),
                    ),
                    const SizedBox(height: 24),
                    _SliderRow(
                      label: 'Music',
                      value: settings.musicVolume,
                      onChanged: (v) => controller.updateSettings(settings.copyWith(musicVolume: v)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _Panel(
                  children: [
                    _ToggleRow(
                      label: 'Vibration',
                      value: settings.vibrationEnabled,
                      onChanged: (v) => controller.updateSettings(settings.copyWith(vibrationEnabled: v)),
                    ),
                    const SizedBox(height: 18),
                    _ToggleRow(
                      label: 'Notifications',
                      value: settings.notificationsEnabled,
                      onChanged: (v) => controller.updateSettings(settings.copyWith(notificationsEnabled: v)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                OrnateButton(
                  label: 'Leaderboard',
                  fontSize: 22,
                  height: 54,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _LinkText('Terms of Use', AppConstants.termsOfUseUrl),
                    _LinkText('Privacy Policy', AppConstants.privacyPolicyUrl),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black45, width: 2),
        image: const DecorationImage(
          image: AssetImage('assets/images/panel_stone_dark.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({required this.label, required this.value, required this.onChanged});
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.display(size: 20, weight: FontWeight.w500)),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.cream,
            inactiveTrackColor: AppColors.cream.withValues(alpha: .35),
            thumbColor: const Color(0xFF2B2926),
            overlayColor: Colors.transparent,
            trackHeight: 6,
          ),
          child: Slider(value: value, onChanged: onChanged),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.display(size: 20, weight: FontWeight.w500))),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF703B1B),
          activeTrackColor: AppColors.cream,
          inactiveThumbColor: const Color(0xFF2B2926),
          inactiveTrackColor: AppColors.cream,
        ),
      ],
    );
  }
}

class _LinkText extends StatelessWidget {
  const _LinkText(this.label, this.url);
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Text(
        label,
        style: AppTextStyles.body(size: 16, color: Colors.black87).copyWith(decoration: TextDecoration.underline),
      ),
    );
  }
}
