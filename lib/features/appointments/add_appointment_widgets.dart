part of 'add_appointment_screen.dart';

class _PickedAppointmentTime {
  final int hour;
  final int minute;

  const _PickedAppointmentTime({required this.hour, required this.minute});
}

Future<_PickedAppointmentTime?> _showAppointmentTimePicker({
  required BuildContext context,
  required int initialHour,
  required int initialMinute,
}) {
  int tempHour = initialHour;
  int tempMinute = initialMinute;

  return showModalBottomSheet<_PickedAppointmentTime>(
    context: context,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setModal) => SizedBox(
        height: 280,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.t1,
                    ),
                  ),
                  WorkloopTextButton(
                    label: 'Done',
                    onPressed: () => Navigator.pop(
                      context,
                      _PickedAppointmentTime(
                        hour: tempHour,
                        minute: tempMinute,
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
                          setModal(() => tempHour = i),
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
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: selected ? AppColors.t1 : AppColors.t3,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const Text(
                    ':',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
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
                          setModal(() => tempMinute = i * 15),
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
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: selected ? AppColors.t1 : AppColors.t3,
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
      ),
    ),
  );
}

class _AppointmentSectionLabel extends StatelessWidget {
  final String text;
  final String? subtitle;

  const _AppointmentSectionLabel(this.text, {this.subtitle});

  @override
  Widget build(BuildContext context) {
    final label = text
        .toLowerCase()
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word.substring(0, 1).toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.12,
            color: AppColors.t1,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            style: const TextStyle(
              color: AppColors.t3,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _BookingSaveAction extends StatelessWidget {
  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  const _BookingSaveAction({
    required this.label,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? AppColors.modCalendar.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: enabled && !loading ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 58,
            minHeight: AppSpacing.minTouch,
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: AppColors.modCalendar,
                      strokeWidth: 2,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: enabled ? AppColors.modCalendar : AppColors.t4,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentSkeleton extends StatelessWidget {
  final double height;

  const _AppointmentSkeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class _AppointmentErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AppointmentErrorBox(this.message, {required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.circleAlert, color: AppColors.error, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _ResponsiveBookingPair extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _ResponsiveBookingPair({required this.first, required this.second});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledBody = MediaQuery.textScalerOf(context).scale(14);
        final stacked = constraints.maxWidth < 360 || scaledBody > 18;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 10), second],
          );
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 10),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _AppointmentTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? prefix;
  final String? suffix;
  final String? label;
  final IconData? icon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _AppointmentTextInput({
    required this.controller,
    required this.hint,
    this.prefix,
    this.suffix,
    this.label,
    this.icon,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              color: AppColors.t2,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(color: AppColors.t1, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            prefixIcon: icon == null
                ? null
                : Icon(icon, color: AppColors.t3, size: 18),
            suffixText: suffix,
            prefixStyle: const TextStyle(color: AppColors.t2),
            suffixStyle: const TextStyle(color: AppColors.t3),
            hintStyle: const TextStyle(
              color: AppColors.t3,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: AppColors.bgCard.withValues(alpha: 0.72),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(
                color: AppColors.accentPrimary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentDueToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PaymentDueToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.t1.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.t2,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create payment due',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.t1,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Adds an unpaid Money item linked to this booking.',
                  style: TextStyle(fontSize: 12, color: AppColors.t3),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
