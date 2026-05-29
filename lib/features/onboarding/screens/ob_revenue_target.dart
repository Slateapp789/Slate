import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/onboarding_provider.dart';

class ObRevenueTarget extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const ObRevenueTarget({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<ObRevenueTarget> createState() => _ObRevenueTargetState();
}

class _ObRevenueTargetState extends ConsumerState<ObRevenueTarget> {
  final _controller = TextEditingController();
  double? _selected;

  final List<double> _presets = [1000, 2000, 3000, 5000, 7500, 10000];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasValue => _controller.text.trim().isNotEmpty || _selected != null;

  void _continue() {
    final target =
        double.tryParse(_controller.text.replaceAll(',', '')) ?? _selected ?? 0;
    ref.read(onboardingProvider.notifier).setRevenueTarget(target);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Set your\nrevenue target.',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.t1,
              letterSpacing: -1.0,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "How much do you want to earn per month? We'll track your progress on the dashboard.",
            style: TextStyle(fontSize: 15, color: AppColors.t3, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Custom input
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Text(
                    '£',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.t2,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.t1,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.t3,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (_) => setState(() => _selected = null),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _controller.clear();
                      setState(() {});
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.t3,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Preset chips
          const Text(
            'OR CHOOSE A TARGET',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.t3,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _presets.map((amount) {
              final active = _selected == amount && _controller.text.isEmpty;
              return GestureDetector(
                onTap: () => setState(() {
                  _selected = amount;
                  _controller.clear();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: active ? AppColors.greenDim : AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active ? AppColors.green : AppColors.border,
                    ),
                  ),
                  child: Text(
                    '£${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: active ? AppColors.green : AppColors.t2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _hasValue ? _continue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                disabledBackgroundColor: AppColors.bgInteract,
                foregroundColor: Colors.white,
                disabledForegroundColor: AppColors.t3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: widget.onNext,
              child: const Text(
                'Skip — set this later in settings',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.t3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
