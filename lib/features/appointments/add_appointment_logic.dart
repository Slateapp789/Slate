part of 'add_appointment_screen.dart';

class _LocationChoice {
  final String value;
  final String label;

  const _LocationChoice({required this.value, required this.label});
}

String _formatAppointmentDate(DateTime dt) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
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
  return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

String? _recurrenceRuleFor(String mode) {
  return switch (mode) {
    'weekly' => 'FREQ=WEEKLY;INTERVAL=1',
    'fortnightly' => 'FREQ=WEEKLY;INTERVAL=2',
    'monthly' => 'FREQ=MONTHLY;INTERVAL=1',
    _ => null,
  };
}

int _repeatOccurrencesFor(String mode) {
  return switch (mode) {
    'weekly' => 12,
    'fortnightly' => 6,
    'monthly' => 3,
    _ => 1,
  };
}
