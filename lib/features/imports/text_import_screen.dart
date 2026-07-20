import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/providers/notes_provider.dart';
import '../../shared/providers/tasks_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/repositories/notes_repository.dart';
import '../../shared/repositories/tasks_repository.dart';
import '../../shared/widgets/slate_ui.dart';

enum TextImportType { notes, tasks }

class TextImportScreen extends ConsumerStatefulWidget {
  final TextImportType type;

  const TextImportScreen({super.key, required this.type});

  @override
  ConsumerState<TextImportScreen> createState() => _TextImportScreenState();
}

class _TextImportScreenState extends ConsumerState<TextImportScreen> {
  final List<({String name, String content})> _files = [];
  final Set<int> _selected = {};
  bool _loading = false;
  bool _importing = false;
  String? _message;

  String get _noun => widget.type == TextImportType.notes ? 'notes' : 'tasks';

  Future<void> _chooseFiles() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: widget.type == TextImportType.notes
            ? const ['txt', 'md', 'markdown']
            : const ['txt', 'md'],
        allowMultiple: true,
        withData: true,
      );
      if (result == null) return;
      final files = <({String name, String content})>[];
      for (final file in result.files) {
        if (file.bytes == null) continue;
        String content;
        try {
          content = utf8.decode(file.bytes!);
        } on FormatException {
          content = latin1.decode(file.bytes!);
        }
        if (content.trim().isNotEmpty) {
          files.add((name: file.name, content: content.trim()));
        }
      }
      if (!mounted) return;
      setState(() {
        _files
          ..clear()
          ..addAll(files);
        _selected
          ..clear()
          ..addAll(List.generate(files.length, (index) => index));
        _message = files.isEmpty ? 'No readable text was found.' : null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'The selected files could not be read.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _import() async {
    if (_selected.isEmpty) return;
    setState(() => _importing = true);
    var imported = 0;
    final failures = <String>[];
    try {
      final workspaceId = await ref.read(workspaceIdProvider.future);
      if (workspaceId == null) throw StateError('Workspace unavailable');
      for (final index in _selected.toList()..sort()) {
        final file = _files[index];
        try {
          if (widget.type == TextImportType.notes) {
            final lines = file.content.split(RegExp(r'\r?\n'));
            final titleCandidate = lines.first
                .replaceFirst(RegExp(r'^#+\s*'), '')
                .trim();
            await ref
                .read(notesRepositoryProvider)
                .create(
                  workspaceId: workspaceId,
                  title: titleCandidate.isEmpty
                      ? _titleFromFile(file.name)
                      : titleCandidate,
                  body: file.content,
                );
            imported++;
          } else {
            final lines = file.content
                .split(RegExp(r'\r?\n'))
                .map(
                  (line) =>
                      line.replaceFirst(RegExp(r'^\s*[-*\d.)]+\s*'), '').trim(),
                )
                .where((line) => line.isNotEmpty);
            for (final line in lines) {
              await ref
                  .read(tasksRepositoryProvider)
                  .create(
                    workspaceId: workspaceId,
                    title: line,
                    priority: 'medium',
                  );
              imported++;
            }
          }
        } catch (_) {
          failures.add(file.name);
        }
      }
      ref.invalidate(allNotesProvider);
      ref.invalidate(tasksProvider);
      if (!mounted) return;
      SlateHaptics.success();
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${_capitalise(_noun)} imported'),
          content: Text(
            failures.isEmpty
                ? '$imported $_noun were created.'
                : '$imported created. ${failures.length} files could not be imported: ${failures.join(', ')}.',
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
        setState(() => _message = 'The import could not be completed.');
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  String _titleFromFile(String name) {
    return name.replaceFirst(
      RegExp(r'\.(txt|md|markdown)$', caseSensitive: false),
      '',
    );
  }

  String _capitalise(String value) {
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final isNotes = widget.type == TextImportType.notes;
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
              Expanded(
                child: Text(
                  'Import ${isNotes ? 'notes' : 'tasks'}',
                  style: const TextStyle(
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
          Text(
            isNotes
                ? 'Import plain text or Markdown'
                : 'Turn a text list into tasks',
            style: const TextStyle(
              color: AppColors.t1,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isNotes
                ? 'Apple Notes and Google Keep do not provide safe direct access. Exported .txt and .md files keep you in control.'
                : 'Each non-empty line becomes an open task. Review the files before confirming.',
            style: const TextStyle(color: AppColors.t3, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.lg),
          WorkloopPrimaryButton(
            label: _loading ? 'Reading files…' : 'Choose files',
            icon: LucideIcons.fileUp,
            onPressed: _loading ? null : _chooseFiles,
          ),
          if (_message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_message!, style: const TextStyle(color: AppColors.t3)),
          ],
          if (_files.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: WorkloopSectionHeader(
                    label:
                        '${_files.length} ${_files.length == 1 ? 'file' : 'files'} ready',
                  ),
                ),
                WorkloopTextButton(
                  label: _selected.length == _files.length
                      ? 'Clear'
                      : 'Select all',
                  onPressed: () => setState(() {
                    if (_selected.length == _files.length) {
                      _selected.clear();
                    } else {
                      _selected
                        ..clear()
                        ..addAll(
                          List.generate(_files.length, (index) => index),
                        );
                    }
                  }),
                ),
              ],
            ),
            WorkloopSurface(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  for (var index = 0; index < _files.length; index++)
                    WorkloopListRow(
                      onTap: () => setState(() {
                        if (!_selected.add(index)) _selected.remove(index);
                      }),
                      showDivider: index != _files.length - 1,
                      leading: Checkbox.adaptive(
                        value: _selected.contains(index),
                        onChanged: (value) => setState(() {
                          if (value == true) {
                            _selected.add(index);
                          } else {
                            _selected.remove(index);
                          }
                        }),
                      ),
                      title: Text(
                        _files[index].name,
                        style: const TextStyle(
                          color: AppColors.t1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        _files[index].content.replaceAll(RegExp(r'\s+'), ' '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.t3),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            WorkloopPrimaryButton(
              label: _importing ? 'Importing…' : 'Import selected',
              icon: LucideIcons.download,
              onPressed: _importing || _selected.isEmpty ? null : _import,
            ),
          ],
        ],
      ),
    );
  }
}
