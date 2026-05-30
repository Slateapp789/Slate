import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/slate_ui.dart';

class ObWelcome extends StatelessWidget {
  final VoidCallback onNext;
  const ObWelcome({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pageX),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.t1.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.t1.withValues(alpha: 0.09)),
            ),
            child: const Icon(
              LucideIcons.layers,
              color: AppColors.slateLight,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Run your business.\nNot your admin.',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppColors.t1,
              letterSpacing: 0,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your bookings, clients, and payments — one app built for people who work for themselves.',
            style: TextStyle(fontSize: 16, color: AppColors.t3, height: 1.5),
          ),
          const SizedBox(height: 40),
          const _ValueProp(
            icon: LucideIcons.calendarDays,
            text: 'Know exactly what is on today',
          ),
          const SizedBox(height: 16),
          const _ValueProp(
            icon: LucideIcons.banknote,
            text: 'Get paid faster, with less chasing',
          ),
          const SizedBox(height: 16),
          const _ValueProp(
            icon: LucideIcons.users,
            text: 'Every client, every history, one place',
          ),
          const Spacer(),
          SlateButton(
            label: 'Get started',
            icon: LucideIcons.arrowRight,
            onPressed: onNext,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ValueProp extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ValueProp({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.t1.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: AppColors.t3, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.t2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
