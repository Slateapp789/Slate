import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/repositories/clients_repository.dart';
import '../../shared/widgets/slate_ui.dart';
import 'import_models.dart';

enum _ClientField { ignore, name, phone, email, address, notes, tags }

class CsvImportScreen extends ConsumerStatefulWidget {
  const CsvImportScreen({super.key});

  @override
  ConsumerState<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends ConsumerState<CsvImportScreen> {
  CsvTable? _table;
  String? _fileName;
  final Map<int, _ClientField> _mapping = {};
  final Set<int> _completedRows = {};
  bool _loading = false;
  bool _importing = false;
  bool _reviewing = false;
  bool _skipDuplicates = true;
  String? _error;

  Future<void> _chooseFile() async {
    if (_loading || _importing || _reviewing) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'txt'],
        withData: true,
      );
      if (result == null) return;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) throw const FormatException('File could not be read');
      String source;
      try {
        source = utf8.decode(bytes);
      } on FormatException {
        source = latin1.decode(bytes);
      }
      final table = parseCsv(source);
      if (table.headers.isEmpty || table.rows.isEmpty) {
        throw const FormatException('No data rows were found');
      }
      final mapping = <int, _ClientField>{};
      for (var index = 0; index < table.headers.length; index++) {
        mapping[index] = _guessField(table.headers[index]);
      }
      if (!mounted) return;
      setState(() {
        _table = table;
        _fileName = file.name;
        _mapping
          ..clear()
          ..addAll(mapping);
        _completedRows.clear();
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'This file could not be prepared. Check that it is a valid CSV and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  _ClientField _guessField(String header) {
    final value = normaliseImportValue(header).replaceAll('_', ' ');
    if (value.contains('name') || value == 'client') return _ClientField.name;
    if (value.contains('phone') || value.contains('mobile')) {
      return _ClientField.phone;
    }
    if (value.contains('email')) return _ClientField.email;
    if (value.contains('address') || value.contains('location')) {
      return _ClientField.address;
    }
    if (value.contains('note')) return _ClientField.notes;
    if (value.contains('tag') || value.contains('category')) {
      return _ClientField.tags;
    }
    return _ClientField.ignore;
  }

  List<ImportCandidate> _candidates() {
    final table = _table;
    if (table == null) return const [];
    final nameIndex = _mapping.entries
        .where((entry) => entry.value == _ClientField.name)
        .map((entry) => entry.key)
        .firstOrNull;
    if (nameIndex == null) return const [];
    String? field(List<String> row, _ClientField field) {
      final index = _mapping.entries
          .where((entry) => entry.value == field)
          .map((entry) => entry.key)
          .firstOrNull;
      if (index == null || index >= row.length) return null;
      return row[index].trim().isEmpty ? null : row[index].trim();
    }

    return [
      for (var index = 0; index < table.rows.length; index++)
        if (!_completedRows.contains(index) &&
            table.rows[index][nameIndex].trim().isNotEmpty)
          ImportCandidate(
            sourceId: 'csv-$index',
            name: table.rows[index][nameIndex].trim(),
            phone: field(table.rows[index], _ClientField.phone),
            email: field(table.rows[index], _ClientField.email),
            address: field(table.rows[index], _ClientField.address),
          ),
    ];
  }

  String? _field(List<String> row, _ClientField field) {
    final index = _mapping.entries
        .where((entry) => entry.value == field)
        .map((entry) => entry.key)
        .firstOrNull;
    if (index == null || index >= row.length) return null;
    return row[index].trim().isEmpty ? null : row[index].trim();
  }

  Future<void> _import() async {
    if (_importing || _reviewing) return;
    final table = _table;
    if (table == null) return;
    final candidates = _candidates();
    if (!_mapping.containsValue(_ClientField.name)) {
      setState(() => _error = 'Choose which column contains the client name.');
      return;
    }
    if (candidates.isEmpty) {
      setState(() => _error = 'No rows contain a client name.');
      return;
    }
    setState(() => _reviewing = true);
    bool? confirmed;
    try {
      confirmed = await showWorkloopBottomSheet<bool>(
        context: context,
        builder: (context) => SlateSheetFrame(
          scrollable: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Review CSV import',
                style: TextStyle(
                  color: AppColors.t1,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${candidates.length} valid rows are ready. Invalid rows will be reported, never silently ignored.',
                style: const TextStyle(color: AppColors.t3, height: 1.45),
              ),
              const SizedBox(height: AppSpacing.lg),
              WorkloopPrimaryButton(
                label: 'Import clients',
                icon: LucideIcons.download,
                onPressed: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: AppSpacing.xs),
              WorkloopPrimaryButton(
                label: 'Keep reviewing',
                secondary: true,
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
    if (confirmed != true) return;
    setState(() {
      _importing = true;
      _error = null;
    });
    var imported = 0;
    var skipped = 0;
    final completedThisAttempt = <int>{};
    final failures = <String>[];
    try {
      final workspaceId = await ref.read(workspaceIdProvider.future);
      if (workspaceId == null) throw StateError('Workspace unavailable');
      final existingClients = await ref.read(clientsProvider.future);
      final existing = existingClients
          .map(
            (client) =>
                (name: client.name, phone: client.phone, email: client.email),
          )
          .toList();
      final repository = ref.read(clientsRepositoryProvider);
      for (var index = 0; index < table.rows.length; index++) {
        if (_completedRows.contains(index)) continue;
        final row = table.rows[index];
        final name = _field(row, _ClientField.name);
        if (name == null) {
          failures.add('Row ${index + 2}: missing name');
          continue;
        }
        final candidate = ImportCandidate(
          sourceId: 'csv-$index',
          name: name,
          phone: _field(row, _ClientField.phone),
          email: _field(row, _ClientField.email),
          address: _field(row, _ClientField.address),
        );
        if (_skipDuplicates &&
            isLikelyDuplicate(candidate: candidate, existing: existing)) {
          skipped++;
          completedThisAttempt.add(index);
          continue;
        }
        try {
          final tags = (_field(row, _ClientField.tags) ?? '')
              .split(RegExp(r'[|;]'))
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList();
          await repository.create(
            workspaceId: workspaceId,
            name: name,
            phone: candidate.phone,
            email: candidate.email,
            address: candidate.address,
            notes: _field(row, _ClientField.notes),
            source: 'CSV import',
            status: 'lead',
            preferredContactMethod: candidate.email?.isNotEmpty == true
                ? 'email'
                : 'phone',
            tags: {...tags, 'imported'}.toList(),
          );
          imported++;
          completedThisAttempt.add(index);
          existing.add((
            name: candidate.name,
            phone: candidate.phone,
            email: candidate.email,
          ));
        } catch (_) {
          failures.add('Row ${index + 2}: $name');
        }
      }
      final attemptedRows = List.generate(
        table.rows.length,
        (index) => index,
      ).where((index) => !_completedRows.contains(index));
      final result = reconcileImportAttempt(
        attempted: attemptedRows,
        completed: completedThisAttempt,
      );
      final summary =
          '$imported ${imported == 1 ? 'client was' : 'clients were'} imported'
          '${skipped > 0 ? '; $skipped likely ${skipped == 1 ? 'duplicate was' : 'duplicates were'} skipped' : ''}.'
          '${result.retryable.isNotEmpty ? ' ${result.retryable.length} ${result.retryable.length == 1 ? 'row remains' : 'rows remain'} to retry.' : ''}';
      if (mounted) {
        setState(() {
          _completedRows.addAll(result.completed);
          _error = failures.isEmpty ? null : summary;
        });
      }
      ref.invalidate(clientsProvider);
      ref.invalidate(clientCrmRecordsProvider);
      if (!mounted) return;
      if (imported > 0 || skipped > 0) {
        SlateHaptics.success();
      } else {
        SlateHaptics.warning();
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import complete'),
          content: SingleChildScrollView(
            child: Text(
              failures.isEmpty
                  ? summary
                  : '$summary\n\nRows needing attention:\n${failures.take(8).join('\n')}',
            ),
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
          () => _error =
              'The import could not be completed. No error details were hidden; please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final table = _table;
    return WorkloopPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkloopRouteHeader(title: 'Import CSV'),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Choose a CSV, map its columns, preview the result and confirm before anything is created.',
            style: TextStyle(color: AppColors.t2, fontSize: 15, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.lg),
          WorkloopPrimaryButton(
            label: _loading ? 'Reading file…' : 'Choose CSV file',
            icon: LucideIcons.fileUp,
            onPressed: _loading || _importing || _reviewing
                ? null
                : _chooseFile,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              container: true,
              liveRegion: true,
              label: _error!,
              child: ExcludeSemantics(
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
          if (table != null) ...[
            const SizedBox(height: AppSpacing.xl),
            WorkloopSurface(
              child: Row(
                children: [
                  const Icon(LucideIcons.fileSpreadsheet, color: AppColors.t2),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fileName ?? 'CSV file',
                          style: const TextStyle(
                            color: AppColors.t1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${table.rows.length - _completedRows.length} rows remaining'
                          '${_completedRows.isNotEmpty ? ' · ${_completedRows.length} completed' : ''}'
                          ' · ${table.headers.length} columns',
                          style: const TextStyle(
                            color: AppColors.t3,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const WorkloopSectionHeader(label: 'Match columns'),
            const SizedBox(height: AppSpacing.xs),
            for (var index = 0; index < table.headers.length; index++) ...[
              Text(
                table.headers[index].isEmpty
                    ? 'Column ${index + 1}'
                    : table.headers[index],
                style: const TextStyle(
                  color: AppColors.t2,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              WorkloopPickerField<_ClientField>(
                value: _mapping[index],
                title: 'Map ${table.headers[index]}',
                hint: 'Ignore this column',
                options: const [
                  WorkloopPickerOption(
                    value: _ClientField.ignore,
                    label: 'Ignore this column',
                  ),
                  WorkloopPickerOption(
                    value: _ClientField.name,
                    label: 'Client name',
                  ),
                  WorkloopPickerOption(
                    value: _ClientField.phone,
                    label: 'Phone number',
                  ),
                  WorkloopPickerOption(
                    value: _ClientField.email,
                    label: 'Email address',
                  ),
                  WorkloopPickerOption(
                    value: _ClientField.address,
                    label: 'Booking address',
                  ),
                  WorkloopPickerOption(
                    value: _ClientField.notes,
                    label: 'Client notes',
                  ),
                  WorkloopPickerOption(value: _ClientField.tags, label: 'Tags'),
                ],
                enabled: !_importing && !_reviewing,
                onChanged: (value) => setState(() {
                  if (value != _ClientField.ignore) {
                    for (final entry in _mapping.entries.toList()) {
                      if (entry.key != index && entry.value == value) {
                        _mapping[entry.key] = _ClientField.ignore;
                      }
                    }
                  }
                  _mapping[index] = value;
                }),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.sm),
            const WorkloopSectionHeader(label: 'Preview'),
            const SizedBox(height: AppSpacing.xs),
            WorkloopSurface(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < _candidates().take(5).length;
                    index++
                  )
                    WorkloopListRow(
                      flat: true,
                      showDivider: index != _candidates().take(5).length - 1,
                      leading: const Icon(
                        LucideIcons.user,
                        color: AppColors.t3,
                        size: 18,
                      ),
                      title: Text(
                        _candidates()[index].name,
                        style: const TextStyle(
                          color: AppColors.t1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        [
                          _candidates()[index].phone,
                          _candidates()[index].email,
                        ].whereType<String>().join(' · '),
                        style: const TextStyle(color: AppColors.t3),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _skipDuplicates,
              onChanged: _importing || _reviewing
                  ? null
                  : (value) => setState(() => _skipDuplicates = value),
              title: const Text('Skip likely duplicates'),
              subtitle: const Text(
                'Matches are checked by name, phone and email.',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            WorkloopPrimaryButton(
              label: _importing
                  ? 'Importing…'
                  : _reviewing
                  ? 'Reviewing…'
                  : 'Review import',
              icon: LucideIcons.arrowRight,
              onPressed: _importing || _reviewing ? null : _import,
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
