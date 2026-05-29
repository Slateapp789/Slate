import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ObWelcome extends StatelessWidget {
  final VoidCallback onNext;
  const ObWelcome({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(
            'Slate',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: AppColors.green,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Run your business.\nNot your admin.',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppColors.t1,
              letterSpacing: -1.2,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your appointments, clients, and payments — one app built for people who work for themselves.',
            style: TextStyle(fontSize: 16, color: AppColors.t3, height: 1.5),
          ),
          const SizedBox(height: 40),
          // Value props
          _ValueProp(emoji: '📅', text: 'Know exactly what\'s on today'),
          const SizedBox(height: 16),
          _ValueProp(emoji: '💰', text: 'Get paid faster, with less chasing'),
          const SizedBox(height: 16),
          _ValueProp(
            emoji: '👥',
            text: 'Every client, every history, one place',
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Get started — it\'s free',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ValueProp extends StatelessWidget {
  final String emoji;
  final String text;
  const _ValueProp({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: AppColors.t2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
