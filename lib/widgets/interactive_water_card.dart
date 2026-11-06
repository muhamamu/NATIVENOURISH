import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';

class InteractiveWaterCard extends StatefulWidget {
  const InteractiveWaterCard({super.key});

  @override
  State<InteractiveWaterCard> createState() => _InteractiveWaterCardState();
}

class _InteractiveWaterCardState extends State<InteractiveWaterCard> {
  bool _saving = false;
  int _feedbackId = 0;
  String _feedback = '';

  Future<void> _update(Future<void> Function() action, {String? feedback}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
      if (mounted && feedback != null) {
        setState(() { _feedback = feedback; _feedbackId++; });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update water. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _chooseGoal() async {
    final user = context.read<UserProvider>();
    final goal = await showDialog<double>(context: context,
      builder: (_) => _WaterGoalDialog(initialGoal: user.profile.dailyWaterTargetMl));
    if (goal == null || !mounted) return;
    await _update(() => user.updateProfile(user.profile.copyWith(dailyWaterTargetMl: goal)));
  }

  @override
  Widget build(BuildContext context) {
    final food = context.watch<FoodProvider>();
    final target = context.watch<UserProvider>().profile.dailyWaterTargetMl;
    final current = food.todayWaterMl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = !_saving && !food.isLoading && food.loadError == null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : const Duration(milliseconds: 650);
    final blue = AppColors.accentBlue;
    return Container(
      key: const ValueKey('water-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: blue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.water_drop_rounded, color: blue, size: 20)),
            const Spacer(),
            Flexible(child: TextButton(
              onPressed: _saving ? null : _chooseGoal,
              style: TextButton.styleFrom(foregroundColor: blue, padding: const EdgeInsets.symmetric(horizontal: 8)),
              child: Text('Goal ${NumberFormat('0.##').format(target / 1000)}L', style: const TextStyle(fontSize: 11)),
            )),
            IconButton(tooltip: 'Reset Water',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              onPressed: enabled && current > 0 ? () => _update(food.clearWater) : null),
          ]),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: current), duration: duration, curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text('${NumberFormat.decimalPattern().format(value.round())} ml',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const Text('Hydration Level', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: target > 0 ? (current / target).clamp(0.0, 1.0) : 0),
            duration: duration, curve: Curves.easeOutCubic,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: value, color: blue,
                backgroundColor: isDark ? AppColors.darkCardHeader : AppColors.lightCardHeader, minHeight: 6)),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final amount in [-250, 250, 500])
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: blue,
                  minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 10),
                  side: BorderSide(color: blue.withValues(alpha: 0.3))),
                onPressed: enabled && (amount > 0 || current > 0)
                  ? () => _update(() => amount > 0 ? food.addWater(amount.toDouble()) : food.reduceWater(-amount.toDouble()),
                    feedback: amount > 0 ? '+$amount ml added' : 'Water reduced') : null,
                child: Text(amount > 0 ? '+$amount ml' : '−250 ml', style: const TextStyle(fontSize: 11)),
              ),
          ]),
          SizedBox(height: 22, child: ClipRect(child: AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation,
              child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(animation), child: child)),
            child: _feedback.isEmpty ? const SizedBox.shrink() : TweenAnimationBuilder<double>(
              key: ValueKey(_feedbackId), tween: Tween(begin: 1.0, end: 0.0),
              duration: reduceMotion ? Duration.zero : const Duration(seconds: 2),
              builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
              child: Text(_feedback, style: TextStyle(fontSize: 11, color: blue)),
            ),
          ))),
        ],
      ),
    );
  }
}

class _WaterGoalDialog extends StatefulWidget {
  final double initialGoal;
  const _WaterGoalDialog({required this.initialGoal});
  @override
  State<_WaterGoalDialog> createState() => _WaterGoalDialogState();
}

class _WaterGoalDialogState extends State<_WaterGoalDialog> {
  late final TextEditingController _controller;
  final _form = GlobalKey<FormState>();
  @override
  void initState() { super.initState(); _controller = TextEditingController(text: widget.initialGoal.round().toString()); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Daily Water Goal'),
    content: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Wrap(spacing: 8, children: [for (final ml in [1500, 2000, 2500, 3000])
        ActionChip(label: Text('${ml / 1000}L'), onPressed: () => _controller.text = ml.toString())]),
      const SizedBox(height: 16),
      TextFormField(controller: _controller, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Daily water goal (ml)'),
        validator: (text) { final value = double.tryParse(text ?? '');
          return value == null || !value.isFinite || value <= 0 ? 'Enter a positive amount in ml' : null; }),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: () { if (_form.currentState!.validate()) Navigator.pop(context, double.parse(_controller.text)); },
        child: const Text('Save Goal')),
    ],
  );
}
