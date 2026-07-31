import 'dart:convert';
import 'dart:io';
import 'dart:math';

const _profiles = <String, int>{
  'small': 8,
  'medium': 250,
  'large': 5000,
  'scale-50000': 50000,
};

void main(List<String> arguments) async {
  final options = _Options.parse(arguments);
  if (options.showHelp) {
    stdout.write(_usage);
    return;
  }

  final accountCount = _profiles[options.profile];
  if (accountCount == null) {
    stderr.writeln(
      'Unknown profile "${options.profile}". '
      'Choose ${_profiles.keys.join(', ')}.',
    );
    exitCode = 64;
    return;
  }

  final root = Directory('build/quality_data').absolute;
  final output = Directory(
    options.output ?? '${root.path}/${options.profile}',
  ).absolute;
  if (!_isWithin(output.path, root.path)) {
    stderr.writeln(
      'Refusing to write outside ${root.path}. '
      'Test data is intentionally restricted to the build directory.',
    );
    exitCode = 64;
    return;
  }
  if (options.profile == 'scale-50000' &&
      !options.dryRun &&
      Platform.environment['WORKLOOP_TEST_ENV'] != 'isolated') {
    stderr.writeln(
      'The 50,000-account profile requires '
      'WORKLOOP_TEST_ENV=isolated.',
    );
    exitCode = 78;
    return;
  }

  final batchCount = (accountCount / options.batchSize).ceil();
  final endBatch = min(
    batchCount,
    options.startBatch + (options.maxBatches ?? batchCount),
  );
  final plan = {
    'schema_version': 1,
    'profile': options.profile,
    'seed': options.seed,
    'account_count': accountCount,
    'batch_size': options.batchSize,
    'batch_count': batchCount,
    'selected_batches': [options.startBatch, endBatch],
    'output': output.path,
    'generated_at': 'deterministic',
    'contains_real_people': false,
    'writes_to_backend': false,
  };

  if (options.dryRun) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(plan));
    return;
  }

  output.createSync(recursive: true);
  var generatedAccounts = 0;
  var skippedBatches = 0;
  for (var batch = options.startBatch; batch < endBatch; batch++) {
    final file = File(
      '${output.path}/accounts-${batch.toString().padLeft(5, '0')}.jsonl',
    );
    if (file.existsSync() && !options.overwrite) {
      skippedBatches++;
      continue;
    }

    final first = batch * options.batchSize;
    final last = min(accountCount, first + options.batchSize);
    final sink = file.openWrite();
    try {
      for (var index = first; index < last; index++) {
        sink.writeln(jsonEncode(_account(index, options.seed)));
        generatedAccounts++;
      }
    } finally {
      await sink.close();
    }
  }

  File('${output.path}/manifest.json').writeAsStringSync(
    '${const JsonEncoder.withIndent(' ').convert({...plan, 'generated_accounts_this_run': generatedAccounts, 'skipped_existing_batches': skippedBatches})}\n',
  );
  stdout.writeln(
    'Generated $generatedAccounts deterministic accounts in ${output.path}; '
    'skipped $skippedBatches existing batches.',
  );
}

Map<String, Object?> _account(int index, int seed) {
  final random = Random(seed + (index * 7919));
  final workspaceId = _id('workspace', index);
  final userId = _id('user', index);
  final archetype = const [
    'new',
    'quiet-appointment',
    'busy-appointment',
    'mature-appointment',
    'project-based',
    'empty',
  ][index % 6];
  final baseDate = DateTime.utc(2026, 7, 26, 9);
  final mature = archetype.startsWith('mature');
  final empty = archetype == 'empty';
  final busy = archetype.startsWith('busy');
  final clientCount = empty
      ? 0
      : busy
      ? 24 + random.nextInt(24)
      : mature
      ? 12 + random.nextInt(18)
      : 1 + random.nextInt(8);
  final serviceCount = empty ? 0 : 1 + random.nextInt(4);
  final names = [
    'Alex Morgan',
    'Samira Khan',
    'José da Silva',
    'Zoë O’Connor',
    '李 明',
    'A very long customer name used to verify truncation and wrapping',
  ];

  final services = List.generate(serviceCount, (serviceIndex) {
    final id = _id('service', index * 100 + serviceIndex);
    return {
      'id': id,
      'workspace_id': workspaceId,
      'name': const [
        'Consultation',
        'Signature service',
        'Project session',
        'Follow-up',
      ][serviceIndex % 4],
      'duration_minutes': [30, 45, 60, 90][serviceIndex % 4],
      'price': [49.99, 75.0, 125.50, 2500.0][serviceIndex % 4],
      'active': true,
    };
  });
  final clients = List.generate(clientCount, (clientIndex) {
    final id = _id('contact', index * 1000 + clientIndex);
    return {
      'id': id,
      'workspace_id': workspaceId,
      'name': names[(index + clientIndex) % names.length],
      'email': 'quality+$index-$clientIndex@example.invalid',
      'phone': '+447700${(900000 + clientIndex).toString().padLeft(6, '0')}',
      'status': ['active', 'lead', 'inactive'][clientIndex % 3],
      'tags': clientIndex.isEven ? ['repeat', 'quality-fixture'] : <String>[],
      'notes': clientIndex % 5 == 0
          ? 'Long-form fixture notes: ${'detail ' * 30}'
          : null,
      'created_at': baseDate
          .subtract(Duration(days: mature ? 1095 - clientIndex : clientIndex))
          .toIso8601String(),
    };
  });

  final bookings = <Map<String, Object?>>[];
  final income = <Map<String, Object?>>[];
  final expenses = <Map<String, Object?>>[];
  final tasks = <Map<String, Object?>>[];
  final notes = <Map<String, Object?>>[];
  final notifications = <Map<String, Object?>>[];
  final feedItems = <Map<String, Object?>>[];
  final files = <Map<String, Object?>>[];
  for (var clientIndex = 0; clientIndex < clients.length; clientIndex++) {
    final clientId = clients[clientIndex]['id']! as String;
    final activityCount = busy
        ? 8
        : mature
        ? 5
        : 1 + random.nextInt(3);
    for (var activity = 0; activity < activityCount; activity++) {
      final ordinal = index * 100000 + clientIndex * 100 + activity;
      final dayOffset = mature
          ? -900 + ((clientIndex * 37 + activity * 71) % 1080)
          : -45 + ((clientIndex * 11 + activity * 17) % 120);
      final start = baseDate.add(
        Duration(days: dayOffset, hours: activity % 7),
      );
      final end = start.add(
        Duration(
          minutes: services.isEmpty
              ? 60
              : services[activity % services.length]['duration_minutes']!
                    as int,
        ),
      );
      final appointmentId = _id('appointment', ordinal);
      final price = services.isEmpty
          ? 0.0
          : services[activity % services.length]['price']! as double;
      bookings.add({
        'id': appointmentId,
        'workspace_id': workspaceId,
        'contact_id': clientId,
        'service_id': services.isEmpty
            ? null
            : services[activity % services.length]['id'],
        'title': 'Quality booking ${activity + 1}',
        'start_time': start.toIso8601String(),
        'end_time': end.toIso8601String(),
        'price': price,
        'status': dayOffset < 0 ? 'completed' : 'scheduled',
        'location': activity % 4 == 0 ? 'Europe/London DST boundary' : null,
      });
      income.add({
        'id': _id('payment', ordinal),
        'workspace_id': workspaceId,
        'contact_id': clientId,
        'appointment_id': appointmentId,
        'amount': price,
        'status': activity % 4 == 0 ? 'unpaid' : 'paid',
        'payment_date': start.toIso8601String().split('T').first,
      });
      if (activity % 3 == 0) {
        expenses.add({
          'id': _id('expense', ordinal),
          'workspace_id': workspaceId,
          'amount': 9.99 + (activity * 7.5),
          'category': ['supplies', 'travel', 'software'][activity % 3],
          'expense_date': start.toIso8601String().split('T').first,
        });
      }
    }
    tasks.add({
      'id': _id('task', index * 1000 + clientIndex),
      'workspace_id': workspaceId,
      'contact_id': clientId,
      'title': clientIndex % 4 == 0
          ? 'Follow up about a deliberately very long project requirement'
          : 'Follow up with ${clients[clientIndex]['name']}',
      'status': clientIndex % 3 == 0 ? 'done' : 'open',
      'due_date': baseDate
          .add(Duration(days: clientIndex - 5))
          .toIso8601String(),
    });
    notes.add({
      'id': _id('note', index * 1000 + clientIndex),
      'workspace_id': workspaceId,
      'contact_id': clientId,
      'title': 'Client context',
      'body': 'Deterministic fixture for ${clients[clientIndex]['name']}.',
    });
  }
  if (!empty) {
    notifications.add({
      'id': _id('notification', index),
      'workspace_id': workspaceId,
      'title': 'You have work that needs attention',
      'read_at': index.isEven ? baseDate.toIso8601String() : null,
    });
    feedItems.add({
      'id': _id('feed', index),
      'workspace_id': workspaceId,
      'event_type': 'fixture_created',
      'occurred_at': baseDate.toIso8601String(),
    });
    files.add({
      'id': _id('file', index),
      'workspace_id': workspaceId,
      'object_path': '$workspaceId/quality-fixture-$index.pdf',
      'content_type': 'application/pdf',
      'size_bytes': 1024 + index,
      'metadata_only': true,
    });
  }

  return {
    'fixture_version': 1,
    'archetype': archetype,
    'user': {
      'id': userId,
      'email': 'owner+$index@example.invalid',
      'synthetic': true,
    },
    'workspace': {
      'id': workspaceId,
      'owner_id': userId,
      'name': 'Quality Business ${index + 1}',
      'timezone': index % 5 == 0 ? 'Australia/Sydney' : 'Europe/London',
    },
    'business_profile': {
      'id': _id('profile', index),
      'workspace_id': workspaceId,
      'handle': 'quality-business-${index + 1}',
      'business_type': archetype.contains('project')
          ? 'project-based'
          : 'appointment-based',
    },
    'services': services,
    'clients': clients,
    'bookings': bookings,
    'income': income,
    'expenses': expenses,
    'tasks': tasks,
    'notes': notes,
    'notifications': notifications,
    'feed_items': feedItems,
    'files_metadata': files,
  };
}

String _id(String namespace, int value) {
  final prefix = namespace.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  final hex = ((prefix << 48) + value).toRadixString(16).padLeft(32, '0');
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20, 32)}';
}

bool _isWithin(String candidate, String root) =>
    candidate == root || candidate.startsWith('$root${Platform.pathSeparator}');

class _Options {
  final String profile;
  final String? output;
  final int seed;
  final int batchSize;
  final int startBatch;
  final int? maxBatches;
  final bool overwrite;
  final bool dryRun;
  final bool showHelp;

  const _Options({
    required this.profile,
    required this.output,
    required this.seed,
    required this.batchSize,
    required this.startBatch,
    required this.maxBatches,
    required this.overwrite,
    required this.dryRun,
    required this.showHelp,
  });

  factory _Options.parse(List<String> arguments) {
    String value(String name, String fallback) {
      final prefix = '--$name=';
      return arguments
          .firstWhere(
            (argument) => argument.startsWith(prefix),
            orElse: () => '$prefix$fallback',
          )
          .substring(prefix.length);
    }

    final outputValue = value('output', '');
    final maxBatchesValue = value('max-batches', '');
    final batchSize = int.tryParse(value('batch-size', '250')) ?? 0;
    final startBatch = int.tryParse(value('start-batch', '0')) ?? -1;
    final maxBatches = maxBatchesValue.isEmpty
        ? null
        : int.tryParse(maxBatchesValue);
    if (batchSize < 1 ||
        startBatch < 0 ||
        (maxBatchesValue.isNotEmpty &&
            (maxBatches == null || maxBatches < 1))) {
      throw const FormatException(
        'batch-size and max-batches must be positive; start-batch must be zero or greater.',
      );
    }
    return _Options(
      profile: value('profile', 'small'),
      output: outputValue.isEmpty ? null : outputValue,
      seed: int.tryParse(value('seed', '26072026')) ?? 26072026,
      batchSize: batchSize,
      startBatch: startBatch,
      maxBatches: maxBatches,
      overwrite: arguments.contains('--overwrite'),
      dryRun: arguments.contains('--dry-run'),
      showHelp: arguments.contains('--help') || arguments.contains('-h'),
    );
  }
}

const _usage = '''
Generate deterministic, synthetic Workloop QA data as resumable JSONL batches.

Usage:
  dart run tool/quality/generate_test_data.dart [options]

Options:
  --profile=small|medium|large|scale-50000
  --batch-size=250
  --start-batch=0
  --max-batches=1
  --seed=26072026
  --output=build/quality_data/custom
  --overwrite
  --dry-run

The generator only writes beneath build/quality_data and never connects to a
backend. Non-dry-run scale-50000 generation additionally requires
WORKLOOP_TEST_ENV=isolated.
''';
