import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/onboarding_provider.dart';

class ObFirstBooking extends ConsumerStatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  const ObFirstBooking({super.key, required this.onNext, required this.onBack});

  @override
  ConsumerState<ObFirstBooking> createState() => _ObFirstBookingState();
}

class _ObFirstBookingState extends ConsumerState<ObFirstBooking> {
  final _clientNameController = TextEditingController();
  String? _selectedService;
  DateTime _selectedDate = DateTime.now();
  int _selectedHour = 9;
  int _selectedMinute = 0;

  @override
  void dispose() {
    _clientNameController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _clientNameController.text.trim().isNotEmpty && _selectedService != null;

  void _saveAndContinue() {
    ref.read(onboardingProvider.notifier).setFirstBooking({
      'clientName': _clientNameController.text.trim(),
      'serviceName': _selectedService,
      'date': _selectedDate.toIso8601String().split('T')[0],
      'hour': _selectedHour,
      'minute': _selectedMinute,
    });
    widget.onNext();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.green,
              surface: AppColors.bgCard,
              onSurface: AppColors.t1,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        int tempHour = _selectedHour;
        int tempMinute = _selectedMinute;
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
                          'Select time',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.t1,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedHour = tempHour;
                              _selectedMinute = tempMinute;
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
                              initialItem: tempHour,
                            ),
                            onSelectedItemChanged: (i) =>
                                setModalState(() => tempHour = i),
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 24,
                              builder: (context, i) {
                                final selected = i == tempHour;
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
                              initialItem: tempMinute ~/ 15,
                            ),
                            onSelectedItemChanged: (i) =>
                                setModalState(() => tempMinute = i * 15),
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 4,
                              builder: (context, i) {
                                final min = i * 15;
                                final selected = min == tempMinute;
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

  String get _formattedDate {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final isToday =
        _selectedDate.day == DateTime.now().day &&
        _selectedDate.month == DateTime.now().month;
    if (isToday) return 'Today';
    return '${days[_selectedDate.weekday - 1]} ${_selectedDate.day} ${months[_selectedDate.month - 1]}';
  }

  String get _formattedTime =>
      '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(onboardingProvider).services;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Create your\nfirst booking.',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.t1,
              letterSpacing: -1.0,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a real appointment to get started.',
            style: TextStyle(fontSize: 15, color: AppColors.t3),
          ),
          const SizedBox(height: 32),

          // Client name
          _label('Client name'),
          const SizedBox(height: 8),
          TextField(
            controller: _clientNameController,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: AppColors.t1, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'e.g. Sarah Johnson',
              hintStyle: TextStyle(color: AppColors.t3),
              filled: true,
              fillColor: AppColors.bgCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.green, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Service
          _label('Service'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedService,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    'Select a service',
                    style: TextStyle(color: AppColors.t3, fontSize: 15),
                  ),
                ),
                isExpanded: true,
                dropdownColor: AppColors.bgRaised,
                icon: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.t3,
                  ),
                ),
                items: services.map((s) {
                  return DropdownMenuItem<String>(
                    value: s['name'] as String,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        s['name'] as String,
                        style: TextStyle(color: AppColors.t1, fontSize: 15),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedService = val),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Date and time row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Date'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          _formattedDate,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.t1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Time'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          _formattedTime,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.t1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _canContinue ? _saveAndContinue : null,
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
                'Create Booking',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: widget.onNext,
              child: Text(
                'Skip — I\'ll do this later',
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

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.t2,
        letterSpacing: 0.2,
      ),
    );
  }
}
