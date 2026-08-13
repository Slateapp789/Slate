import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workloop/shared/repositories/appointments_repository.dart';
import 'package:workloop/shared/repositories/clients_repository.dart';
import 'package:workloop/shared/repositories/notes_repository.dart';
import 'package:workloop/shared/repositories/payments_repository.dart';
import 'package:workloop/shared/repositories/privacy_repository.dart';
import 'package:workloop/shared/repositories/tasks_repository.dart';

import 'staging_test_config.dart';

const _userEmail = String.fromEnvironment('E2E_USER_A_EMAIL');
const _userPassword = String.fromEnvironment('E2E_USER_A_PASSWORD');

final _configured =
    stagingWritesAllowed &&
    stagingUrl.isNotEmpty &&
    stagingAnonKey.isNotEmpty &&
    _userEmail.isNotEmpty &&
    _userPassword.isNotEmpty;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  requireSafeStagingWriteTarget();

  testWidgets(
    'staging core loop persists client, booking, task, note, and payment',
    (tester) async {
      final client = SupabaseClient(
        stagingUrl,
        stagingAnonKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      final runId = DateTime.now().toUtc().microsecondsSinceEpoch.toString();
      final clientName = 'E2E Client $runId';
      final bookingTitle = 'E2E Booking $runId';
      final taskTitle = 'E2E Follow-up $runId';
      final noteTitle = 'E2E Note $runId';
      final notificationBody = 'E2E booking created $runId';

      String? workspaceId;
      String? contactId;
      String? appointmentId;
      String? taskId;
      String? noteId;
      String? paymentId;

      try {
        final auth = await client.auth.signInWithPassword(
          email: _userEmail,
          password: _userPassword,
        );
        expect(auth.user, isNotNull);

        final membership = await client
            .from('workspace_members')
            .select('workspace_id')
            .eq('user_id', auth.user!.id)
            .limit(1)
            .maybeSingle();
        expect(
          membership,
          isNotNull,
          reason: 'The E2E user needs a workspace.',
        );
        workspaceId = membership!['workspace_id'] as String;

        final clients = ClientsRepository(client);
        final appointments = AppointmentsRepository(client);
        final tasks = TasksRepository(client);
        final notes = NotesRepository(client);
        final payments = PaymentsRepository(client);

        contactId = await clients.create(
          workspaceId: workspaceId,
          name: clientName,
          phone: '+44 7700 9${runId.substring(runId.length - 5)}',
          email: 'workloop-e2e-$runId@example.invalid',
          source: 'E2E staging',
          tags: const ['E2E'],
        );
        expect(
          (await clients.list(
            workspaceId,
          )).any((item) => item.id == contactId && item.name == clientName),
          isTrue,
        );

        final start = DateTime.now().toUtc().add(const Duration(days: 45));
        final appointmentIds = await appointments.createBookingWorkflow(
          workspaceId: workspaceId,
          idempotencyKey: 'e2e-create-booking-$runId',
          contactId: contactId,
          startTime: DateTime.utc(start.year, start.month, start.day, 10),
          endTime: DateTime.utc(start.year, start.month, start.day, 11),
          price: 85,
          title: bookingTitle,
          notes: 'Disposable staging workflow evidence.',
          taskTitles: [taskTitle],
          taskDueDate: start,
          createPaymentDue: true,
          paymentNote: 'E2E payment $runId',
          notificationTitle: 'E2E booking created',
          notificationBody: notificationBody,
        );
        expect(appointmentIds, hasLength(1));
        appointmentId = appointmentIds.single;

        final appointment = (await appointments.list(
          workspaceId,
        )).singleWhere((item) => item.id == appointmentId);
        expect(appointment.title, bookingTitle);
        expect(appointment.status, 'scheduled');

        final linkedTasks = (await tasks.list(
          workspaceId,
        )).where((item) => item.appointmentId == appointmentId).toList();
        expect(linkedTasks.any((item) => item.title == taskTitle), isTrue);
        taskId = linkedTasks.singleWhere((item) => item.title == taskTitle).id;

        final linkedPayments = await payments.forAppointment(appointmentId);
        expect(linkedPayments, hasLength(1));
        expect(linkedPayments.single.outstandingAmount, 85);
        paymentId = linkedPayments.single.id;

        noteId = await notes.create(
          workspaceId: workspaceId,
          title: noteTitle,
          body: 'Linked context created by the staging core-loop test.',
          contactId: contactId,
          appointmentId: appointmentId,
          pinned: true,
        );
        expect(
          (await notes.list(workspaceId)).any(
            (item) =>
                item.id == noteId &&
                item.contactId == contactId &&
                item.appointmentId == appointmentId,
          ),
          isTrue,
        );

        await clients.update(contactId, {'name': '$clientName updated'});
        expect((await clients.getById(contactId))?.name, '$clientName updated');

        await tasks.updateStatus(taskId, 'done');
        expect(
          (await tasks.list(
            workspaceId,
          )).singleWhere((item) => item.id == taskId).status,
          'done',
        );

        await appointments.completeBookingWorkflow(
          workspaceId: workspaceId,
          appointmentId: appointmentId,
          idempotencyKey: 'e2e-complete-booking-$runId',
          paymentMode: 'linked_paid',
          linkedPaymentId: paymentId,
          paymentDate: DateTime.now().toUtc(),
        );
        expect(
          (await appointments.list(
            workspaceId,
          )).singleWhere((item) => item.id == appointmentId).status,
          'completed',
        );
        final paid = (await payments.forAppointment(appointmentId)).single;
        expect(paid.status, 'paid');
        expect(paid.outstandingAmount, 0);

        final export =
            jsonDecode(
                  await PrivacyRepository(
                    client,
                  ).exportWorkspaceData(workspaceId),
                )
                as Map<String, dynamic>;
        expect(export['format'], 'workloop_workspace_export');
        expect(export['workspace_id'], workspaceId);
        expect(
          (export['contacts'] as List).any(
            (row) => (row as Map<String, dynamic>)['id'] == contactId,
          ),
          isTrue,
        );
        expect(
          (export['appointments'] as List).any(
            (row) => (row as Map<String, dynamic>)['id'] == appointmentId,
          ),
          isTrue,
        );
      } finally {
        if (noteId != null) {
          await _ignoreCleanup(() => NotesRepository(client).delete(noteId!));
        }
        if (taskId != null) {
          await _ignoreCleanup(() => TasksRepository(client).delete(taskId!));
        }
        if (paymentId != null) {
          await _ignoreCleanup(
            () => PaymentsRepository(client).delete(paymentId!),
          );
        }
        if (appointmentId != null) {
          await _ignoreCleanup(
            () => client.from('appointments').delete().eq('id', appointmentId!),
          );
        }
        if (contactId != null) {
          await _ignoreCleanup(
            () => ClientsRepository(client).delete(contactId!),
          );
        }
        if (workspaceId != null) {
          await _ignoreCleanup(
            () => client
                .from('notifications')
                .delete()
                .eq('workspace_id', workspaceId!)
                .eq('body', notificationBody),
          );
          await _ignoreCleanup(
            () => client
                .from('notifications')
                .delete()
                .eq('workspace_id', workspaceId!)
                .ilike('body', '%$clientName%'),
          );
        }
        await _ignoreCleanup(client.auth.signOut);
        client.dispose();
      }
    },
    skip: !_configured,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<void> _ignoreCleanup(Future<void> Function() action) async {
  try {
    await action();
  } catch (_) {
    // Cleanup is best effort so the original workflow failure remains visible.
  }
}
