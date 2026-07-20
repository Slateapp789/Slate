import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/providers/notes_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/repositories/notes_repository.dart';
import '../../shared/widgets/slate_ui.dart';
import '../imports/text_import_screen.dart';

const _uncheckedChecklistMarker = '○  ';
const _checkedChecklistMarker = '✓  ';
const _bulletMarker = '•  ';
final _checklistPattern = RegExp(r'^\s*(?:○|✓|-\s?\[[ xX]\]|\[[ xX]\])\s*');
final _uncheckedChecklistPattern = RegExp(r'^\s*(?:○|-\s?\[ \]|\[ \])\s*');
final _checkedChecklistPattern = RegExp(r'^\s*(?:✓|-\s?\[[xX]\]|\[[xX]\])\s*');
final _partialChecklistPattern = RegExp(r'^\s*(?:-\s?)?\[[ xX]?\]?\s*');
final _bulletPattern = RegExp(r'^\s*(?:•|[-*])\s+(?!\[)');

enum _LineFormat { none, checklist, bullet }

enum _NoteFilter { all, pinned, clients, bookings }

class _ChecklistMarkerInfo {
  final int lineStart;
  final double top;
  final bool checked;

  const _ChecklistMarkerInfo({
    required this.lineStart,
    required this.top,
    required this.checked,
  });
}

class NotesScreen extends ConsumerStatefulWidget {
  final bool showBackButton;
  final int createRequest;

  const NotesScreen({
    super.key,
    this.showBackButton = true,
    this.createRequest = 0,
  });

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _query = '';
  _NoteFilter _filter = _NoteFilter.all;

  @override
  void didUpdateWidget(covariant NotesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.createRequest == oldWidget.createRequest ||
        widget.createRequest == 0) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openEditor();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(allNotesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageX,
                    AppSpacing.lg,
                    AppSpacing.pageX,
                    0,
                  ),
                  child: Row(
                    children: [
                      if (widget.showBackButton) ...[
                        WorkloopIconButton(
                          icon: LucideIcons.chevronLeft,
                          semanticLabel: 'Back',
                          onTap: () => Navigator.maybePop(context),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: WorkloopPageHeader(
                          icon: LucideIcons.fileText,
                          title: 'Notes',
                          subtitle: 'Capture context before it disappears.',
                          color: AppColors.modNotes,
                          trailing: WorkloopIconButton(
                            icon: LucideIcons.plus,
                            semanticLabel: 'New note',
                            color: AppColors.modNotes,
                            backgroundColor: AppColors.modNotes.withValues(
                              alpha: 0.10,
                            ),
                            onTap: () => _openEditor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pageX,
                  ),
                  child: WorkloopSearchField(
                    onChanged: (value) => setState(() => _query = value),
                    hintText: 'Search notes',
                    semanticLabel: 'Search notes',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                notes.maybeWhen(
                  data: (_) => _NoteFilterRail(
                    selected: _filter,
                    onChanged: (value) => setState(() => _filter = value),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: notes.when(
                    loading: () => _loadingList(),
                    error: (_, __) => const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageX,
                      ),
                      child: SlateErrorState(message: 'Could not load notes'),
                    ),
                    data: (data) => _NotesList(
                      notes: _filteredNotes(data),
                      hasSearch: _query.trim().isNotEmpty,
                      onRefresh: () async => ref.invalidate(allNotesProvider),
                      onOpen: (note) => _openEditor(note: note),
                      onCreate: _openEditor,
                      onImport: () async {
                        await Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TextImportScreen(
                              type: TextImportType.notes,
                            ),
                          ),
                        );
                        ref.invalidate(allNotesProvider);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<SlateNote> _filteredNotes(List<SlateNote> notes) {
    final term = _query.trim().toLowerCase();
    return notes.where((note) {
      final matchesFilter = switch (_filter) {
        _NoteFilter.all => true,
        _NoteFilter.pinned => note.pinned,
        _NoteFilter.clients => note.contactId != null,
        _NoteFilter.bookings => note.appointmentId != null,
      };
      if (!matchesFilter) return false;
      if (term.isEmpty) return true;
      return note.title.toLowerCase().contains(term) ||
          note.body.toLowerCase().contains(term) ||
          (note.clientName ?? '').toLowerCase().contains(term);
    }).toList();
  }

  Widget _loadingList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        0,
        AppSpacing.pageX,
        40,
      ),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (_, __) =>
          const SlateLoadingBlock(height: 72, radius: AppRadius.md),
    );
  }

  Future<void> _openEditor({SlateNote? note}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => _NoteEditorScreen(note: note)),
    );
    if (mounted) ref.invalidate(allNotesProvider);
  }
}

class _NoteFilterRail extends StatelessWidget {
  final _NoteFilter selected;
  final ValueChanged<_NoteFilter> onChanged;

  const _NoteFilterRail({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
      child: WorkloopSegmentedControl<_NoteFilter>(
        selected: selected,
        onChanged: onChanged,
        segments: const [
          WorkloopSegment(value: _NoteFilter.all, label: 'All'),
          WorkloopSegment(value: _NoteFilter.pinned, label: 'Pinned'),
          WorkloopSegment(value: _NoteFilter.clients, label: 'Clients'),
          WorkloopSegment(value: _NoteFilter.bookings, label: 'Bookings'),
        ],
      ),
    );
  }
}

class _NotesList extends StatelessWidget {
  final List<SlateNote> notes;
  final bool hasSearch;
  final RefreshCallback onRefresh;
  final ValueChanged<SlateNote> onOpen;
  final VoidCallback onCreate;
  final VoidCallback onImport;

  const _NotesList({
    required this.notes,
    required this.hasSearch,
    required this.onRefresh,
    required this.onOpen,
    required this.onCreate,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final pinned = notes.where((note) => note.pinned).toList();
    final unpinned = notes.where((note) => !note.pinned).toList();
    final groups = _groupNotesByDate(unpinned);

    return RefreshIndicator(
      color: AppColors.accentPrimary,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageX,
          0,
          AppSpacing.pageX,
          112,
        ),
        children: [
          if (notes.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 42),
              child: Column(
                children: [
                  WorkloopEmptyState(
                    icon: LucideIcons.stickyNote,
                    title: hasSearch ? 'No matching notes' : 'No notes yet',
                    subtitle: hasSearch
                        ? 'Try a different search term.'
                        : 'Useful details will appear here.',
                  ),
                  if (!hasSearch) ...[
                    const SizedBox(height: AppSpacing.md),
                    WorkloopPrimaryButton(
                      label: 'Add note',
                      icon: LucideIcons.plus,
                      onPressed: onCreate,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    WorkloopTextButton(
                      label: 'Import notes files',
                      onPressed: onImport,
                    ),
                  ],
                ],
              ),
            )
          else ...[
            if (pinned.isNotEmpty) ...[
              const _NoteDateHeader(label: 'Pinned'),
              _NoteGroupCard(notes: pinned, onOpen: onOpen),
              const SizedBox(height: AppSpacing.lg),
            ],
            for (final group in groups) ...[
              _NoteDateHeader(label: group.label),
              _NoteGroupCard(notes: group.notes, onOpen: onOpen),
              const SizedBox(height: AppSpacing.lg),
            ],
          ],
        ],
      ),
    );
  }
}

class _NoteDateHeader extends StatelessWidget {
  final String label;

  const _NoteDateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: WorkloopSectionHeader(label: label),
    );
  }
}

class _NoteGroupCard extends StatelessWidget {
  final List<SlateNote> notes;
  final ValueChanged<SlateNote> onOpen;

  const _NoteGroupCard({required this.notes, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < notes.length; index++) ...[
          _NoteListRow(note: notes[index], onOpen: onOpen),
        ],
      ],
    );
  }
}

class _NoteListRow extends StatelessWidget {
  final SlateNote note;
  final ValueChanged<SlateNote> onOpen;

  const _NoteListRow({required this.note, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final title = note.title.trim().isEmpty
        ? 'Untitled note'
        : _readablePreviewText(note.title);
    final preview = note.body.trim().isEmpty
        ? 'No additional text'
        : _oneLine(note.body);

    return WorkloopListRow(
      onTap: () => onOpen(note),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      leading: SizedBox(
        width: 28,
        height: 28,
        child: Icon(
          note.pinned ? LucideIcons.pin : LucideIcons.fileText,
          size: 16,
          color: note.pinned ? AppColors.accentPrimary : AppColors.t3,
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.t1,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _noteDateLabel(note),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const TextSpan(text: '  '),
                TextSpan(text: preview),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.t3,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          if (note.clientName != null)
            Text(
              note.clientName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.t3,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: AppColors.t3,
        size: 18,
      ),
    );
  }
}

class _NoteEditorScreen extends ConsumerStatefulWidget {
  final SlateNote? note;

  const _NoteEditorScreen({this.note});

  @override
  ConsumerState<_NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<_NoteEditorScreen> {
  late final _NoteTextController _controller;
  late final FocusNode _focusNode;
  late String _lastEditorText;
  late final String _originalText;
  late bool _pinned;
  late final bool _originalPinned;
  bool _applyingListContinuation = false;
  bool _repairingListMarker = false;
  bool _saving = false;
  bool _allowPop = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = _NoteTextController(
      text: _normalizeLegacyListMarkers(_editorTextFor(widget.note)),
    );
    _lastEditorText = _controller.text;
    _originalText = _controller.text;
    _focusNode = FocusNode();
    _controller.addListener(_handleEditorChanged);
    _focusNode.addListener(_handleEditorChanged);
    _pinned = widget.note?.pinned ?? false;
    _originalPinned = _pinned;
  }

  @override
  void dispose() {
    _controller.removeListener(_handleEditorChanged);
    _focusNode.removeListener(_handleEditorChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final lineFormat = _selectedLineFormat();

    return PopScope(
      canPop: _allowPop || !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) _saveAndClose();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        extendBody: true,
        body: Stack(
          children: [
            const Positioned.fill(child: WorkloopTexturedBackdrop()),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageX,
                      AppSpacing.lg,
                      AppSpacing.pageX,
                      0,
                    ),
                    child: Row(
                      children: [
                        WorkloopIconButton(
                          icon: LucideIcons.chevronLeft,
                          semanticLabel: 'Back to notes',
                          onTap: _saving ? () {} : _saveAndClose,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Expanded(
                          child: Text(
                            'Note',
                            style: TextStyle(
                              color: AppColors.t1,
                              fontSize: 26,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        WorkloopIconButton(
                          icon: _pinned ? LucideIcons.pinOff : LucideIcons.pin,
                          semanticLabel: _pinned ? 'Unpin note' : 'Pin note',
                          color: _pinned ? AppColors.modNotes : AppColors.t2,
                          backgroundColor: _pinned
                              ? AppColors.modNotes.withValues(alpha: 0.12)
                              : null,
                          size: 42,
                          onTap: () => setState(() => _pinned = !_pinned),
                        ),
                        if (isEditing) ...[
                          const SizedBox(width: AppSpacing.xs),
                          WorkloopIconButton(
                            icon: LucideIcons.moreHorizontal,
                            semanticLabel: 'Note actions',
                            color: AppColors.t2,
                            size: 42,
                            onTap: _showNoteActions,
                          ),
                        ],
                        const SizedBox(width: AppSpacing.xs),
                        _NoteDoneAction(loading: _saving, onTap: _saveAndClose),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageX,
                      ),
                      child: SlateErrorState(message: _error!),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageX,
                        0,
                        AppSpacing.pageX,
                        88,
                      ),
                      child: Stack(
                        children: [
                          TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            autofocus: !isEditing,
                            expands: true,
                            maxLines: null,
                            minLines: null,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.newline,
                            style: const TextStyle(
                              color: AppColors.t1,
                              fontSize: 17,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: const InputDecoration(
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintText: 'Note title\nStart writing...',
                              hintStyle: TextStyle(
                                color: AppColors.t3,
                                fontSize: 17,
                                height: 1.55,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          ..._checklistMarkerButtons(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: AnimatedPadding(
          duration: AppMotion.standard,
          curve: AppMotion.curve,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pageX,
            AppSpacing.xs,
            AppSpacing.pageX,
            keyboardInset > 0 ? keyboardInset + AppSpacing.xs : AppSpacing.md,
          ),
          child: _NoteFormatToolbar(
            checklistActive: lineFormat == _LineFormat.checklist,
            bulletActive: lineFormat == _LineFormat.bullet,
            onChecklist: _toggleChecklistLines,
            onBullet: _toggleBulletLines,
          ),
        ),
      ),
    );
  }

  bool get _hasChanges =>
      _controller.text != _originalText || _pinned != _originalPinned;

  Future<void> _showNoteActions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.t1.withValues(alpha: 0.20),
      builder: (sheetContext) => SlateSheetFrame(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Note actions',
              style: TextStyle(
                color: AppColors.t1,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            WorkloopListRow(
              showDivider: false,
              leading: const Icon(
                LucideIcons.trash2,
                size: 18,
                color: AppColors.error,
              ),
              title: const Text(
                'Delete note',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _confirmDelete();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleEditorChanged() {
    if (_repairPartialChecklistMarker()) return;
    _continueListAfterReturn();
    _lastEditorText = _controller.text;
    if (mounted) setState(() {});
  }

  bool _repairPartialChecklistMarker() {
    if (_repairingListMarker || _applyingListContinuation) return false;

    final text = _controller.text;
    final selection = _controller.selection;
    if (text.isEmpty || !selection.isValid) {
      return false;
    }

    final lineStart = _lineStartFor(text, selection.start);
    final lineEnd = _lineEndFor(text, selection.start);
    final line = text.substring(lineStart, lineEnd);
    if (line.trimLeft().startsWith('[]')) {
      final newText = text.replaceRange(
        lineStart,
        lineEnd,
        line.replaceFirst('[]', _uncheckedChecklistMarker.trimRight()),
      );
      _applyChecklistRepair(newText, selection.start + 1);
      return true;
    }

    if (_checklistPattern.hasMatch(line)) return false;

    final partialMatch = _partialChecklistPattern.firstMatch(line);
    if (partialMatch == null || partialMatch.start != 0) return false;

    final repairedLine = line.substring(partialMatch.end).trimLeft();
    final newText = text.replaceRange(lineStart, lineEnd, repairedLine);
    final newOffset = (lineStart + repairedLine.length).clamp(
      0,
      newText.length,
    );

    _applyChecklistRepair(newText, newOffset);
    return true;
  }

  void _applyChecklistRepair(String text, int cursorOffset) {
    _repairingListMarker = true;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: cursorOffset.clamp(0, text.length),
      ),
    );
    _lastEditorText = text;
    _repairingListMarker = false;
    if (mounted) setState(() {});
  }

  Future<void> _saveAndClose() async {
    final saved = await _save();
    if (saved && mounted) {
      _allowPop = true;
      Navigator.pop(context);
    }
  }

  Future<bool> _save() async {
    final draft = _NoteDraft.fromText(_controller.text);
    if (draft.isEmpty && widget.note == null) return true;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repository = ref.read(notesRepositoryProvider);
      final workspaceId = await ref.read(workspaceIdProvider.future);
      if (workspaceId == null) {
        setState(() => _error = 'Workspace is not ready yet.');
        return false;
      }

      final note = widget.note;
      if (note == null) {
        await repository.create(
          workspaceId: workspaceId,
          title: draft.title,
          body: draft.body,
          pinned: _pinned,
        );
      } else {
        await repository.update(
          noteId: note.id,
          title: draft.title,
          body: draft.body,
          contactId: note.contactId,
          appointmentId: note.appointmentId,
          pinned: _pinned,
        );
      }
      ref.invalidate(allNotesProvider);
      return true;
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save this note.');
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final note = widget.note;
    if (note == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Delete note?'),
        content: Text(
          note.title.trim().isEmpty ? 'This note will be deleted.' : note.title,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(notesRepositoryProvider).delete(note.id);
    ref.invalidate(allNotesProvider);
    if (mounted) {
      _allowPop = true;
      Navigator.pop(context);
    }
  }

  void _toggleChecklistLines() {
    final text = _controller.text;
    final selection = _safeSelection(text);
    _replaceSelectedLines(selection, (lines) {
      final editableLines = _nonEmptyLines(lines);
      if (editableLines.isEmpty) return [_uncheckedChecklistMarker];

      final allChecklist = editableLines.every(
        (line) => _checklistPattern.hasMatch(line),
      );
      final markComplete =
          allChecklist &&
          editableLines.any(
            (line) => _uncheckedChecklistPattern.hasMatch(line),
          );
      final markIncomplete =
          allChecklist &&
          editableLines.every(
            (line) => _checkedChecklistPattern.hasMatch(line),
          );

      return lines.map((line) {
        if (line.trim().isEmpty) return line;
        if (markComplete) {
          return line.replaceFirst(
            _uncheckedChecklistPattern,
            _checkedChecklistMarker,
          );
        }
        if (markIncomplete) {
          return line.replaceFirst(
            _checkedChecklistPattern,
            _uncheckedChecklistMarker,
          );
        }
        final cleanLine = _stripListMarker(line);
        return '$_uncheckedChecklistMarker$cleanLine';
      }).toList();
    });
    _focusNode.requestFocus();
  }

  void _toggleBulletLines() {
    final selection = _safeSelection(_controller.text);
    _replaceSelectedLines(selection, (lines) {
      final editableLines = _nonEmptyLines(lines);
      if (editableLines.isEmpty) return [_bulletMarker];

      final removeBullet =
          editableLines.isNotEmpty &&
          editableLines.every((line) => _bulletPattern.hasMatch(line));

      return lines.map((line) {
        if (line.trim().isEmpty) return line;
        final cleanLine = _stripListMarker(line);
        return removeBullet ? cleanLine : '$_bulletMarker$cleanLine';
      }).toList();
    });
    _focusNode.requestFocus();
  }

  void _toggleChecklistLineAt(
    int lineStart,
    String line,
    RegExpMatch checklistMatch,
  ) {
    final checked = _checkedChecklistPattern.hasMatch(line);
    final replacement = checked
        ? _uncheckedChecklistMarker
        : _checkedChecklistMarker;
    final markerStart = lineStart + checklistMatch.start;
    final markerEnd = lineStart + checklistMatch.end;
    final text = _controller.text;
    final newText = text.replaceRange(markerStart, markerEnd, replacement);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (markerStart + replacement.length).clamp(0, newText.length),
      ),
    );
  }

  List<Widget> _checklistMarkerButtons() {
    return _checklistMarkers().map((marker) {
      return Positioned(
        left: -2,
        top: marker.top,
        width: 30,
        height: 26,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _toggleChecklistMarker(marker),
        ),
      );
    }).toList();
  }

  List<_ChecklistMarkerInfo> _checklistMarkers() {
    final markers = <_ChecklistMarkerInfo>[];
    final text = _controller.text;
    if (text.isEmpty) return markers;

    final lines = text.split('\n');
    var offset = 0;
    var top = 0.0;

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final match = _checklistPattern.firstMatch(line);
      if (match != null && match.start == 0) {
        markers.add(
          _ChecklistMarkerInfo(
            lineStart: offset,
            top: top,
            checked: _checkedChecklistPattern.hasMatch(line),
          ),
        );
      }

      top += _estimatedLineHeightFor(index);
      offset += line.length + 1;
    }

    return markers;
  }

  double _estimatedLineHeightFor(int lineIndex) {
    return lineIndex == 0 ? 24 * 1.24 : 17 * 1.45;
  }

  void _toggleChecklistMarker(_ChecklistMarkerInfo marker) {
    final text = _controller.text;
    if (marker.lineStart < 0 || marker.lineStart >= text.length) return;

    final lineEnd = _lineEndFor(text, marker.lineStart);
    final line = text.substring(marker.lineStart, lineEnd);
    final checklistMatch = _checklistPattern.firstMatch(line);
    if (checklistMatch == null || checklistMatch.start != 0) return;

    _toggleChecklistLineAt(marker.lineStart, line, checklistMatch);
    _focusNode.requestFocus();
  }

  void _continueListAfterReturn() {
    if (_applyingListContinuation) return;

    final previousText = _lastEditorText;
    final text = _controller.text;
    final selection = _controller.selection;
    if (!selection.isValid || !selection.isCollapsed) return;
    if (text.length != previousText.length + 1) return;

    final newlineOffset = selection.start - 1;
    if (newlineOffset < 0 ||
        newlineOffset >= text.length ||
        text[newlineOffset] != '\n') {
      return;
    }

    final previousLineStart = _lineStartFor(text, newlineOffset);
    final previousLine = text.substring(previousLineStart, newlineOffset);
    final marker = _nextListMarker(previousLine);
    if (marker == null) return;

    final previousLineBody = _stripListMarker(previousLine).trim();
    if (previousLineBody.isEmpty) {
      _applyEditorValue(
        text.replaceRange(previousLineStart, newlineOffset, ''),
        selection.start - previousLine.length,
      );
      return;
    }

    _applyEditorValue(
      text.replaceRange(selection.start, selection.start, marker),
      selection.start + marker.length,
    );
  }

  String? _nextListMarker(String line) {
    if (_checklistPattern.hasMatch(line)) return _uncheckedChecklistMarker;
    if (_bulletPattern.hasMatch(line)) return _bulletMarker;
    return null;
  }

  _LineFormat _selectedLineFormat() {
    final text = _controller.text;
    if (text.isEmpty || !_focusNode.hasFocus) return _LineFormat.none;
    final selection = _safeSelection(text);
    final lineStart = _lineStartFor(text, selection.start);
    final lineEnd = _lineEndFor(text, selection.start);
    final line = text.substring(lineStart, lineEnd);
    if (_checklistPattern.hasMatch(line)) return _LineFormat.checklist;
    if (_bulletPattern.hasMatch(line)) return _LineFormat.bullet;
    return _LineFormat.none;
  }

  TextSelection _safeSelection(String text) {
    final selection = _controller.selection;
    if (selection.isValid) {
      return TextSelection(
        baseOffset: selection.start.clamp(0, text.length),
        extentOffset: selection.end.clamp(0, text.length),
      );
    }
    return TextSelection.collapsed(offset: text.length);
  }

  int _lineStartFor(String text, int offset) {
    if (text.isEmpty) return 0;
    final safeOffset = offset.clamp(0, text.length);
    return text.lastIndexOf('\n', safeOffset == 0 ? 0 : safeOffset - 1) + 1;
  }

  int _lineEndFor(String text, int offset) {
    if (text.isEmpty) return 0;
    final safeOffset = offset.clamp(0, text.length);
    final lineEnd = text.indexOf('\n', safeOffset);
    return lineEnd == -1 ? text.length : lineEnd;
  }

  void _replaceSelectedLines(
    TextSelection selection,
    List<String> Function(List<String> lines) transform,
  ) {
    final text = _controller.text;
    final start = _lineStartFor(text, selection.start);
    final end = _lineEndFor(text, selection.end);
    final selectedText = text.substring(start, end);
    final transformedText = transform(selectedText.split('\n')).join('\n');
    final newText = text.replaceRange(start, end, transformedText);
    final cursorDelta = transformedText.length - selectedText.length;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (selection.end + cursorDelta).clamp(0, newText.length),
      ),
    );
  }

  List<String> _nonEmptyLines(List<String> lines) {
    return lines.where((line) => line.trim().isNotEmpty).toList();
  }

  String _stripListMarker(String line) {
    return line
        .replaceFirst(_checklistPattern, '')
        .replaceFirst(_bulletPattern, '')
        .trimLeft();
  }

  void _applyEditorValue(String text, int cursorOffset) {
    _applyingListContinuation = true;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: cursorOffset.clamp(0, text.length),
      ),
    );
    _lastEditorText = text;
    _applyingListContinuation = false;
  }
}

class _NoteFormatToolbar extends StatelessWidget {
  final bool checklistActive;
  final bool bulletActive;
  final VoidCallback onChecklist;
  final VoidCallback onBullet;

  const _NoteFormatToolbar({
    required this.checklistActive,
    required this.bulletActive,
    required this.onChecklist,
    required this.onBullet,
  });

  @override
  Widget build(BuildContext context) {
    return SlateSurface(
      color: AppColors.bgCard.withValues(alpha: 0.92),
      borderColor: AppColors.t1.withValues(alpha: 0.08),
      radius: AppRadius.lg,
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: _FormatButton(
              icon: LucideIcons.checkSquare,
              label: 'Checklist',
              active: checklistActive,
              onTap: onChecklist,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _FormatButton(
              icon: LucideIcons.list,
              label: 'Bullets',
              active: bulletActive,
              onTap: onBullet,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteDoneAction extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _NoteDoneAction({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.modNotes.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 62, minHeight: 42),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: AppColors.modNotes,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Done',
                    style: TextStyle(
                      color: AppColors.modNotes,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FormatButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        selected: active,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.curve,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.modNotes.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: active ? AppColors.modNotes : AppColors.t2,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? AppColors.modNotes : AppColors.t2,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteDraft {
  final String title;
  final String body;

  const _NoteDraft({required this.title, required this.body});

  bool get isEmpty => title.trim().isEmpty && body.trim().isEmpty;

  factory _NoteDraft.fromText(String text) {
    final normalized = text.replaceAll('\r\n', '\n').trimRight();
    final lines = normalized.split('\n');
    final titleIndex = lines.indexWhere((line) => line.trim().isNotEmpty);
    if (titleIndex == -1) return const _NoteDraft(title: '', body: '');

    final title = lines[titleIndex].trim();
    final body = lines.skip(titleIndex + 1).join('\n').trim();
    return _NoteDraft(
      title: title.isEmpty ? 'Untitled note' : title,
      body: body,
    );
  }
}

class _NoteTextController extends TextEditingController {
  _NoteTextController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final headingStyle = baseStyle.copyWith(
      fontSize: 24,
      height: 1.24,
      fontWeight: FontWeight.w900,
      color: AppColors.t1,
    );
    final bodyStyle = baseStyle.copyWith(
      fontSize: 17,
      height: 1.45,
      fontWeight: FontWeight.w500,
      color: AppColors.t1,
    );

    final newlineIndex = text.indexOf('\n');
    if (newlineIndex == -1) {
      return TextSpan(children: _styledTextSpans(text, headingStyle));
    }

    return TextSpan(
      children: [
        ..._styledTextSpans(text.substring(0, newlineIndex), headingStyle),
        TextSpan(
          text: text.substring(newlineIndex, newlineIndex + 1),
          style: bodyStyle,
        ),
        ..._styledTextSpans(text.substring(newlineIndex + 1), bodyStyle),
      ],
    );
  }

  List<TextSpan> _styledTextSpans(String value, TextStyle style) {
    final spans = <TextSpan>[];
    final lines = value.split('\n');

    for (var index = 0; index < lines.length; index++) {
      spans.addAll(_styledLineSpans(lines[index], style));
      if (index != lines.length - 1) {
        spans.add(TextSpan(text: '\n', style: style));
      }
    }

    if (spans.isEmpty) return [TextSpan(text: value, style: style)];
    return spans;
  }

  List<TextSpan> _styledLineSpans(String value, TextStyle style) {
    final spans = <TextSpan>[];
    final cursor = _addListMarkerSpan(value, style, spans);

    if (cursor < value.length) {
      spans.add(TextSpan(text: value.substring(cursor), style: style));
    }
    if (spans.isEmpty) return [TextSpan(text: value, style: style)];
    return spans;
  }

  int _addListMarkerSpan(String value, TextStyle style, List<TextSpan> spans) {
    final checklistMatch = _checklistPattern.firstMatch(value);
    if (checklistMatch != null && checklistMatch.start == 0) {
      final rawMarker = value.substring(0, checklistMatch.end);
      final checked = _checkedChecklistPattern.hasMatch(rawMarker);
      spans.add(
        TextSpan(
          text: checked ? _checkedChecklistMarker : _uncheckedChecklistMarker,
          style: style.copyWith(
            color: checked ? AppColors.slateLight : AppColors.t3,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      return checklistMatch.end;
    }

    final bulletMatch = _bulletPattern.firstMatch(value);
    if (bulletMatch != null && bulletMatch.start == 0) {
      spans.add(
        TextSpan(
          text: _bulletMarker,
          style: style.copyWith(
            color: AppColors.t3,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
      return bulletMatch.end;
    }

    return 0;
  }
}

class _NoteDateGroup {
  final String label;
  final List<SlateNote> notes;

  const _NoteDateGroup({required this.label, required this.notes});
}

List<_NoteDateGroup> _groupNotesByDate(List<SlateNote> notes) {
  final now = DateTime.now();
  final groups = <_NoteDateGroup>[];

  for (final note in notes) {
    final label = _dateGroupLabel(note.updatedAt ?? note.createdAt, now);
    if (groups.isEmpty || groups.last.label != label) {
      groups.add(_NoteDateGroup(label: label, notes: [note]));
    } else {
      groups.last.notes.add(note);
    }
  }

  return groups;
}

String _dateGroupLabel(DateTime? value, DateTime now) {
  if (value == null) return 'Earlier';

  final local = value.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final noteDay = DateTime(local.year, local.month, local.day);
  final daysAgo = today.difference(noteDay).inDays;

  if (daysAgo <= 0) return 'Today';
  if (daysAgo == 1) return 'Yesterday';
  if (daysAgo < 7) return 'Previous 7 Days';
  if (daysAgo < 30) return 'Previous 30 Days';

  final month = _monthName(local.month);
  return local.year == now.year ? month : '$month ${local.year}';
}

String _editorTextFor(SlateNote? note) {
  if (note == null) return '';
  final title = note.title.trim();
  final body = note.body.trim();
  if (title.isEmpty) return body;
  if (body.isEmpty) return title;
  return '$title\n$body';
}

String _normalizeLegacyListMarkers(String value) {
  return value
      .split('\n')
      .map((line) {
        return line
            .replaceFirst(RegExp(r'^(\s*)(?:-\s)?\[ \]\s*'), r'$1○  ')
            .replaceFirst(RegExp(r'^(\s*)(?:-\s)?\[[xX]\]\s*'), r'$1✓  ')
            .replaceFirst(RegExp(r'^(\s*)[-*]\s+(?!\[)'), r'$1•  ');
      })
      .join('\n');
}

String _noteDateLabel(SlateNote note) {
  final date = note.updatedAt ?? note.createdAt;
  if (date == null) return 'Saved note';
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}

String _oneLine(String value) {
  return _readablePreviewText(
    value,
  ).split(RegExp(r'\s+')).where((part) => part.trim().isNotEmpty).join(' ');
}

String _readablePreviewText(String value) {
  return value
      .split('\n')
      .map((line) {
        final withoutLists = line
            .replaceFirst(_uncheckedChecklistPattern, '○ ')
            .replaceFirst(_checkedChecklistPattern, '✓ ')
            .replaceFirst(_bulletPattern, '• ');
        return withoutLists.replaceAllMapped(
          RegExp(r'\[([^\]]+)\]\([^)]+\)'),
          (match) => match.group(1) ?? '',
        );
      })
      .join('\n');
}

String _monthName(int month) {
  return switch (month) {
    1 => 'January',
    2 => 'February',
    3 => 'March',
    4 => 'April',
    5 => 'May',
    6 => 'June',
    7 => 'July',
    8 => 'August',
    9 => 'September',
    10 => 'October',
    11 => 'November',
    12 => 'December',
    _ => 'Earlier',
  };
}
