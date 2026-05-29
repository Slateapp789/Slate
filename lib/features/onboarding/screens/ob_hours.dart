import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/onboarding_provider.dart';

const List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const Map<String, dynamic> _defaultHours = {
  'Mon': {'enabled': true, 'open': '09:00', 'close': '18:00'},
  'Tue': {'enabled': true, 'open': '09:00', 'close': '18:00'},
  'Wed': {'enabled': true, 'open': '09:00', 'close': '18:00'},
  'Thu': {'enabled': true, 'open': '09:00', 'close': '18:00'},
  'Fri': {'enabled': true, 'open': '09:00', 'close': '17:00'},
  'Sat': {'enabled': true, 'open': '09:00', 'close': '14:00'},
  'Sun': {'enabled': false, 'open': '09:00', 'close': '17:00'},
};

class ObHours extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const ObHours({super.key, required this.onNext, required this.onBack});

  @override
  ConsumerState<ObHours> createState() => _ObHoursState();
}

class _ObHoursState extends ConsumerState<ObHours> {
  late Map<String, Map<String, dynamic>> _hours;

  @override
  void initState() {
    super.initState();
    _hours = {
      for (var day in _days)
        day: Map<String, dynamic>.from(
          _defaultHours[day] as Map<String, dynamic>,
        ),
    };
  }

  Future<void> _pickTime(String day, String type) async {
    final current = _hours[day]![type] as String;
    final parts = current.split(':');
    int selectedHour = int.parse(parts[0]);
    int selectedMinute = int.parse(parts[1]);

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: 300,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          type == 'open' ? 'Opening time' : 'Closing time',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.t1,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _hours[day]![type] =
                                  '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';
                            });
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            itemExtent: 48,
                            perspective: 0.003,
                            diameterRatio: 1.8,
                            physics: const FixedExtentScrollPhysics(),
                            controller: FixedExtentScrollController(
                              initialItem: selectedHour,
                            ),
                            onSelectedItemChanged: (i) {
                              setModalState(() => selectedHour = i);
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 24,
                              builder: (context, i) {
                                final selected = i == selectedHour;
                                return Center(
                                  child: Text(
                                    i.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: selected ? 24 : 18,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w400,
                                      color: selected
                                          ? AppColors.t1
                                          : AppColors.t3,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Text(
                          ':',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.t1,
                          ),
                        ),
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            itemExtent: 48,
                            perspective: 0.003,
                            diameterRatio: 1.8,
                            physics: const FixedExtentScrollPhysics(),
                            controller: FixedExtentScrollController(
                              initialItem: selectedMinute ~/ 15,
                            ),
                            onSelectedItemChanged: (i) {
                              setModalState(() => selectedMinute = i * 15);
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 4,
                              builder: (context, i) {
                                final min = i * 15;
                                final selected = min == selectedMinute;
                                return Center(
                                  child: Text(
                                    min.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: selected ? 24 : 18,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w400,
                                      color: selected
                                          ? AppColors.t1
                                          : AppColors.t3,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _continue() {
    ref.read(onboardingProvider.notifier).setWorkingHours(_hours);
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
          Text(
            'When do you work?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.t1,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set your working hours. You can change these anytime in settings.',
            style: TextStyle(fontSize: 15, color: AppColors.t3, height: 1.5),
          ),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: _days.asMap().entries.map((entry) {
                final i = entry.key;
                final day = entry.value;
                final data = _hours[day]!;
                final enabled = data['enabled'] as bool;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 36,
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: enabled ? AppColors.t1 : AppColors.t3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (enabled) ...[
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _pickTime(day, 'open'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgInteract,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    data['open'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.t1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                '—',
                                style: TextStyle(color: AppColors.t3),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _pickTime(day, 'close'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgInteract,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    data['close'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.t1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            Expanded(
                              child: Text(
                                'Closed',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.t3,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 12),
                          Switch(
                            value: enabled,
                            onChanged: (val) {
                              setState(() => _hours[day]!['enabled'] = val);
                            },
                            activeThumbColor: AppColors.green,
                            inactiveTrackColor: AppColors.bgInteract,
                          ),
                        ],
                      ),
                    ),
                    if (i < _days.length - 1)
                      Divider(height: 1, color: AppColors.border),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _continue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
