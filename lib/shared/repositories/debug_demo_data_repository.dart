import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client_provider.dart';

final debugDemoDataRepositoryProvider = Provider<DebugDemoDataRepository>((
  ref,
) {
  return DebugDemoDataRepository(ref.watch(supabaseClientProvider));
});

class DebugDemoDataRepository {
  static const marker = '[Slate demo]';

  final SupabaseClient _client;
  const DebugDemoDataRepository(this._client);

  Future<void> seed(String workspaceId) async {
    await _clearExistingDemoData(workspaceId);

    final now = DateTime.now();
    final services = await _insertServices(workspaceId);
    final clients = await _insertClients(workspaceId);

    await Future.wait([
      _insertAppointments(workspaceId, clients, services, now),
      _insertPayments(workspaceId, clients, now),
      _insertTasks(workspaceId, clients, now),
      _insertBookingRequests(workspaceId, services, now),
      _insertNotifications(workspaceId, now),
    ]);
  }

  Future<void> _clearExistingDemoData(String workspaceId) async {
    final demoContacts = await _client
        .from('contacts')
        .select('id')
        .eq('workspace_id', workspaceId)
        .ilike('notes', '%$marker%');
    final contactIds = demoContacts
        .map<String>((row) => row['id'] as String)
        .toList();

    final demoServices = await _client
        .from('services')
        .select('id')
        .eq('workspace_id', workspaceId)
        .ilike('description', '%$marker%');
    final serviceIds = demoServices
        .map<String>((row) => row['id'] as String)
        .toList();

    await _tryDelete(
      () => _client
          .from('notifications')
          .delete()
          .eq('workspace_id', workspaceId)
          .ilike('title', 'Demo:%'),
    );
    await _tryDelete(
      () => _client
          .from('booking_requests')
          .delete()
          .eq('workspace_id', workspaceId)
          .ilike('message', '%$marker%'),
    );
    await _tryDelete(
      () => _client
          .from('invoices')
          .delete()
          .eq('workspace_id', workspaceId)
          .ilike('invoice_number', 'DEMO-PAY-%'),
    );
    await _tryDelete(
      () => _client
          .from('tasks')
          .delete()
          .eq('workspace_id', workspaceId)
          .ilike('title', 'Demo:%'),
    );

    if (contactIds.isNotEmpty) {
      await _tryDelete(
        () => _client
            .from('appointments')
            .delete()
            .eq('workspace_id', workspaceId)
            .inFilter('contact_id', contactIds),
      );
      await _tryDelete(
        () => _client
            .from('tasks')
            .delete()
            .eq('workspace_id', workspaceId)
            .inFilter('contact_id', contactIds),
      );
      await _tryDelete(
        () => _client
            .from('invoices')
            .delete()
            .eq('workspace_id', workspaceId)
            .inFilter('contact_id', contactIds),
      );
      await _tryDelete(
        () => _client
            .from('contacts')
            .delete()
            .eq('workspace_id', workspaceId)
            .inFilter('id', contactIds),
      );
    }

    if (serviceIds.isNotEmpty) {
      await _tryDelete(
        () => _client
            .from('services')
            .delete()
            .eq('workspace_id', workspaceId)
            .inFilter('id', serviceIds),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _insertServices(String workspaceId) async {
    final rows = [
      {
        'workspace_id': workspaceId,
        'name': 'Signature Cut',
        'duration_mins': 45,
        'price': 38,
        'description': '$marker Precision cut, finish, and style.',
        'show_on_profile': true,
      },
      {
        'workspace_id': workspaceId,
        'name': 'Colour Refresh',
        'duration_mins': 90,
        'price': 85,
        'description': '$marker Toner, colour refresh, and blow dry.',
        'show_on_profile': true,
      },
      {
        'workspace_id': workspaceId,
        'name': 'Mobile Grooming',
        'duration_mins': 60,
        'price': 55,
        'description': '$marker Mobile appointment at client location.',
        'show_on_profile': true,
      },
      {
        'workspace_id': workspaceId,
        'name': 'Consultation',
        'duration_mins': 30,
        'price': 25,
        'description': '$marker First visit, advice, and planning.',
        'show_on_profile': true,
      },
    ];

    final inserted = await _client.from('services').insert(rows).select();
    return List<Map<String, dynamic>>.from(inserted);
  }

  Future<List<Map<String, dynamic>>> _insertClients(String workspaceId) async {
    final rows = [
      _clientRow(
        workspaceId,
        'Maya Patel',
        '07123 456 101',
        'maya@example.com',
        'Prefers Friday mornings. Likes a quiet appointment.',
      ),
      _clientRow(
        workspaceId,
        'Daniel Brooks',
        '07123 456 102',
        'daniel@example.com',
        'Usually books every 2 weeks after work.',
      ),
      _clientRow(
        workspaceId,
        'Aisha Khan',
        '07123 456 103',
        'aisha@example.com',
        'Colour client. Patch test reminder needed.',
      ),
      _clientRow(
        workspaceId,
        'Tom Gallagher',
        '07123 456 104',
        'tom@example.com',
        'Mobile visit. Ring when outside.',
      ),
      _clientRow(
        workspaceId,
        'Priya Shah',
        '07123 456 105',
        'priya@example.com',
        'Lead from public profile.',
      ),
      _clientRow(
        workspaceId,
        'Elliot Morris',
        '07123 456 106',
        'elliot@example.com',
        'Pays same day by bank transfer.',
      ),
      _clientRow(
        workspaceId,
        'Nina Clarke',
        '07123 456 107',
        'nina@example.com',
        'Monthly colour refresh.',
      ),
      _clientRow(
        workspaceId,
        'Sam Williams',
        '07123 456 108',
        'sam@example.com',
        'Needs evening slots where possible.',
      ),
    ];

    final inserted = await _client.from('contacts').insert(rows).select();
    return List<Map<String, dynamic>>.from(inserted);
  }

  Map<String, dynamic> _clientRow(
    String workspaceId,
    String name,
    String phone,
    String email,
    String note,
  ) {
    final isLead = name == 'Priya Shah';
    return {
      'workspace_id': workspaceId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': name.hashCode.isEven
          ? '${name.length + 10} King Street'
          : null,
      'notes': '$marker $note',
      'important_notes': name == 'Aisha Khan'
          ? 'Prefers quiet morning appointments.'
          : null,
      'status': isLead ? 'lead' : 'active',
      'preferred_contact_method': isLead ? 'whatsapp' : 'sms',
      'source': isLead ? 'Public profile' : 'Referral',
      'birthday': DateTime(
        1990 + (name.length % 15),
        name.length % 12 + 1,
        12,
      ).toIso8601String().split('T').first,
      'tags': [
        if (isLead) 'lead',
        if (name.length.isEven) 'regular',
        if (note.toLowerCase().contains('evening')) 'evening',
        if (note.toLowerCase().contains('monthly')) 'monthly',
      ],
      'last_activity_at': DateTime.now()
          .subtract(Duration(days: name.length))
          .toUtc()
          .toIso8601String(),
    };
  }

  Future<void> _insertAppointments(
    String workspaceId,
    List<Map<String, dynamic>> clients,
    List<Map<String, dynamic>> services,
    DateTime now,
  ) async {
    final rows = <Map<String, dynamic>>[];
    final random = Random(11);
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 28));

    for (var week = 0; week < 17; week++) {
      final weekStart = start.add(Duration(days: week * 7));
      for (var slot = 0; slot < 4; slot++) {
        final client = clients[(week + slot) % clients.length];
        final service = services[(slot + week) % services.length];
        final dayOffset = [1, 2, 4, 5][slot];
        final hour = [9, 11, 14, 16][slot];
        final startTime = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + dayOffset,
          hour,
          slot.isEven ? 0 : 30,
        );
        final duration = (service['duration_mins'] as num).toInt();
        final isPast = startTime.isBefore(now);
        rows.add({
          'workspace_id': workspaceId,
          'contact_id': client['id'],
          'service_id': service['id'],
          'title': service['name'],
          'start_time': startTime.toUtc().toIso8601String(),
          'end_time': startTime
              .add(Duration(minutes: duration))
              .toUtc()
              .toIso8601String(),
          'price': service['price'],
          'status': isPast
              ? random.nextInt(8) == 0
                    ? 'cancelled'
                    : 'completed'
              : 'scheduled',
          'notes': '$marker ${slot == 2 ? 'Repeat client.' : 'Demo booking.'}',
          'location': service['name'] == 'Mobile Grooming'
              ? '${12 + slot} Market Street'
              : null,
          if (slot == 0) 'recurrence_rule': 'FREQ=WEEKLY;INTERVAL=2',
        });
      }
    }

    final today = DateTime(now.year, now.month, now.day);
    for (var i = 0; i < 3; i++) {
      final client = clients[(i + 2) % clients.length];
      final service = services[i % services.length];
      final startTime = today.add(Duration(hours: [9, 12, 15][i]));
      final duration = (service['duration_mins'] as num).toInt();
      rows.add({
        'workspace_id': workspaceId,
        'contact_id': client['id'],
        'service_id': service['id'],
        'title': service['name'],
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': startTime
            .add(Duration(minutes: duration))
            .toUtc()
            .toIso8601String(),
        'price': service['price'],
        'status': startTime.isBefore(now) ? 'completed' : 'scheduled',
        'notes': '$marker Today demo booking.',
        'location': service['name'] == 'Mobile Grooming'
            ? '${18 + i} King Street'
            : null,
      });
    }

    try {
      await _client.from('appointments').insert(rows);
    } catch (_) {
      final fallbackRows = rows
          .map(
            (row) => Map<String, dynamic>.from(row)
              ..remove('location')
              ..remove('recurrence_rule'),
          )
          .toList();
      await _client.from('appointments').insert(fallbackRows);
    }
  }

  Future<void> _insertPayments(
    String workspaceId,
    List<Map<String, dynamic>> clients,
    DateTime now,
  ) async {
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < 18; i++) {
      final client = clients[i % clients.length];
      final amount = [38, 55, 85, 25, 110][i % 5].toDouble();
      final issueDate = now.subtract(Duration(days: 42 - (i * 4)));
      final status = i % 7 == 0
          ? 'overdue'
          : i % 5 == 0
          ? 'sent'
          : 'paid';
      rows.add({
        'workspace_id': workspaceId,
        'contact_id': client['id'],
        'invoice_number': 'DEMO-PAY-${(i + 1).toString().padLeft(3, '0')}',
        'type': 'invoice',
        'status': status,
        'issue_date': issueDate.toIso8601String().split('T').first,
        'due_date': issueDate
            .add(const Duration(days: 7))
            .toIso8601String()
            .split('T')
            .first,
        'subtotal': amount,
        'tax_rate': 0,
        'tax_amount': 0,
        'discount_value': 0,
        'total': amount,
        'amount_paid': status == 'paid' ? amount : 0,
        'notes':
            '$marker ${status == 'paid' ? 'Paid after appointment.' : 'Awaiting payment.'}',
      });
    }

    await _client.from('invoices').insert(rows);
  }

  Future<void> _insertTasks(
    String workspaceId,
    List<Map<String, dynamic>> clients,
    DateTime now,
  ) async {
    final rows = [
      _task(
        workspaceId,
        clients[0],
        'Demo: Send aftercare message',
        'high',
        now.add(const Duration(days: 1)),
      ),
      _task(
        workspaceId,
        clients[2],
        'Demo: Patch test reminder',
        'high',
        now.add(const Duration(days: 2)),
      ),
      _task(
        workspaceId,
        clients[4],
        'Demo: Follow up new lead',
        'medium',
        now.add(const Duration(days: 3)),
      ),
      _task(
        workspaceId,
        clients[6],
        'Demo: Confirm next colour booking',
        'medium',
        now.add(const Duration(days: 6)),
      ),
      _task(
        workspaceId,
        clients[3],
        'Demo: Check mobile address',
        'low',
        now.add(const Duration(days: 8)),
      ),
      _task(
        workspaceId,
        clients[1],
        'Demo: Rebook fortnightly slot',
        'medium',
        now.subtract(const Duration(days: 1)),
      ),
    ];

    await _client.from('tasks').insert(rows);
  }

  Map<String, dynamic> _task(
    String workspaceId,
    Map<String, dynamic> client,
    String title,
    String priority,
    DateTime dueDate,
  ) {
    return {
      'workspace_id': workspaceId,
      'contact_id': client['id'],
      'title': title,
      'priority': priority,
      'due_date': dueDate.toIso8601String().split('T').first,
      'status': dueDate.isBefore(DateTime.now()) ? 'open' : 'open',
    };
  }

  Future<void> _insertBookingRequests(
    String workspaceId,
    List<Map<String, dynamic>> services,
    DateTime now,
  ) async {
    final rows = [
      {
        'workspace_id': workspaceId,
        'name': 'Hannah Reed',
        'phone': '07123 456 201',
        'service_id': services[1]['id'],
        'preferred_time_text': 'Next Thursday afternoon',
        'message': '$marker Saw your profile and would like a colour refresh.',
        'status': 'pending',
        'created_at': now
            .subtract(const Duration(hours: 3))
            .toUtc()
            .toIso8601String(),
      },
      {
        'workspace_id': workspaceId,
        'name': 'Marcus Lee',
        'phone': '07123 456 202',
        'service_id': services[0]['id'],
        'preferred_time_text': 'Any Saturday morning',
        'message': '$marker Needs a regular appointment every month.',
        'status': 'contacted',
        'created_at': now
            .subtract(const Duration(days: 1))
            .toUtc()
            .toIso8601String(),
      },
      {
        'workspace_id': workspaceId,
        'name': 'Sofia Martin',
        'phone': '07123 456 203',
        'service_id': services[3]['id'],
        'preferred_time_text': 'Early next week',
        'message': '$marker Wants a consultation before booking.',
        'status': 'pending',
        'created_at': now
            .subtract(const Duration(days: 2))
            .toUtc()
            .toIso8601String(),
      },
    ];

    try {
      await _client.from('booking_requests').insert(rows);
    } catch (_) {
      final fallbackRows = rows
          .map(
            (row) => Map<String, dynamic>.from(row)
              ..update(
                'message',
                (message) =>
                    '${row['preferred_time_text']}\n\n${message.toString()}',
              )
              ..remove('preferred_time_text'),
          )
          .toList();
      await _tryInsert(
        () => _client.from('booking_requests').insert(fallbackRows),
      );
    }
  }

  Future<void> _insertNotifications(String workspaceId, DateTime now) async {
    final rows = [
      _notification(
        workspaceId,
        'booking_request',
        'Demo: New booking request',
        'Hannah requested a colour refresh.',
        '/booking-requests',
        now,
      ),
      _notification(
        workspaceId,
        'invoice_overdue',
        'Demo: Payment overdue',
        'A demo payment needs attention.',
        '/payments',
        now.subtract(const Duration(hours: 5)),
      ),
      _notification(
        workspaceId,
        'lead_followup',
        'Demo: Lead follow-up',
        'Priya is waiting for a reply.',
        '/clients',
        now.subtract(const Duration(days: 1)),
      ),
    ];

    await _tryInsert(() => _client.from('notifications').insert(rows));
  }

  Map<String, dynamic> _notification(
    String workspaceId,
    String type,
    String title,
    String body,
    String deepLink,
    DateTime createdAt,
  ) {
    return {
      'workspace_id': workspaceId,
      'type': type,
      'title': title,
      'body': body,
      'deep_link': deepLink,
      'read': false,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  Future<void> _tryDelete(Future<dynamic> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Demo cleanup should not block seeding on older local schemas.
    }
  }

  Future<void> _tryInsert(Future<dynamic> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Optional V1 tables may not exist in every development database yet.
    }
  }
}
