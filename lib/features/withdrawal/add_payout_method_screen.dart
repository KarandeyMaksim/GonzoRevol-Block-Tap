import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_scale.dart';
import '../../app/theme.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';
import '../../widgets/ornate_button.dart';
import '../../widgets/pressable.dart';
import '../../widgets/screen_background.dart';
import '../../widgets/screen_header.dart';
import 'connect_method_dialog.dart';
import 'payment_icon.dart';

/// Node `0:126` — scrollable list of every payout method (26-method lookup
/// table from "Инструкция для разработчиков.md"), each row showing a
/// Connect / Connected pill exactly like the Figma reference
/// ("Add payout method.png"): brand badge + label on the left, action pill
/// on the right. Tapping "Connect" opens `ConnectMethodDialog` to capture
/// the account detail(s), stored locally only.
class AddPayoutMethodScreen extends ConsumerWidget {
  const AddPayoutMethodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);

    return DesignCanvas(
      child: ScreenBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              const ScreenHeader(title: 'Add payout method'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  itemCount: PayoutMethodDef.all.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final m = PayoutMethodDef.all[i];
                    final connected = game.connectedPayoutMethods.containsKey(m.id);
                    return _PayoutRow(method: m, connected: connected);
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayoutRow extends StatelessWidget {
  const _PayoutRow({required this.method, required this.connected});

  final PayoutMethodDef method;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black45, width: 1.5),
        image: const DecorationImage(
          image: AssetImage('assets/images/panel_row_stone.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          PaymentIcon(methodId: method.id, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              method.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(size: 15, color: AppColors.cream, weight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          connected
              ? OrnateButton(
                  label: 'Connected',
                  width: 118,
                  height: 38,
                  fontSize: 14,
                  onTap: () => ConnectMethodDialog.show(context, method),
                )
              : _ConnectPill(onTap: () => ConnectMethodDialog.show(context, method)),
        ],
      ),
    );
  }
}

/// Flat golden-brown "Connect" pill, matching the Figma reference exactly
/// (a plain carved button — visually distinct from the ornate "Connected"
/// state, which reuses the same texture as every other primary CTA).
class _ConnectPill extends StatelessWidget {
  const _ConnectPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF876A34), Color(0xFF5E4517)],
          ),
          border: Border.all(color: const Color(0xFF3B2A16), width: 1.5),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 2))],
        ),
        child: Text('Connect', style: AppTextStyles.body(size: 14, color: AppColors.cream, weight: FontWeight.w700)),
      ),
    );
  }
}
