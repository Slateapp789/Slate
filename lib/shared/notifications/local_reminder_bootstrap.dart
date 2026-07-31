import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/slate_models.dart';
import '../providers/appointments_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/tasks_provider.dart';
import 'local_reminder_plan.dart';
import 'local_reminder_service.dart';

class WorkloopLocalReminderBootstrap extends ConsumerStatefulWidget {
  final Widget child;

  const WorkloopLocalReminderBootstrap({super.key, required this.child});

  @override
  ConsumerState<WorkloopLocalReminderBootstrap> createState() =>
      _WorkloopLocalReminderBootstrapState();
}

class _WorkloopLocalReminderBootstrapState
    extends ConsumerState<WorkloopLocalReminderBootstrap>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _routeSubscription;
  StreamSubscription<void>? _permissionSubscription;
  String? _lastFingerprint;
  String? _queuedFingerprint;
  List<LocalReminderPlan>? _queuedPlans;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final service = ref.read(localReminderServiceProvider);
    _routeSubscription = service.selectedRoutes.listen(_openRoute);
    _permissionSubscription = service.permissionChanges.listen((_) {
      if (!mounted) return;
      setState(() => _lastFingerprint = null);
    });
    unawaited(_initializeReminderNavigation(service));
  }

  Future<void> _initializeReminderNavigation(
    LocalReminderService service,
  ) async {
    try {
      await service.initialize();
      final route = service.takePendingLaunchRoute();
      if (route != null) _openRoute(route);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Workloop local reminder setup failed: $error');
      }
    }
  }

  void _openRoute(String route) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Supabase.instance.client.auth.currentSession == null) {
        context.go('/');
        return;
      }
      if (GoRouterState.of(context).uri.path == route) return;
      // Preserve the screen the user was working on so the routed reminder
      // destination has a meaningful back button and iOS back-swipe target.
      context.push(route);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _lastFingerprint = null;
    ref.invalidate(allTasksProvider);
    ref.invalidate(appointmentsProvider);
    ref.invalidate(notificationPreferencesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(allTasksProvider);
    final appointmentState = ref.watch(appointmentsProvider);
    final preferenceState = ref.watch(notificationPreferencesProvider);

    if (taskState.hasValue &&
        appointmentState.hasValue &&
        preferenceState.hasValue) {
      final appointments = <Appointment>[];
      for (final row in appointmentState.value ?? const []) {
        try {
          appointments.add(Appointment.fromMap(row));
        } catch (_) {
          // A malformed legacy row should not block reminders for valid work.
        }
      }
      final plans = buildLocalReminderPlans(
        tasks: taskState.value ?? const [],
        appointments: appointments,
        bookingRemindersEnabled:
            preferenceState.value?['appointment_reminder_15'] == true,
        now: DateTime.now(),
      );
      final fingerprint = plans
          .map(
            (plan) =>
                '${plan.key}:${plan.scheduledAtUtc.microsecondsSinceEpoch}:'
                '${plan.title}:${plan.body}',
          )
          .join('|');
      if (_lastFingerprint != fingerprint) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _queueReconcile(fingerprint, plans);
        });
      }
    }

    return widget.child;
  }

  void _queueReconcile(String fingerprint, List<LocalReminderPlan> plans) {
    if (_lastFingerprint == fingerprint && !_syncing) return;
    _queuedFingerprint = fingerprint;
    _queuedPlans = plans;
    if (!_syncing) unawaited(_drainReconciliationQueue());
  }

  Future<void> _drainReconciliationQueue() async {
    _syncing = true;
    while (_queuedPlans != null) {
      final plans = _queuedPlans!;
      final fingerprint = _queuedFingerprint!;
      _queuedPlans = null;
      _queuedFingerprint = null;
      try {
        await ref.read(localReminderServiceProvider).reconcile(plans);
        _lastFingerprint = fingerprint;
      } catch (error) {
        if (kDebugMode) {
          debugPrint('Workloop reminder reconciliation failed: $error');
        }
      }
    }
    _syncing = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_routeSubscription?.cancel());
    unawaited(_permissionSubscription?.cancel());
    super.dispose();
  }
}
