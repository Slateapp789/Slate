import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/slate_models.dart';
import '../../../shared/repositories/services_repository.dart';
import '../../../shared/utils/currency_format.dart';
import '../../../shared/utils/duration_format.dart';
import '../../../shared/widgets/slate_ui.dart';
import 'settings_helpers.dart';

class ServiceAddOnsEditor extends ConsumerStatefulWidget {
  final String workspaceId;
  final String serviceId;

  const ServiceAddOnsEditor({
    super.key,
    required this.workspaceId,
    required this.serviceId,
  });

  @override
  ConsumerState<ServiceAddOnsEditor> createState() =>
      _ServiceAddOnsEditorState();
}

class _ServiceAddOnsEditorState extends ConsumerState<ServiceAddOnsEditor> {
  late Future<List<ServiceAddOn>> _addOns;

  @override
  void initState() {
    super.initState();
    _addOns = _load();
  }

  Future<List<ServiceAddOn>> _load() => ref
      .read(servicesRepositoryProvider)
      .listAddOns(workspaceId: widget.workspaceId, serviceId: widget.serviceId);

  void _refresh() => setState(() => _addOns = _load());

  Future<void> _showEditor(
    List<ServiceAddOn> current, [
    ServiceAddOn? existing,
  ]) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final priceController = TextEditingController(
      text: existing == null ? '' : currencyInputValue(existing.price),
    );
    final duration = existing?.durationMins ?? 0;
    final hoursController = TextEditingController(text: '${duration ~/ 60}');
    final minutesController = TextEditingController(
      text: '${duration.remainder(60)}',
    );
    var active = existing?.active ?? true;
    var saving = false;
    String? error;

    await showWorkloopBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModal) => AnimatedPadding(
          duration: AppMotion.responsive(context, AppMotion.fast),
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SlateSheetFrame(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          existing == null ? 'New add-on' : 'Edit add-on',
                          style: const TextStyle(
                            color: AppColors.t1,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (existing != null)
                        WorkloopTextButton(
                          label: 'Delete',
                          destructive: true,
                          onPressed: saving
                              ? null
                              : () async {
                                  final confirmed = await _confirmDelete(
                                    existing,
                                  );
                                  if (!confirmed || !sheetContext.mounted) {
                                    return;
                                  }
                                  Navigator.pop(sheetContext);
                                },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  settingsField(
                    label: 'ADD-ON NAME',
                    controller: nameController,
                    hint: 'e.g. Interior windows',
                    autofocus: existing == null,
                  ),
                  const SizedBox(height: 12),
                  settingsField(
                    label: 'DESCRIPTION',
                    controller: descriptionController,
                    hint: 'Optional customer-facing detail',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  settingsField(
                    label: 'EXTRA PRICE (£)',
                    controller: priceController,
                    hint: '0',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: settingsField(
                          label: 'EXTRA HOURS',
                          controller: hoursController,
                          hint: '0',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: settingsField(
                          label: 'MINUTES',
                          controller: minutesController,
                          hint: '0',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: active,
                    title: const Text(
                      'Available to customers',
                      style: TextStyle(
                        color: AppColors.t1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Turn this off without removing it from saved history.',
                      style: TextStyle(color: AppColors.t3, fontSize: 12),
                    ),
                    onChanged: (value) => setModal(() => active = value),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  saveBtn(
                    label: existing == null
                        ? 'Add optional extra'
                        : 'Save changes',
                    loading: saving,
                    onTap: () async {
                      if (saving) return;
                      final name = nameController.text.trim();
                      final hours = int.tryParse(hoursController.text.trim());
                      final minutes = int.tryParse(
                        minutesController.text.trim(),
                      );
                      final price = double.tryParse(
                        priceController.text.trim(),
                      );
                      if (name.isEmpty) {
                        setModal(
                          () => error = 'Add a name for this optional extra.',
                        );
                        return;
                      }
                      if (hours == null ||
                          minutes == null ||
                          hours < 0 ||
                          minutes < 0 ||
                          minutes > 59 ||
                          (hours * 60) + minutes > 1440) {
                        setModal(
                          () => error =
                              'Use an extra duration from 0 minutes to 24 hours.',
                        );
                        return;
                      }
                      if (price == null || price < 0 || price > 1000000) {
                        setModal(() => error = 'Enter a valid extra price.');
                        return;
                      }
                      setModal(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        final repository = ref.read(servicesRepositoryProvider);
                        if (existing == null) {
                          await repository.createAddOn(
                            workspaceId: widget.workspaceId,
                            serviceId: widget.serviceId,
                            name: name,
                            description: descriptionController.text,
                            durationMins: (hours * 60) + minutes,
                            price: price,
                            active: active,
                            position: current.length,
                          );
                        } else {
                          await repository.updateAddOn(
                            workspaceId: widget.workspaceId,
                            serviceId: widget.serviceId,
                            addOnId: existing.id,
                            name: name,
                            description: descriptionController.text,
                            durationMins: (hours * 60) + minutes,
                            price: price,
                            active: active,
                            position: existing.position,
                          );
                        }
                        if (!sheetContext.mounted) return;
                        Navigator.pop(sheetContext);
                        _refresh();
                      } catch (_) {
                        if (!sheetContext.mounted) return;
                        setModal(() {
                          saving = false;
                          error =
                              'Couldn’t save this optional extra. Nothing was changed.';
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    hoursController.dispose();
    minutesController.dispose();
  }

  Future<bool> _confirmDelete(ServiceAddOn addOn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Delete optional extra?'),
        content: Text(
          '“${addOn.name}” will no longer be offered. Existing requests and bookings keep their saved details.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    try {
      await ref
          .read(servicesRepositoryProvider)
          .deleteAddOn(
            workspaceId: widget.workspaceId,
            serviceId: widget.serviceId,
            addOnId: addOn.id,
          );
      if (mounted) _refresh();
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The optional extra could not be deleted.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ServiceAddOn>>(
      future: _addOns,
      builder: (context, snapshot) {
        final addOns = snapshot.data ?? const <ServiceAddOn>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Optional add-ons',
                    style: TextStyle(
                      color: AppColors.t1,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                WorkloopTextButton(
                  label: addOns.length >= 8 ? 'Limit reached' : 'Add',
                  onPressed:
                      snapshot.connectionState == ConnectionState.waiting ||
                          addOns.length >= 8
                      ? null
                      : () => _showEditor(addOns),
                ),
              ],
            ),
            const Text(
              'Offer up to 8 simple extras for this service. Packages stay as their own service.',
              style: TextStyle(color: AppColors.t3, fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: 10),
            if (snapshot.connectionState == ConnectionState.waiting)
              const SlateLoadingBlock(height: 54, radius: AppRadius.md)
            else if (snapshot.hasError)
              SlateErrorState(
                message: 'Optional extras could not be loaded.',
                onRetry: _refresh,
              )
            else if (addOns.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No optional extras for this service.',
                  style: TextStyle(color: AppColors.t3, fontSize: 13),
                ),
              )
            else
              ...addOns.map(
                (addOn) => SlateListRow(
                  onTap: () => _showEditor(addOns, addOn),
                  showDivider: addOn.id != addOns.last.id,
                  title: Text(
                    addOn.name,
                    style: TextStyle(
                      color: addOn.active ? AppColors.t1 : AppColors.t3,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    [
                      if (addOn.durationMins > 0)
                        '+${formatFriendlyDuration(addOn.durationMins)}',
                      if (addOn.price > 0) '+${formatPounds(addOn.price)}',
                      if (!addOn.active) 'Hidden',
                    ].join(' · '),
                    style: const TextStyle(color: AppColors.t3, fontSize: 12),
                  ),
                  trailing: const Icon(
                    LucideIcons.pencil,
                    color: AppColors.t3,
                    size: 14,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
