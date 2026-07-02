import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';
import '../../widgets/ornate_button.dart';
import '../../widgets/pressable.dart';
import 'payment_icon.dart';

/// Small carved-stone popup asking for the account detail(s) of one payout
/// method — matches the Figma reference exactly ("Exchange, 1v.png" /
/// "2v.png"): the `board_plaque.png` tablet texture, a big circular brand
/// badge, an uppercase label, one or two input fields, a close "X", and a
/// separate ornate "Save" pill floating below the tablet. Shared by the
/// payout-method list and the Exchange screen's quick-connect flow.
class ConnectMethodDialog extends ConsumerStatefulWidget {
  const ConnectMethodDialog({super.key, required this.method});

  final PayoutMethodDef method;

  static Future<void> show(BuildContext context, PayoutMethodDef method) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => ConnectMethodDialog(method: method),
    );
  }

  @override
  ConsumerState<ConnectMethodDialog> createState() => _ConnectMethodDialogState();
}

class _ConnectMethodDialogState extends ConsumerState<ConnectMethodDialog> {
  final _nameCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final m = widget.method;
    if (_numberCtrl.text.trim().isEmpty || (!m.singleField && _nameCtrl.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields.')));
      return;
    }
    final detail = m.singleField ? _numberCtrl.text.trim() : '${_nameCtrl.text.trim()} · ${_numberCtrl.text.trim()}';
    ref.read(gameControllerProvider.notifier).connectPayoutMethod(m.id, detail);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${m.label} connected!')));
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.method;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 320,
            height: m.singleField ? 400 : 450,
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
                Positioned(
                  top: 30,
                  right: 34,
                  child: Pressable(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: AppColors.cream, size: 20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(44, 66, 44, 56),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PaymentIcon(methodId: m.id, size: 84),
                      const SizedBox(height: 14),
                      Text(m.label.toUpperCase(), style: AppTextStyles.displayShadowed(size: 20)),
                      const SizedBox(height: 18),
                      if (!m.singleField) ...[
                        _FormField(controller: _nameCtrl, hint: 'Name'),
                        const SizedBox(height: 10),
                      ],
                      _FormField(controller: _numberCtrl, hint: m.hint),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OrnateButton(label: 'Save', width: 220, height: 54, fontSize: 22, onTap: _save),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sliderTrack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.trayPanelBorder, width: 2),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        style: AppTextStyles.body(size: 15, color: Colors.black87, weight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body(size: 15, color: Colors.black45),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
