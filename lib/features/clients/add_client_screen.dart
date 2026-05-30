import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/widgets/slate_ui.dart';

class AddClientScreen extends ConsumerStatefulWidget {
  const AddClientScreen({super.key});

  @override
  ConsumerState<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends ConsumerState<AddClientScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _sourceController = TextEditingController();
  final _tagsController = TextEditingController();
  final _notesController = TextEditingController();
  final _importantNotesController = TextEditingController();
  String _status = 'active';
  String _preferredContactMethod = 'phone';
  DateTime? _birthday;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _sourceController.dispose();
    _tagsController.dispose();
    _notesController.dispose();
    _importantNotesController.dispose();
    super.dispose();
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_canSave) return;
    final workspaceId = await ref.read(workspaceIdProvider.future);
    if (workspaceId == null) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(clientsRepositoryProvider)
          .create(
            workspaceId: workspaceId,
            name: _nameController.text,
            phone: _phoneController.text,
            email: _emailController.text,
            address: _addressController.text,
            notes: _notesController.text,
            importantNotes: _importantNotesController.text,
            status: _status,
            preferredContactMethod: _preferredContactMethod,
            source: _sourceController.text,
            birthday: _birthday,
            tags: _tagsController.text
                .split(',')
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toList(),
          );
      ref.invalidate(clientsProvider);
      ref.invalidate(clientCrmRecordsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nameController.text.trim()} added'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        LucideIcons.chevronLeft,
                        color: AppColors.t2,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'New client',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.t1,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 132),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Core details'),
                    _field(
                      label: 'NAME',
                      controller: _nameController,
                      hint: 'Full name',
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _statusRow(),
                    const SizedBox(height: 20),
                    _sectionTitle('Contact'),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            label: 'PHONE',
                            controller: _phoneController,
                            hint: 'Mobile number',
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            label: 'EMAIL',
                            controller: _emailController,
                            hint: 'Email address',
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _field(
                      label: 'ADDRESS',
                      controller: _addressController,
                      hint: 'Client or usual service address',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    _choiceRow(
                      label: 'PREFERRED CONTACT',
                      value: _preferredContactMethod,
                      options: const {
                        'phone': 'Phone',
                        'sms': 'Text',
                        'email': 'Email',
                        'whatsapp': 'WhatsApp',
                      },
                      onChanged: (value) =>
                          setState(() => _preferredContactMethod = value),
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle('CRM context'),
                    _field(
                      label: 'SOURCE',
                      controller: _sourceController,
                      hint: 'Instagram, referral, walk-in, website...',
                    ),
                    const SizedBox(height: 12),
                    _dateTile(),
                    const SizedBox(height: 12),
                    _field(
                      label: 'TAGS',
                      controller: _tagsController,
                      hint: 'VIP, monthly, mobile, colour',
                    ),
                    const SizedBox(height: 12),
                    _field(
                      label: 'NOTES',
                      controller: _notesController,
                      hint: 'Preferences, booking context, useful details...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      label: 'IMPORTANT',
                      controller: _importantNotesController,
                      hint: 'Allergies, access notes, must-know details...',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _canSave && !_saving ? _save : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          disabledBackgroundColor: AppColors.bgInteract,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Add Client',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.t3,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool autofocus = false,
    void Function(String)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: AppColors.t3,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            autofocus: autofocus,
            onChanged: onChanged,
            style: const TextStyle(color: AppColors.t1, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.t3, fontSize: 14),
              border: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATUS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: AppColors.t3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statusChip('active', 'Active', AppColors.green),
              const SizedBox(width: 8),
              _statusChip('lead', 'Lead', AppColors.warning),
              const SizedBox(width: 8),
              _statusChip('inactive', 'Inactive', AppColors.t3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String value, String label, Color color) {
    final active = _status == value;
    return GestureDetector(
      onTap: () => setState(() => _status = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : AppColors.bgInteract,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? color : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? color : AppColors.t3,
          ),
        ),
      ),
    );
  }

  Widget _choiceRow({
    required String label,
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    return SlateSurface(
      color: AppColors.bgCard,
      borderColor: AppColors.border,
      radius: AppRadius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: AppColors.t3,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.entries.map((entry) {
              final active = value == entry.key;
              return GestureDetector(
                onTap: () => onChanged(entry.key),
                child: AnimatedContainer(
                  duration: AppMotion.standard,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.green.withValues(alpha: 0.14)
                        : AppColors.bgInteract,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: active ? AppColors.green : AppColors.border,
                    ),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: active ? AppColors.green : AppColors.t3,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _dateTile() {
    return SlateSurface(
      onTap: _pickBirthday,
      color: AppColors.bgCard,
      borderColor: AppColors.border,
      radius: AppRadius.md,
      child: Row(
        children: [
          const Icon(LucideIcons.cake, color: AppColors.t3, size: 18),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Birthday',
              style: TextStyle(
                color: AppColors.t1,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            _birthday == null
                ? 'Add date'
                : '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}',
            style: const TextStyle(
              color: AppColors.t3,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthday = picked);
  }
}
