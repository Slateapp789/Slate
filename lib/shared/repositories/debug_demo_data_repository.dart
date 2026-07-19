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
    final windowStart = DateTime(now.year, now.month - 6, now.day);
    final windowEnd = DateTime(now.year, now.month + 6, now.day);

    await _updateBusinessContext(workspaceId);
    final services = await _insertServices(workspaceId);
    final clients = await _insertClients(workspaceId, now);
    final appointments = await _insertAppointments(
      workspaceId,
      clients,
      services,
      now,
      windowStart,
      windowEnd,
    );

    await Future.wait([
      _insertPayments(workspaceId, clients, appointments, now),
      _insertExpenses(workspaceId, now, windowStart, windowEnd),
      _insertTasks(workspaceId, clients, appointments, now),
      _insertNotes(workspaceId, clients, appointments, now),
      _insertBookingRequests(workspaceId, services, now),
      _insertNotifications(workspaceId, now),
    ]);
  }

  Future<void> _updateBusinessContext(String workspaceId) async {
    await _tryUpdate(
      () => _client
          .from('workspaces')
          .update({
            'name': 'Clearview Window Care',
            'industry': 'Window cleaning',
          })
          .eq('id', workspaceId),
    );

    await _tryUpdate(
      () => _client
          .from('workspace_settings')
          .update({
            'revenue_target': 6800,
            'min_booking_notice_hours': 4,
            'max_booking_window_weeks': 26,
          })
          .eq('workspace_id', workspaceId),
    );

    await _tryUpdate(
      () => _client
          .from('business_profiles')
          .update({
            'bio':
                'Reliable residential and commercial window cleaning across South London. Pure water pole system, frames and sills included, regular rounds available.',
            'gallery_enabled': true,
            'reviews_enabled': true,
            'booking_mode': 'manual',
            'notice_text':
                'Taking regular round bookings for late summer and autumn.',
            'notice_start': DateTime.now()
                .subtract(const Duration(days: 1))
                .toUtc()
                .toIso8601String(),
            'notice_end': DateTime.now()
                .add(const Duration(days: 45))
                .toUtc()
                .toIso8601String(),
          })
          .eq('workspace_id', workspaceId),
    );
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
          .ilike('body', '%$marker%'),
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
          .from('notes')
          .delete()
          .eq('workspace_id', workspaceId)
          .ilike('body', '%$marker%'),
    );
    await _tryDelete(
      () => _client
          .from('invoices')
          .delete()
          .eq('workspace_id', workspaceId)
          .ilike('invoice_number', 'WC-MOCK-%'),
    );
    await _tryDelete(
      () => _client
          .from('expenses')
          .delete()
          .eq('workspace_id', workspaceId)
          .ilike('notes', '%$marker%'),
    );
    await _tryDelete(
      () => _client
          .from('tasks')
          .delete()
          .eq('workspace_id', workspaceId)
          .ilike('title', '%$marker%'),
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
            .from('notes')
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
      _service(
        workspaceId,
        'Terraced House Clean',
        45,
        28,
        'Exterior windows, frames, sills, and doors for smaller homes.',
      ),
      _service(
        workspaceId,
        'Detached House Clean',
        75,
        52,
        'Full exterior clean for larger homes and conservatory access.',
      ),
      _service(
        workspaceId,
        'Shopfront Clean',
        35,
        35,
        'Street-level commercial glass, signage wipe-down, and entrance door.',
      ),
      _service(
        workspaceId,
        'Conservatory Roof Clean',
        120,
        120,
        'Deep clean for roof panels, gutters, frames, and finials.',
      ),
      _service(
        workspaceId,
        'Gutter Clear',
        90,
        95,
        'Gutter vacuum, downpipe check, and before/after photos.',
      ),
      _service(
        workspaceId,
        'Regular Round Visit',
        30,
        22,
        'Four-to-six-week maintenance clean for regular customers.',
      ),
    ];

    final inserted = await _client.from('services').insert(rows).select();
    return List<Map<String, dynamic>>.from(inserted);
  }

  Map<String, dynamic> _service(
    String workspaceId,
    String name,
    int duration,
    int price,
    String description,
  ) {
    return {
      'workspace_id': workspaceId,
      'name': name,
      'duration_mins': duration,
      'price': price,
      'description': '$marker $description',
      'show_on_profile': true,
      'active': true,
    };
  }

  Future<List<Map<String, dynamic>>> _insertClients(
    String workspaceId,
    DateTime now,
  ) async {
    final specs = [
      _ClientSpec(
        'Sarah Thompson',
        '07911 234 101',
        'sarah.thompson@example.com',
        '14 Maple Road, Clapham',
        'Regular six-week exterior clean. Side gate code 1942.',
        ['residential', 'regular', 'six-week round'],
      ),
      _ClientSpec(
        'Omar Rahman',
        '07911 234 102',
        'omar.rahman@example.com',
        '8 Station Parade, Tooting',
        'Shopfront before opening. Prefers invoices by email.',
        ['commercial', 'shopfront', 'early'],
      ),
      _ClientSpec(
        'Emily Carter',
        '07911 234 103',
        'emily.carter@example.com',
        '27 Ash Grove, Balham',
        'Detached house plus conservatory twice a year.',
        ['residential', 'conservatory', 'premium'],
      ),
      _ClientSpec(
        'Marcus Green',
        '07911 234 104',
        'marcus.green@example.com',
        '63 Elm Avenue, Streatham',
        'Pays same day by bank transfer.',
        ['residential', 'regular'],
      ),
      _ClientSpec(
        'Priya Desai',
        '07911 234 105',
        'priya.desai@example.com',
        'Flat 4, 19 Park Hill, Brixton',
        'Lead from public profile. Wants a first clean and regular quote.',
        ['lead', 'public-profile'],
        status: 'lead',
      ),
      _ClientSpec(
        'Ben Wallace',
        '07911 234 106',
        'ben.wallace@example.com',
        '41 Orchard Lane, Dulwich',
        'Needs text reminder the day before because of locked side access.',
        ['residential', 'access-note'],
      ),
      _ClientSpec(
        'Nina Hughes',
        '07911 234 107',
        'nina.hughes@example.com',
        '9 Victoria Mews, Wandsworth',
        'Monthly regular round, prefers Fridays.',
        ['residential', 'monthly', 'friday'],
      ),
      _ClientSpec(
        'The Daily Grind Cafe',
        '020 7946 0210',
        'manager@dailygrind.example.com',
        '112 High Street, Putney',
        'Weekly shopfront before 8am. Avoid delivery bay on Tuesdays.',
        ['commercial', 'weekly', 'shopfront'],
      ),
      _ClientSpec(
        'Luca Romano',
        '07911 234 108',
        'luca.romano@example.com',
        '5 Birch Close, Earlsfield',
        'Quarterly gutter clear plus windows after heavy rain.',
        ['residential', 'gutter', 'quarterly'],
      ),
      _ClientSpec(
        'Greenfield Dental',
        '020 7946 0211',
        'reception@greenfield.example.com',
        '22 Lavender Hill, Battersea',
        'Commercial clean every other Monday. Send invoice to reception.',
        ['commercial', 'fortnightly'],
      ),
      _ClientSpec(
        'Ava Mitchell',
        '07911 234 109',
        'ava.mitchell@example.com',
        '31 Rose Terrace, Wimbledon',
        'Prefers eco products and quiet morning appointments.',
        ['residential', 'morning'],
      ),
      _ClientSpec(
        'Harper & Co Studio',
        '020 7946 0212',
        'studio@harperco.example.com',
        '3 Market Yard, Peckham',
        'Large interior-facing panes, monthly after 5pm.',
        ['commercial', 'monthly', 'evening'],
      ),
      _ClientSpec(
        'James Porter',
        '07911 234 110',
        'james.porter@example.com',
        '76 Oakfield Road, Norwood',
        'Semi-detached regular. Dog in garden, call before arrival.',
        ['residential', 'pet-note'],
      ),
      _ClientSpec(
        'Maya Lewis',
        '07911 234 111',
        'maya.lewis@example.com',
        '18 Cedar Walk, Crystal Palace',
        'First clean completed in spring, likely to become regular.',
        ['residential', 'new-regular'],
      ),
      _ClientSpec(
        'Northside Nursery',
        '020 7946 0213',
        'office@northside.example.com',
        '88 Common Road, Wimbledon',
        'School holiday deep cleans only. Safeguarding sign-in required.',
        ['commercial', 'seasonal', 'school'],
      ),
      _ClientSpec(
        'Grace Wilson',
        '07911 234 112',
        'grace.wilson@example.com',
        '2 Willow Court, Clapham',
        'Top-floor flat, no rear access. Confirm parking first.',
        ['residential', 'access-note'],
      ),
      _ClientSpec(
        'Ethan Brooks',
        '07911 234 113',
        'ethan.brooks@example.com',
        '49 Kingston Road, Southfields',
        'Regular round and occasional conservatory roof clean.',
        ['residential', 'regular', 'conservatory'],
      ),
      _ClientSpec(
        'Bright Bean Roastery',
        '020 7946 0214',
        'ops@brightbean.example.com',
        '16 Railway Arches, Brixton',
        'Warehouse office windows every month. Invoice PO required.',
        ['commercial', 'monthly', 'po-required'],
      ),
    ];

    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < specs.length; i++) {
      final spec = specs[i];
      rows.add({
        'workspace_id': workspaceId,
        'name': spec.name,
        'phone': spec.phone,
        'email': spec.email,
        'address': spec.address,
        'notes': '$marker ${spec.note}',
        'important_notes': spec.tags.contains('access-note')
            ? 'Access note: check gate/parking before arrival.'
            : spec.tags.contains('po-required')
            ? 'Purchase order required before invoice is paid.'
            : null,
        'status': spec.status,
        'preferred_contact_method': spec.tags.contains('commercial')
            ? 'email'
            : 'sms',
        'source': spec.status == 'lead'
            ? 'Public profile'
            : spec.tags.contains('commercial')
            ? 'Local business referral'
            : 'Neighbour referral',
        'birthday': DateTime(
          1980 + (i % 22),
          (i % 12) + 1,
          8 + (i % 18),
        ).toIso8601String().split('T').first,
        'tags': spec.tags,
        'last_activity_at': now
            .subtract(Duration(days: i * 3 + 2))
            .toUtc()
            .toIso8601String(),
      });
    }

    final inserted = await _client.from('contacts').insert(rows).select();
    return List<Map<String, dynamic>>.from(inserted);
  }

  Future<List<Map<String, dynamic>>> _insertAppointments(
    String workspaceId,
    List<Map<String, dynamic>> clients,
    List<Map<String, dynamic>> services,
    DateTime now,
    DateTime windowStart,
    DateTime windowEnd,
  ) async {
    final rows = <Map<String, dynamic>>[];
    final random = Random(73);
    final daySlots = [
      (day: 1, hour: 8, minute: 30),
      (day: 1, hour: 11, minute: 0),
      (day: 2, hour: 9, minute: 15),
      (day: 3, hour: 13, minute: 0),
      (day: 4, hour: 10, minute: 30),
      (day: 5, hour: 14, minute: 0),
    ];

    var weekStart = _mondayOf(windowStart);
    var appointmentIndex = 0;
    while (weekStart.isBefore(windowEnd)) {
      for (final slot in daySlots) {
        final startTime = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + slot.day - 1,
          slot.hour,
          slot.minute,
        );
        if (startTime.isBefore(windowStart) || startTime.isAfter(windowEnd)) {
          continue;
        }

        final client =
            clients[(appointmentIndex * 3 + slot.day) % clients.length];
        final commercial = (client['tags'] as List<dynamic>? ?? const [])
            .contains('commercial');
        final service = commercial
            ? services[(slot.day == 5 ? 2 : 2 + appointmentIndex) %
                  services.length]
            : services[(appointmentIndex + slot.day) % services.length];
        final duration = (service['duration_mins'] as num).toInt();
        final basePrice = (service['price'] as num).toDouble();
        final price = basePrice + (commercial ? 8 : random.nextInt(9));
        final isPast = startTime.isBefore(now);
        final status = isPast
            ? appointmentIndex % 23 == 0
                  ? 'cancelled'
                  : appointmentIndex % 31 == 0
                  ? 'no_show'
                  : 'completed'
            : 'scheduled';

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
          'price': price,
          'status': status,
          'notes':
              '$marker ${commercial ? 'Commercial account.' : 'Residential round.'} ${appointmentIndex % 7 == 0 ? 'Send before/after photo.' : 'Frames and sills included.'}',
          'location': client['address'],
          if (appointmentIndex % 6 == 0) 'recurrence_rule': 'FREQ=MONTHLY',
        });
        appointmentIndex++;
      }
      weekStart = weekStart.add(const Duration(days: 7));
    }

    final today = DateTime(now.year, now.month, now.day);
    for (var i = 0; i < 4; i++) {
      final client = clients[(i * 4 + 2) % clients.length];
      final service = services[[5, 0, 2, 4][i]];
      final startTime = today.add(Duration(hours: [8, 10, 13, 15][i]));
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
        'notes': '$marker Today route: keep ladder and gutter vac in van.',
        'location': client['address'],
      });
    }

    try {
      final inserted = await _client.from('appointments').insert(rows).select();
      return List<Map<String, dynamic>>.from(inserted);
    } catch (_) {
      final fallbackRows = rows
          .map(
            (row) => Map<String, dynamic>.from(row)
              ..remove('location')
              ..remove('recurrence_rule'),
          )
          .toList();
      final inserted = await _client
          .from('appointments')
          .insert(fallbackRows)
          .select();
      return List<Map<String, dynamic>>.from(inserted);
    }
  }

  Future<void> _insertPayments(
    String workspaceId,
    List<Map<String, dynamic>> clients,
    List<Map<String, dynamic>> appointments,
    DateTime now,
  ) async {
    final completed =
        appointments.where((row) => row['status'] == 'completed').toList()
          ..sort(
            (a, b) => (a['start_time'] as String).compareTo(
              b['start_time'] as String,
            ),
          );
    final selected = completed.length > 110
        ? completed.sublist(completed.length - 110)
        : completed;
    final rows = <Map<String, dynamic>>[];

    for (var i = 0; i < selected.length; i++) {
      final appointment = selected[i];
      final issueDate = DateTime.parse(appointment['start_time'] as String);
      final total =
          ((appointment['price'] as num?)?.toDouble() ?? 35) +
          (i % 9 == 0 ? 12 : 0);
      final status = i % 17 == 0
          ? 'overdue'
          : i % 11 == 0
          ? 'sent'
          : 'paid';

      rows.add({
        'workspace_id': workspaceId,
        'contact_id': appointment['contact_id'],
        'appointment_id': appointment['id'],
        'invoice_number': 'WC-MOCK-${(i + 1).toString().padLeft(4, '0')}',
        'type': 'invoice',
        'status': status,
        'issue_date': _dateOnly(issueDate),
        'due_date': _dateOnly(issueDate.add(const Duration(days: 7))),
        'subtotal': total,
        'tax_rate': 0,
        'tax_amount': 0,
        'discount_value': 0,
        'total': total,
        'amount_paid': status == 'paid' ? total : 0,
        'notes':
            '$marker Window cleaning ${status == 'paid' ? 'paid' : 'due'} for ${_dateOnly(issueDate)}.',
      });
    }

    for (var i = 0; i < 10; i++) {
      final client = clients[(i * 2 + 1) % clients.length];
      final issueDate = now.add(Duration(days: 5 + i * 8));
      final total = [28, 35, 52, 95, 120][i % 5].toDouble();
      rows.add({
        'workspace_id': workspaceId,
        'contact_id': client['id'],
        'invoice_number': 'WC-MOCK-FUT-${(i + 1).toString().padLeft(3, '0')}',
        'type': 'invoice',
        'status': 'sent',
        'issue_date': _dateOnly(issueDate),
        'due_date': _dateOnly(issueDate.add(const Duration(days: 7))),
        'subtotal': total,
        'tax_rate': 0,
        'tax_amount': 0,
        'discount_value': 0,
        'total': total,
        'amount_paid': 0,
        'notes': '$marker Future scheduled window clean invoice.',
      });
    }

    await _client.from('invoices').insert(rows);
  }

  Future<void> _insertExpenses(
    String workspaceId,
    DateTime now,
    DateTime windowStart,
    DateTime windowEnd,
  ) async {
    final categories = ['Fuel', 'Materials', 'Insurance', 'Equipment', 'Other'];
    final amounts = [18, 22, 35, 48, 64, 11, 29, 95, 14, 42];
    final rows = <Map<String, dynamic>>[];

    var date = DateTime(windowStart.year, windowStart.month, 3);
    var index = 0;
    while (date.isBefore(windowEnd)) {
      for (var offset in [0, 9, 18]) {
        final expenseDate = date.add(Duration(days: offset));
        if (expenseDate.isAfter(windowEnd)) continue;
        rows.add({
          'workspace_id': workspaceId,
          'amount': amounts[(index + offset) % amounts.length],
          'category': categories[(index + offset) % categories.length],
          'expense_date': _dateOnly(expenseDate),
          'notes':
              '$marker Window cleaning ${categories[(index + offset) % categories.length].toLowerCase()} expense.',
        });
        index++;
      }
      date = DateTime(date.year, date.month + 1, date.day);
    }

    await _tryInsert(() => _client.from('expenses').insert(rows));
  }

  Future<void> _insertTasks(
    String workspaceId,
    List<Map<String, dynamic>> clients,
    List<Map<String, dynamic>> appointments,
    DateTime now,
  ) async {
    final upcoming = appointments
        .where(
          (row) => DateTime.parse(row['start_time'] as String).isAfter(now),
        )
        .take(8)
        .toList();

    final rows = [
      _task(
        workspaceId,
        clients[1],
        '$marker Confirm shopfront keyholder for Monday route',
        'high',
        now.add(const Duration(days: 1)),
        appointment: upcoming.isNotEmpty ? upcoming[0] : null,
      ),
      _task(
        workspaceId,
        clients[4],
        '$marker Quote Priya for first clean and regular round',
        'high',
        now.add(const Duration(days: 2)),
      ),
      _task(
        workspaceId,
        clients[8],
        '$marker Check gutter vacuum filter before quarterly job',
        'medium',
        now.add(const Duration(days: 4)),
        appointment: upcoming.length > 1 ? upcoming[1] : null,
      ),
      _task(
        workspaceId,
        clients[14],
        '$marker Send safeguarding paperwork before nursery clean',
        'medium',
        now.add(const Duration(days: 8)),
      ),
      _task(
        workspaceId,
        clients[10],
        '$marker Follow up eco product preference',
        'low',
        now.add(const Duration(days: 12)),
      ),
      _task(
        workspaceId,
        clients[17],
        '$marker Chase PO for Bright Bean invoice',
        'high',
        now.subtract(const Duration(days: 2)),
      ),
      _task(
        workspaceId,
        clients[6],
        '$marker Rebook Nina into September Friday slot',
        'medium',
        now.subtract(const Duration(days: 1)),
      ),
      _task(
        workspaceId,
        clients[0],
        '$marker Order more resin for pure water system',
        'low',
        now.add(const Duration(days: 18)),
      ),
    ];

    await _client.from('tasks').insert(rows);
  }

  Map<String, dynamic> _task(
    String workspaceId,
    Map<String, dynamic> client,
    String title,
    String priority,
    DateTime dueDate, {
    Map<String, dynamic>? appointment,
  }) {
    return {
      'workspace_id': workspaceId,
      'contact_id': client['id'],
      'appointment_id': appointment?['id'],
      'title': title,
      'priority': priority,
      'due_date': _dateOnly(dueDate),
      'status': 'open',
      'reminder_timing': priority == 'high' ? 'morning' : 'none',
    };
  }

  Future<void> _insertNotes(
    String workspaceId,
    List<Map<String, dynamic>> clients,
    List<Map<String, dynamic>> appointments,
    DateTime now,
  ) async {
    final rows = [
      _note(
        workspaceId,
        clients[0],
        '$marker Route planning',
        'Cluster Clapham and Balham residential jobs on Wednesdays to reduce fuel and parking time.',
        now.subtract(const Duration(days: 2)),
        pinned: true,
      ),
      _note(
        workspaceId,
        clients[7],
        '$marker Commercial account note',
        'Daily Grind wants windows spotless before morning rush. Arrive 7:15-7:30 and avoid Tuesday delivery bay.',
        now.subtract(const Duration(days: 5)),
        pinned: true,
      ),
      _note(
        workspaceId,
        clients[14],
        '$marker School holiday clean',
        'Northside Nursery prefers deep cleans during half term. Confirm DBS sign-in and reception contact.',
        now.subtract(const Duration(days: 8)),
      ),
      _note(
        workspaceId,
        clients[8],
        '$marker Gutter photos',
        'Take before and after photos for Luca after every gutter clear. He forwards them to landlord.',
        now.subtract(const Duration(days: 12)),
      ),
      _note(
        workspaceId,
        clients[17],
        '$marker Invoice process',
        'Bright Bean needs PO code on invoice notes or payment gets delayed.',
        now.subtract(const Duration(days: 17)),
      ),
      _note(
        workspaceId,
        clients[4],
        '$marker Lead context',
        'Priya has a first-floor maisonette and asked about six-week regular cleaning after a first clean.',
        now.subtract(const Duration(hours: 10)),
      ),
    ];

    await _tryInsert(() => _client.from('notes').insert(rows));
  }

  Map<String, dynamic> _note(
    String workspaceId,
    Map<String, dynamic> client,
    String title,
    String body,
    DateTime updatedAt, {
    bool pinned = false,
  }) {
    return {
      'workspace_id': workspaceId,
      'contact_id': client['id'],
      'title': title,
      'body': '$marker $body',
      'pinned': pinned,
      'created_at': updatedAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
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
        'phone': '07911 234 201',
        'service_id': services[0]['id'],
        'preferred_time_text': 'Next Friday morning',
        'message':
            '$marker Wants a one-off clean before house photos are taken.',
        'status': 'pending',
        'created_at': now
            .subtract(const Duration(hours: 3))
            .toUtc()
            .toIso8601String(),
      },
      {
        'workspace_id': workspaceId,
        'name': 'Oak & Stone Deli',
        'phone': '020 7946 0310',
        'service_id': services[2]['id'],
        'preferred_time_text': 'Every Monday before 8am',
        'message': '$marker New shopfront lead from public profile.',
        'status': 'pending',
        'created_at': now
            .subtract(const Duration(hours: 18))
            .toUtc()
            .toIso8601String(),
      },
      {
        'workspace_id': workspaceId,
        'name': 'Sofia Martin',
        'phone': '07911 234 202',
        'service_id': services[4]['id'],
        'preferred_time_text': 'Early next week',
        'message': '$marker Asking about gutter clear and upstairs windows.',
        'status': 'contacted',
        'created_at': now
            .subtract(const Duration(days: 2))
            .toUtc()
            .toIso8601String(),
      },
      {
        'workspace_id': workspaceId,
        'name': 'Riverside Offices',
        'phone': '020 7946 0311',
        'service_id': services[2]['id'],
        'preferred_time_text': 'Monthly, after office hours',
        'message':
            '$marker Commercial enquiry for recurring internal glass clean.',
        'status': 'pending',
        'created_at': now
            .subtract(const Duration(days: 4))
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
        'New booking request',
        '$marker Oak & Stone Deli asked for a weekly shopfront clean.',
        '/booking-requests',
        now.subtract(const Duration(hours: 2)),
      ),
      _notification(
        workspaceId,
        'invoice_overdue',
        'Payment overdue',
        '$marker Bright Bean has an overdue window cleaning invoice.',
        '/payments',
        now.subtract(const Duration(hours: 5)),
      ),
      _notification(
        workspaceId,
        'lead_followup',
        'Lead follow-up',
        '$marker Priya is waiting for a first-clean quote.',
        '/clients',
        now.subtract(const Duration(days: 1)),
      ),
      _notification(
        workspaceId,
        'new_booking',
        'Tomorrow route ready',
        '$marker Six jobs are scheduled across Clapham and Balham tomorrow.',
        '/work',
        now.subtract(const Duration(days: 2)),
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

  DateTime _mondayOf(DateTime date) {
    final midnight = DateTime(date.year, date.month, date.day);
    return midnight.subtract(Duration(days: midnight.weekday - 1));
  }

  String _dateOnly(DateTime value) => value.toIso8601String().split('T').first;

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

  Future<void> _tryUpdate(Future<dynamic> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Some development databases may have older profile/settings columns.
    }
  }
}

class _ClientSpec {
  final String name;
  final String phone;
  final String email;
  final String address;
  final String note;
  final List<String> tags;
  final String status;

  const _ClientSpec(
    this.name,
    this.phone,
    this.email,
    this.address,
    this.note,
    this.tags, {
    this.status = 'active',
  });
}
