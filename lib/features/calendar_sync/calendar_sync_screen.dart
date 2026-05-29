import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';

class CalendarSyncScreen extends StatelessWidget {
  const CalendarSyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      LucideIcons.chevronLeft,
                      color: AppColors.t2,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Calendar sync',
                  style: TextStyle(
                    color: AppColors.t1,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.calendarClock,
                    color: AppColors.green,
                    size: 28,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Connect your calendar',
                    style: TextStyle(
                      color: AppColors.t1,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Slate will keep calendar sync contained here: provider account, sync status, conflict checks and disconnect controls. Provider OAuth is the only missing external integration.',
                    style: TextStyle(
                      color: AppColors.t3,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SyncRow(label: 'Two-way sync', value: 'Planned'),
            _SyncRow(label: 'Conflict detection', value: 'Planned'),
            _SyncRow(label: 'Imported busy blocks', value: 'Planned'),
          ],
        ),
      ),
    );
  }
}

class _SyncRow extends StatelessWidget {
  final String label;
  final String value;
  const _SyncRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.t1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.t3,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
