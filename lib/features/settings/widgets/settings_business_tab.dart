import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/workspace_provider.dart';
import '../../../shared/repositories/slate_repositories.dart';
import '../../../shared/utils/working_hours.dart';
import '../providers/settings_providers.dart';
import 'settings_helpers.dart';
import 'settings_services_section.dart';

class SettingsBusinessTab extends ConsumerStatefulWidget {
  const SettingsBusinessTab({super.key});

  @override
  ConsumerState<SettingsBusinessTab> createState() =>
      _SettingsBusinessTabState();
}

class _HoursBlockControllers {
  final TextEditingController startController;
  final TextEditingController endController;

  _HoursBlockControllers({required String start, required String end})
    : startController = TextEditingController(text: start),
      endController = TextEditingController(text: end);
}

class _SettingsBusinessTabState extends ConsumerState<SettingsBusinessTab> {
  bool _editingInfo = false;
  bool _saving = false;
  late TextEditingController _nameController;
  late TextEditingController _industryController;
  late TextEditingController _handleController;
  late TextEditingController _bioController;
  late TextEditingController _noticeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _industryController = TextEditingController();
    _handleController = TextEditingController();
    _bioController = TextEditingController();
    _noticeController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _industryController.dispose();
    _handleController.dispose();
    _bioController.dispose();
    _noticeController.dispose();
    super.dispose();
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _saveInfo(String workspaceId) async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(workspaceRepositoryProvider).update(workspaceId, {
        'name': _nameController.text.trim(),
        'industry': _industryController.text.trim().isEmpty
            ? null
            : _industryController.text.trim(),
      });
      ref.invalidate(workspaceProvider);
      setState(() {
        _editingInfo = false;
        _saving = false;
      });
      if (mounted) _snack('Business details updated', AppColors.green);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) _snack('Error: $e', AppColors.error);
    }
  }

  Future<void> _saveProfile(String workspaceId) async {
    final handle = _handleController.text.trim().toLowerCase();
    if (handle.length < 3) {
      _snack('Handle must be at least 3 characters', AppColors.warning);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateWorkspaceProfile(
            workspaceId: workspaceId,
            values: {
              'handle': handle,
              'bio': _bioController.text.trim().isEmpty
                  ? null
                  : _bioController.text.trim(),
              'notice_text': _noticeController.text.trim().isEmpty
                  ? null
                  : _noticeController.text.trim(),
            },
          );
      ref.invalidate(settingsBusinessProfileProvider);
      setState(() => _saving = false);
      if (mounted) _snack('Profile updated', AppColors.green);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) _snack('Error: $e', AppColors.error);
    }
  }

  void _showHoursSheet(Map<String, dynamic> settings) {
    final rawHours = Map<String, dynamic>.from(
      settings['working_hours'] as Map? ?? {},
    );
    final enabled = <String, bool>{};
    final blockControllers = <String, List<_HoursBlockControllers>>{};

    for (final day in workingHourDays) {
      final shortDay = shortToLongDay.entries
          .firstWhere((entry) => entry.value == day)
          .key;
      final rawDay = rawHours[day] ?? rawHours[shortDay];
      final value = rawDay is Map
          ? Map<String, dynamic>.from(rawDay)
          : <String, dynamic>{};
      final blocks = workingHourBlocks(
        value.isEmpty ? defaultWorkingHours()[day] : value,
      );
      enabled[day] =
          value['enabled'] as bool? ?? blocks.isNotEmpty && day != 'Sunday';
      blockControllers[day] = blocks.isEmpty
          ? [_HoursBlockControllers(start: '09:00', end: '17:00')]
          : blocks
                .map(
                  (block) => _HoursBlockControllers(
                    start: block.start,
                    end: block.end,
                  ),
                )
                .toList();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (ctx, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              settingsHandle(),
              const SizedBox(height: 20),
              const Text(
                'Working Hours',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.t1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'These hours appear on your public profile and will guide booking rules.',
                style: TextStyle(color: AppColors.t3, fontSize: 13),
              ),
              const SizedBox(height: 18),
              ...workingHourDays.map((day) {
                final blocks = blockControllers[day]!;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgInteract,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              day,
                              style: const TextStyle(
                                color: AppColors.t1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Switch(
                            value: enabled[day]!,
                            activeThumbColor: AppColors.green,
                            onChanged: (value) =>
                                setModal(() => enabled[day] = value),
                          ),
                        ],
                      ),
                      if (enabled[day]!) ...[
                        const SizedBox(height: 8),
                        ...blocks.asMap().entries.map((entry) {
                          final index = entry.key;
                          final block = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == blocks.length - 1 ? 0 : 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _timeField(
                                    label: 'Start',
                                    controller: block.startController,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _timeField(
                                    label: 'End',
                                    controller: block.endController,
                                  ),
                                ),
                                if (blocks.length > 1) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () =>
                                        setModal(() => blocks.removeAt(index)),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.t3,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => setModal(
                            () => blocks.add(
                              _HoursBlockControllers(
                                start: '16:00',
                                end: '21:00',
                              ),
                            ),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.add_rounded,
                                color: AppColors.green,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Add another block',
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (blocks.length > 1) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'The gap between blocks is treated as a break.',
                            style: TextStyle(color: AppColors.t3, fontSize: 12),
                          ),
                        ],
                      ],
                    ],
                  ),
                );
              }),
              const SizedBox(height: 10),
              saveBtn(
                label: 'Save Hours',
                onTap: () async {
                  final workspaceId = await ref.read(
                    workspaceIdProvider.future,
                  );
                  if (workspaceId == null) return;
                  final nextHours = <String, dynamic>{};
                  for (final day in workingHourDays) {
                    final blocks = blockControllers[day]!
                        .map(
                          (block) => {
                            'start': block.startController.text.trim(),
                            'end': block.endController.text.trim(),
                          },
                        )
                        .toList();
                    nextHours[day] = {
                      'enabled': enabled[day],
                      'blocks': blocks,
                      if (blocks.isNotEmpty) 'start': blocks.first['start'],
                      if (blocks.isNotEmpty) 'end': blocks.last['end'],
                    };
                  }
                  await ref.read(workspaceSettingsRepositoryProvider).update(
                    workspaceId,
                    {'working_hours': nextHours},
                  );
                  ref.invalidate(settingsWorkspaceSettingsProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) _snack('Working hours updated', AppColors.green);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.datetime,
      style: const TextStyle(color: AppColors.t1, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.t3),
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
      ),
    );
  }

  void _showAddServiceSheet() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final durCtrl = TextEditingController(text: '60');
    final descCtrl = TextEditingController();
    bool showOnProfile = true;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              settingsHandle(),
              const SizedBox(height: 20),
              const Text(
                'New Service',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.t1,
                ),
              ),
              const SizedBox(height: 16),
              settingsField(
                label: 'SERVICE NAME',
                controller: nameCtrl,
                hint: 'e.g. 1-on-1 PT Session',
                autofocus: true,
              ),
              const SizedBox(height: 12),
              settingsField(
                label: 'DESCRIPTION',
                controller: descCtrl,
                hint: 'Optional public description',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: settingsField(
                      label: 'PRICE (£)',
                      controller: priceCtrl,
                      hint: '65',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: settingsField(
                      label: 'DURATION (MIN)',
                      controller: durCtrl,
                      hint: '60',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: showOnProfile,
                activeThumbColor: AppColors.green,
                title: const Text(
                  'Show on public profile',
                  style: TextStyle(
                    color: AppColors.t1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Clients can request this service from your link.',
                  style: TextStyle(color: AppColors.t3, fontSize: 12),
                ),
                onChanged: (value) => setModal(() => showOnProfile = value),
              ),
              const SizedBox(height: 20),
              saveBtn(
                label: 'Add Service',
                loading: saving,
                onTap: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  setModal(() => saving = true);
                  try {
                    final wsId = await ref.read(workspaceIdProvider.future);
                    if (wsId == null) return;
                    await ref
                        .read(servicesRepositoryProvider)
                        .create(
                          workspaceId: wsId,
                          name: nameCtrl.text.trim(),
                          price: double.tryParse(priceCtrl.text) ?? 0,
                          durationMins: int.tryParse(durCtrl.text) ?? 60,
                          description: descCtrl.text,
                          showOnProfile: showOnProfile,
                        );
                    ref.invalidate(settingsServicesProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    setModal(() => saving = false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditServiceSheet(Map<String, dynamic> svc) {
    final nameCtrl = TextEditingController(text: svc['name'] as String? ?? '');
    final priceCtrl = TextEditingController(
      text: (svc['price'] as num?)?.toStringAsFixed(0) ?? '',
    );
    final durCtrl = TextEditingController(
      text: svc['duration_mins']?.toString() ?? '60',
    );
    final descCtrl = TextEditingController(
      text: svc['description'] as String? ?? '',
    );
    bool showOnProfile = svc['show_on_profile'] as bool? ?? true;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              settingsHandle(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Service',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.t1,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmDelete(svc);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorDim,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              settingsField(
                label: 'SERVICE NAME',
                controller: nameCtrl,
                hint: 'e.g. 1-on-1 PT Session',
              ),
              const SizedBox(height: 12),
              settingsField(
                label: 'DESCRIPTION',
                controller: descCtrl,
                hint: 'Optional public description',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: settingsField(
                      label: 'PRICE (£)',
                      controller: priceCtrl,
                      hint: '65',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: settingsField(
                      label: 'DURATION (MIN)',
                      controller: durCtrl,
                      hint: '60',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: showOnProfile,
                activeThumbColor: AppColors.green,
                title: const Text(
                  'Show on public profile',
                  style: TextStyle(
                    color: AppColors.t1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Clients can request this service from your link.',
                  style: TextStyle(color: AppColors.t3, fontSize: 12),
                ),
                onChanged: (value) => setModal(() => showOnProfile = value),
              ),
              const SizedBox(height: 20),
              saveBtn(
                label: 'Save Changes',
                loading: saving,
                onTap: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  setModal(() => saving = true);
                  try {
                    await ref.read(servicesRepositoryProvider).update(
                      svc['id'] as String,
                      {
                        'name': nameCtrl.text.trim(),
                        'price':
                            double.tryParse(priceCtrl.text) ?? svc['price'],
                        'duration_mins':
                            int.tryParse(durCtrl.text) ?? svc['duration_mins'],
                        'description': descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                        'show_on_profile': showOnProfile,
                      },
                    );
                    ref.invalidate(settingsServicesProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) _snack('Service updated', AppColors.green);
                  } catch (e) {
                    setModal(() => saving = false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> svc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              settingsHandle(),
              const SizedBox(height: 24),
              Text(
                'Delete "${svc['name']}"?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.t1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "This won't affect existing appointments.",
                style: TextStyle(fontSize: 14, color: AppColors.t3),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              saveBtn(
                label: 'Delete Service',
                color: AppColors.error,
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(servicesRepositoryProvider)
                      .delete(svc['id'] as String);
                  ref.invalidate(settingsServicesProvider);
                  if (mounted) _snack('Service deleted', AppColors.error);
                },
              ),
              const SizedBox(height: 10),
              cancelBtn(ctx),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(workspaceProvider);
    final profile = ref.watch(settingsBusinessProfileProvider);
    final workspaceSettings = ref.watch(settingsWorkspaceSettingsProvider);
    final services = ref.watch(settingsServicesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(workspaceProvider);
        ref.invalidate(settingsBusinessProfileProvider);
        ref.invalidate(settingsWorkspaceSettingsProvider);
        ref.invalidate(settingsServicesProvider);
      },
      color: AppColors.green,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        children: [
          // ── Business info ────────────────────────────────────────────────
          sectionLabel('Business Info'),
          const SizedBox(height: 10),
          workspace.when(
            loading: () => skeletonBox(80),
            error: (_, __) => errorBox('Could not load workspace'),
            data: (ws) => Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: _editingInfo
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          settingsField(
                            label: 'BUSINESS NAME',
                            controller: _nameController,
                            hint: 'Your business name',
                          ),
                          const SizedBox(height: 12),
                          settingsField(
                            label: 'INDUSTRY',
                            controller: _industryController,
                            hint: 'e.g. Health & Fitness',
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _editingInfo = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgInteract,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.t3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _saving
                                      ? null
                                      : () => _saveInfo(ws?['id'] as String),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: _saving
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Save',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        tappableRow(
                          label: 'Business name',
                          value: ws?['name'] as String? ?? '—',
                          onTap: () {
                            _nameController.text = ws?['name'] as String? ?? '';
                            _industryController.text =
                                ws?['industry'] as String? ?? '';
                            setState(() => _editingInfo = true);
                          },
                        ),
                        Divider(height: 1, color: AppColors.border),
                        tappableRow(
                          label: 'Industry',
                          value: ws?['industry'] as String? ?? '—',
                          onTap: () {
                            _nameController.text = ws?['name'] as String? ?? '';
                            _industryController.text =
                                ws?['industry'] as String? ?? '';
                            setState(() => _editingInfo = true);
                          },
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 28),

          sectionLabel('Working Hours'),
          const SizedBox(height: 10),
          workspaceSettings.when(
            loading: () => skeletonBox(80),
            error: (_, __) => errorBox('Could not load working hours'),
            data: (settings) {
              final hours = Map<String, dynamic>.from(
                settings?['working_hours'] as Map? ?? {},
              );
              final openDays = hours.entries
                  .where((entry) {
                    final value = entry.value;
                    if (value is! Map) return false;
                    return Map<String, dynamic>.from(value)['enabled'] == true;
                  })
                  .map((entry) => entry.key.substring(0, 3))
                  .join(', ');
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: tappableRow(
                  label: 'Availability',
                  value: openDays.isEmpty ? 'Not set' : openDays,
                  onTap: () => _showHoursSheet(settings ?? {}),
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          sectionLabel('Public Profile'),
          const SizedBox(height: 10),
          workspace.when(
            loading: () => skeletonBox(140),
            error: (_, __) => errorBox('Could not load profile controls'),
            data: (ws) => profile.when(
              loading: () => skeletonBox(140),
              error: (_, __) => errorBox('Could not load public profile'),
              data: (bp) {
                _handleController.text = bp?.handle ?? '';
                _bioController.text = bp?.bio ?? '';
                _noticeController.text = bp?.noticeText ?? '';
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      settingsField(
                        label: 'HANDLE',
                        controller: _handleController,
                        hint: 'your-handle',
                      ),
                      const SizedBox(height: 12),
                      settingsField(
                        label: 'BIO',
                        controller: _bioController,
                        hint: 'A short public description',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      settingsField(
                        label: 'NOTICE',
                        controller: _noticeController,
                        hint: 'Optional seasonal notice',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Profile link: /p/${_handleController.text.isEmpty ? 'your-handle' : _handleController.text}',
                              style: const TextStyle(
                                color: AppColors.t3,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 112,
                            child: saveBtn(
                              label: 'Save',
                              loading: _saving,
                              onTap: () => _saveProfile(ws?['id'] as String),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),

          SettingsServicesSection(
            services: services,
            onAdd: _showAddServiceSheet,
            onEdit: _showEditServiceSheet,
          ),
        ],
      ),
    );
  }
}
