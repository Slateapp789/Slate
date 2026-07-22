import 'package:device_calendar/device_calendar.dart' as device;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/providers/appointments_provider.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/repositories/appointments_repository.dart';
import '../../shared/widgets/slate_ui.dart';

class CalendarImportScreen extends ConsumerStatefulWidget {
  const CalendarImportScreen({super.key});

  @override
  ConsumerState<CalendarImportScreen> createState() =>
      _CalendarImportScreenState();
}

class _CalendarImportScreenState extends ConsumerState<CalendarImportScreen> {
  final device.DeviceCalendarPlugin _calendar = device.DeviceCalendarPlugin();
  List<device.Calendar> _calendars = const [];
  List<device.Event> _events = const [];
  final Set<String> _selected = {};
  String? _calendarId;
  String? _clientId;
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now().add(const Duration(days: 90));
  bool _loading = false;
  bool _importing = false;
  String? _message;

  Future<void> _loadCalendars() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      var permission = await _calendar.hasPermissions();
      if (permission.data != true) {
        permission = await _calendar.requestPermissions();
      }
      if (permission.data != true) {
        if (mounted) {
          setState(
            () => _message =
                'Calendar access is off. Enable it in system settings to choose events.',
          );
        }
        return;
      }
      final result = await _calendar.retrieveCalendars();
      final calendars = result.data?.toList() ?? const <device.Calendar>[];
      if (!mounted) return;
      setState(() {
        _calendars = calendars;
        _calendarId =
            calendars
                .where((calendar) => calendar.isDefault == true)
                .map((calendar) => calendar.id)
                .firstOrNull ??
            calendars.map((calendar) => calendar.id).firstOrNull;
        _message = calendars.isEmpty
            ? 'No readable calendars were found.'
            : null;
      });
      if (_calendarId != null) await _loadEvents();
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Calendars could not be loaded. Check permission and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadEvents() async {
    if (_calendarId == null) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final result = await _calendar.retrieveEvents(
        _calendarId,
        device.RetrieveEventsParams(startDate: _from, endDate: _to),
      );
      final events =
          (result.data?.toList() ?? const <device.Event>[])
              .where((event) => event.start != null)
              .where((event) => event.status != device.EventStatus.Canceled)
              .toList()
            ..sort((a, b) => a.start!.compareTo(b.start!));
      if (!mounted) return;
      setState(() {
        _events = events;
        _selected.clear();
        _message = events.isEmpty
            ? 'No events were found in this calendar and date range.'
            : null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Events could not be read. Try another calendar or date range.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickRange() async {
    final from = await showWorkloopDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime.now().subtract(const Duration(days: 730)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      title: 'Import from',
    );
    if (from == null || !mounted) return;
    final to = await showWorkloopDatePicker(
      context: context,
      initialDate: _to.isBefore(from)
          ? from.add(const Duration(days: 30))
          : _to,
      firstDate: from,
      lastDate: from.add(const Duration(days: 730)),
      title: 'Import until',
    );
    if (to == null || !mounted) return;
    setState(() {
      _from = from;
      _to = to.add(const Duration(hours: 23, minutes: 59));
    });
    await _loadEvents();
  }

  Future<void> _import() async {
    if (_selected.isEmpty || _clientId == null) return;
    setState(() => _importing = true);
    var imported = 0;
    final failures = <String>[];
    try {
      final workspaceId = await ref.read(workspaceIdProvider.future);
      if (workspaceId == null) throw StateError('Workspace unavailable');
      final repository = ref.read(appointmentsRepositoryProvider);
      final chosen = _events.where((event) => _selected.contains(_id(event)));
      for (final event in chosen) {
        final start = event.start!.toLocal();
        final end = event.end?.toLocal() ?? start.add(const Duration(hours: 1));
        try {
          await repository.create(
            workspaceId: workspaceId,
            contactId: _clientId!,
            startTime: start,
            endTime: end.isAfter(start)
                ? end
                : start.add(const Duration(hours: 1)),
            price: 0,
            title: event.title?.trim().isNotEmpty == true
                ? event.title!.trim()
                : 'Imported booking',
            notes:
                [
                      event.description?.trim(),
                      'Imported once from device calendar.',
                      if (event.allDay == true) 'Originally an all-day event.',
                    ]
                    .whereType<String>()
                    .where((value) => value.isNotEmpty)
                    .join('\n\n'),
            location: event.location,
          );
          imported++;
        } catch (_) {
          failures.add(event.title ?? 'Untitled event');
        }
      }
      ref.invalidate(appointmentsProvider);
      if (!mounted) return;
      SlateHaptics.success();
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Calendar import complete'),
          content: Text(
            failures.isEmpty
                ? '$imported ${imported == 1 ? 'booking was' : 'bookings were'} created.'
                : '$imported created. ${failures.length} could not be imported: ${failures.take(3).join(', ')}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted && failures.isEmpty) Navigator.pop(context, imported);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'The selected events could not be imported. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  String _id(device.Event event) {
    return event.eventId ??
        '${event.calendarId}-${event.title}-${event.start?.millisecondsSinceEpoch}';
  }

  String _date(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _time(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider).value ?? const <Client>[];
    return WorkloopPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              WorkloopIconButton(
                icon: LucideIcons.chevronLeft,
                semanticLabel: 'Back',
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Import calendar',
                  style: TextStyle(
                    color: AppColors.t1,
                    fontSize: 26,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'Review events before creating bookings',
            style: TextStyle(
              color: AppColors.t1,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'This is a one-time import, not calendar sync. Your source calendar is never changed.',
            style: TextStyle(color: AppColors.t3, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_calendars.isEmpty) ...[
            WorkloopPrimaryButton(
              label: _loading ? 'Loading calendars…' : 'Choose a calendar',
              icon: LucideIcons.calendarDays,
              onPressed: _loading ? null : _loadCalendars,
            ),
          ] else ...[
            const Text(
              'Calendar',
              style: TextStyle(
                color: AppColors.t2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            WorkloopPickerField<String>(
              value: _calendarId,
              title: 'Choose calendar',
              hint: 'Choose calendar',
              leadingIcon: LucideIcons.calendarDays,
              options: _calendars
                  .where((calendar) => calendar.id != null)
                  .map(
                    (calendar) => WorkloopPickerOption(
                      value: calendar.id!,
                      label: calendar.name ?? 'Calendar',
                      subtitle: calendar.accountName,
                    ),
                  )
                  .toList(),
              onChanged: (value) async {
                setState(() => _calendarId = value);
                await _loadEvents();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Date range',
              style: TextStyle(
                color: AppColors.t2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            WorkloopSurface(
              onTap: _pickRange,
              child: Row(
                children: [
                  const Icon(LucideIcons.calendarRange, color: AppColors.t3),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${_date(_from)} — ${_date(_to)}',
                      style: const TextStyle(
                        color: AppColors.t1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, color: AppColors.t3),
                ],
              ),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _message!,
              style: const TextStyle(color: AppColors.t3, height: 1.4),
            ),
          ],
          if (_loading) ...[
            const SizedBox(height: AppSpacing.lg),
            const Center(child: CircularProgressIndicator()),
          ] else if (_events.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                const Expanded(child: WorkloopSectionHeader(label: 'Events')),
                WorkloopTextButton(
                  label: _selected.length == _events.length
                      ? 'Clear'
                      : 'Select all',
                  onPressed: () => setState(() {
                    if (_selected.length == _events.length) {
                      _selected.clear();
                    } else {
                      _selected.addAll(_events.map(_id));
                    }
                  }),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            WorkloopSurface(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 520),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    final id = _id(event);
                    final start = event.start!.toLocal();
                    return WorkloopListRow(
                      onTap: () => setState(() {
                        if (!_selected.add(id)) _selected.remove(id);
                      }),
                      showDivider: index != _events.length - 1,
                      leading: Checkbox.adaptive(
                        value: _selected.contains(id),
                        onChanged: (value) => setState(() {
                          if (value == true) {
                            _selected.add(id);
                          } else {
                            _selected.remove(id);
                          }
                        }),
                      ),
                      title: Text(
                        event.title?.trim().isNotEmpty == true
                            ? event.title!.trim()
                            : 'Untitled event',
                        style: const TextStyle(
                          color: AppColors.t1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        event.allDay == true
                            ? '${_date(start)} · All day'
                            : '${_date(start)} · ${_time(start)}${event.end == null ? '' : '–${_time(event.end!.toLocal())}'}',
                        style: const TextStyle(color: AppColors.t3),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Client for selected events',
              style: TextStyle(
                color: AppColors.t2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            WorkloopPickerField<String>(
              value: _clientId,
              title: 'Choose client',
              hint: 'Choose a client',
              searchHint: 'Search clients',
              searchable: true,
              leadingIcon: LucideIcons.user,
              options: clients
                  .map(
                    (client) => WorkloopPickerOption(
                      value: client.id,
                      label: client.name,
                      subtitle: client.address,
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _clientId = value),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Imported bookings start at £0 so you can confirm the service and price safely afterward.',
              style: TextStyle(color: AppColors.t3, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            WorkloopPrimaryButton(
              label: _importing ? 'Importing…' : 'Import selected events',
              icon: LucideIcons.download,
              onPressed: _importing || _selected.isEmpty || _clientId == null
                  ? null
                  : _import,
            ),
          ],
        ],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
