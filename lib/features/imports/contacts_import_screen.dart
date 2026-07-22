import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as device;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/repositories/clients_repository.dart';
import '../../shared/widgets/slate_ui.dart';
import 'import_models.dart';

class ContactsImportScreen extends ConsumerStatefulWidget {
  const ContactsImportScreen({super.key});

  @override
  ConsumerState<ContactsImportScreen> createState() =>
      _ContactsImportScreenState();
}

class _ContactsImportScreenState extends ConsumerState<ContactsImportScreen> {
  final _searchController = TextEditingController();
  List<ImportCandidate> _contacts = const [];
  final Set<String> _selected = {};
  bool _loading = false;
  bool _importing = false;
  bool _includeDuplicates = false;
  String _query = '';
  String? _message;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      var permission = await device.FlutterContacts.permissions.check(
        device.PermissionType.read,
      );
      if (permission == device.PermissionStatus.notDetermined ||
          permission == device.PermissionStatus.denied) {
        permission = await device.FlutterContacts.permissions.request(
          device.PermissionType.read,
        );
      }
      if (permission != device.PermissionStatus.granted &&
          permission != device.PermissionStatus.limited) {
        if (!mounted) return;
        setState(() {
          _message = permission == device.PermissionStatus.restricted
              ? 'Contacts access is restricted on this device.'
              : 'Contacts access is off. You can enable it in system settings.';
        });
        return;
      }

      final existingClients = await ref.read(clientsProvider.future);
      final existing = existingClients
          .map(
            (client) =>
                (name: client.name, phone: client.phone, email: client.email),
          )
          .toList();
      final contacts = await device.FlutterContacts.getAll(
        properties: const {
          device.ContactProperty.name,
          device.ContactProperty.phone,
          device.ContactProperty.email,
          device.ContactProperty.address,
          device.ContactProperty.organization,
        },
      );
      final mapped =
          contacts
              .map((contact) {
                final displayName = contact.displayName?.trim();
                final organisation = contact.organizations.isEmpty
                    ? null
                    : contact.organizations.first.name?.trim();
                final name = displayName?.isNotEmpty == true
                    ? displayName!
                    : organisation ?? '';
                if (name.isEmpty) return null;
                final candidate = ImportCandidate(
                  sourceId: contact.id ?? name,
                  name: name,
                  phone: contact.phones.isEmpty
                      ? null
                      : contact.phones.first.number,
                  email: contact.emails.isEmpty
                      ? null
                      : contact.emails.first.address,
                  address: contact.addresses.isEmpty
                      ? null
                      : contact.addresses.first.formatted,
                );
                return candidate.copyWith(
                  likelyDuplicate: isLikelyDuplicate(
                    candidate: candidate,
                    existing: existing,
                  ),
                );
              })
              .whereType<ImportCandidate>()
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
      if (!mounted) return;
      setState(() {
        _contacts = mapped;
        _selected.clear();
        _message = mapped.isEmpty ? 'No importable contacts were found.' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Contacts could not be loaded. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openSettings() async {
    await device.FlutterContacts.permissions.openSettings();
  }

  List<ImportCandidate> get _visibleContacts {
    final query = normaliseImportValue(_query);
    if (query.isEmpty) return _contacts;
    return _contacts.where((contact) {
      return normaliseImportValue(contact.name).contains(query) ||
          normaliseImportValue(contact.email).contains(query) ||
          normalisePhone(contact.phone).contains(normalisePhone(query));
    }).toList();
  }

  Future<void> _reviewImport() async {
    final candidates = _contacts
        .where((item) => _selected.contains(item.sourceId))
        .where((item) => _includeDuplicates || !item.likelyDuplicate)
        .toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one new contact.')),
      );
      return;
    }
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: SlateTheme.of(context).scrim,
      builder: (context) => SlateSheetFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Review contact import',
              style: TextStyle(
                color: AppColors.t1,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${candidates.length} ${candidates.length == 1 ? 'client' : 'clients'} will be created with available name, phone, email and postal address details.',
              style: const TextStyle(
                color: AppColors.t3,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            WorkloopPrimaryButton(
              label: 'Import ${candidates.length}',
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
    if (confirmed == true) await _import(candidates);
  }

  Future<void> _import(List<ImportCandidate> candidates) async {
    setState(() => _importing = true);
    var success = 0;
    final failures = <String>[];
    try {
      final workspaceId = await ref.read(workspaceIdProvider.future);
      if (workspaceId == null) throw StateError('Workspace unavailable');
      final repository = ref.read(clientsRepositoryProvider);
      for (final candidate in candidates) {
        try {
          await repository.create(
            workspaceId: workspaceId,
            name: candidate.name,
            phone: candidate.phone,
            email: candidate.email,
            address: candidate.address,
            source: 'Device contacts',
            status: 'lead',
            preferredContactMethod: candidate.email?.isNotEmpty == true
                ? 'email'
                : 'phone',
            tags: const ['imported'],
          );
          success++;
        } catch (_) {
          failures.add(candidate.name);
        }
      }
      ref.invalidate(clientsProvider);
      ref.invalidate(clientCrmRecordsProvider);
      if (!mounted) return;
      SlateHaptics.success();
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import complete'),
          content: Text(
            failures.isEmpty
                ? '$success ${success == 1 ? 'client was' : 'clients were'} added.'
                : '$success added. ${failures.length} could not be added: ${failures.take(3).join(', ')}${failures.length > 3 ? '…' : ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (failures.isEmpty && mounted) Navigator.pop(context, success);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleContacts;
    final duplicateCount = _contacts
        .where((item) => _selected.contains(item.sourceId))
        .where((item) => item.likelyDuplicate)
        .length;
    return WorkloopPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ImportHeader(
            title: 'Import contacts',
            onBack: () => Navigator.pop(context),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'Choose who to bring into Workloop',
            style: TextStyle(
              color: AppColors.t1,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Workloop reads only the contacts you review here. Nothing is imported until you confirm.',
            style: TextStyle(color: AppColors.t3, fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_contacts.isEmpty && !_loading) ...[
            WorkloopSurface(
              child: Column(
                children: [
                  const Icon(
                    LucideIcons.contact,
                    size: 30,
                    color: AppColors.t2,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _message ?? 'Contact access has not been requested.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.t2, height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  WorkloopPrimaryButton(
                    label: 'Choose contacts',
                    icon: LucideIcons.contact,
                    onPressed: _loadContacts,
                  ),
                  if (_message?.contains('settings') == true) ...[
                    const SizedBox(height: AppSpacing.xs),
                    WorkloopTextButton(
                      label: 'Open system settings',
                      onPressed: _openSettings,
                    ),
                  ],
                ],
              ),
            ),
          ] else if (_loading) ...[
            const Center(child: CircularProgressIndicator()),
          ] else ...[
            WorkloopSearchField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              hintText: 'Search contacts',
              semanticLabel: 'Search device contacts',
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selected.length} selected',
                    style: const TextStyle(
                      color: AppColors.t2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                WorkloopTextButton(
                  label: _selected.length == visible.length
                      ? 'Clear'
                      : 'Select all',
                  onPressed: () => setState(() {
                    if (_selected.length == visible.length) {
                      _selected.clear();
                    } else {
                      _selected.addAll(visible.map((item) => item.sourceId));
                    }
                  }),
                ),
              ],
            ),
            WorkloopSurface(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 520),
                child: visible.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                        child: Text(
                          'No contacts match this search.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.t3),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: visible.length,
                        itemBuilder: (context, index) => _ContactRow(
                          contact: visible[index],
                          selected: _selected.contains(visible[index].sourceId),
                          showDivider: index != visible.length - 1,
                          onChanged: (selected) => setState(() {
                            if (selected) {
                              _selected.add(visible[index].sourceId);
                            } else {
                              _selected.remove(visible[index].sourceId);
                            }
                          }),
                        ),
                      ),
              ),
            ),
            if (duplicateCount > 0) ...[
              const SizedBox(height: AppSpacing.md),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _includeDuplicates,
                onChanged: (value) =>
                    setState(() => _includeDuplicates = value),
                title: const Text('Create likely duplicates separately'),
                subtitle: Text(
                  _includeDuplicates
                      ? 'The $duplicateCount possible ${duplicateCount == 1 ? 'match will' : 'matches will'} also be imported.'
                      : '$duplicateCount possible ${duplicateCount == 1 ? 'match will' : 'matches will'} be skipped.',
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            WorkloopPrimaryButton(
              label: _importing ? 'Importing…' : 'Review import',
              icon: LucideIcons.arrowRight,
              onPressed: _selected.isEmpty || _importing ? null : _reviewImport,
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final ImportCandidate contact;
  final bool selected;
  final bool showDivider;
  final ValueChanged<bool> onChanged;

  const _ContactRow({
    required this.contact,
    required this.selected,
    required this.showDivider,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      contact.phone,
      contact.email,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');
    return WorkloopListRow(
      onTap: () => onChanged(!selected),
      showDivider: showDivider,
      leading: Checkbox.adaptive(
        value: selected,
        onChanged: (value) => onChanged(value ?? false),
      ),
      title: Text(
        contact.name,
        style: const TextStyle(
          color: AppColors.t1,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.t3),
            ),
      trailing: contact.likelyDuplicate
          ? const Text(
              'Possible match',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

class _ImportHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _ImportHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        WorkloopIconButton(
          icon: LucideIcons.chevronLeft,
          semanticLabel: 'Back',
          onTap: onBack,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.t1,
              fontSize: 26,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
