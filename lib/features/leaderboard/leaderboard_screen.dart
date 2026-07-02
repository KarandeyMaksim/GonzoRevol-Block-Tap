import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_scale.dart';
import '../../app/theme.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';
import '../../widgets/screen_background.dart';
import '../../widgets/screen_header.dart';

/// Local, backend-free leaderboard screen. Not present in the Figma file for
/// this project, added per the studio's general "leaderboard everywhere"
/// instruction, styled to match the rest of the jungle/gold theme.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(leaderboardProvider);
    final game = ref.watch(gameControllerProvider);
    final playerScore = game.totalWinnings;

    final all = [...entries, LeaderboardEntry(entries.length + 1, 'You', playerScore, isPlayer: true)]
      ..sort((a, b) => b.score.compareTo(a.score));

    return DesignCanvas(
      child: ScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const ScreenHeader(title: 'Leaderboard'),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.separated(
                    itemCount: all.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final rank = i + 1;
                      final e = all[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: e.isPlayer ? AppColors.gold1.withValues(alpha: .35) : const Color(0xCC1F2E27),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: rank <= 3 ? AppColors.gold2 : Colors.black38, width: 2),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text('#$rank', style: AppTextStyles.display(size: 18)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e.name,
                                style: AppTextStyles.body(size: 16, color: AppColors.cream, weight: FontWeight.w600),
                              ),
                            ),
                            Text('${e.score}', style: AppTextStyles.display(size: 18, color: AppColors.gold2)),
                          ],
                        ),
                      );
                    },
                  ),
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
