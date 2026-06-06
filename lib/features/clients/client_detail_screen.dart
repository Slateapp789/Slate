import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/widgets/slate_ui.dart';
import 'providers/client_detail_providers.dart';
import 'widgets/client_appointments_tab.dart';
import 'widgets/client_overview_tab.dart';
import 'widgets/client_payments_tab.dart';
import 'widgets/client_tasks_tab.dart';

export 'providers/client_detail_providers.dart';

class ClientDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> client;
  const ClientDetailScreen({super.key, required this.client});

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> _client;
  bool _editing = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _sourceController;
  late TextEditingController _tagsController;
  late TextEditingController _notesController;
  late TextEditingController _importantNotesController;
  String _status = 'active';
  String _preferredContactMethod = 'phone';
  DateTime? _birthday;
  bool _saving = false;
  bool _moreDetailsExpanded = false;

  @override
  void initState() {
    super.initState();
    _client = Map<String, dynamic>.from(widget.client);
    _tabController = TabController(length: 4, vsync: this);
    _nameController = TextEditingController(
      text: _client['name'] as String? ?? '',
    );
    _phoneController = TextEditingController(
      text: _client['phone'] as String? ?? '',
    );
    _emailController = TextEditingController(
      text: _client['email'] as String? ?? '',
    );
    _addressController = TextEditingController(
      text: _client['address'] as String? ?? '',
    );
    _sourceController = TextEditingController(
      text: _client['source'] as String? ?? '',
    );
    _tagsController = TextEditingController(
      text: ((_client['tags'] as List?) ?? const []).join(', '),
    );
    _notesController = TextEditingController(
      text: _client['notes'] as String? ?? '',
    );
    _importantNotesController = TextEditingController(
      text: _client['important_notes'] as String? ?? '',
    );
    _status = _client['status'] as String? ?? 'active';
    _preferredContactMethod =
        _client['preferred_contact_method'] as String? ?? 'phone';
    _birthday = DateTime.tryParse(_client['birthday']?.toString() ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  // ── Save / Delete ─────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(clientsRepositoryProvider)
          .update(_client['id'] as String, {
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            'email': _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            'address': _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            'notes': _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            'important_notes': _importantNotesController.text.trim().isEmpty
                ? null
                : _importantNotesController.text.trim(),
            'status': _status,
            'preferred_contact_method': _preferredContactMethod,
            'source': _sourceController.text.trim().isEmpty
                ? null
                : _sourceController.text.trim(),
            'birthday': _birthday?.toIso8601String().split('T').first,
            'tags': _tagsController.text
                .split(',')
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toList(),
          });
      setState(() {
        _client['name'] = _nameController.text.trim();
        _client['phone'] = _phoneController.text.trim();
        _client['email'] = _emailController.text.trim();
        _client['address'] = _addressController.text.trim();
        _client['source'] = _sourceController.text.trim();
        _client['tags'] = _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();
        _client['notes'] = _notesController.text.trim();
        _client['important_notes'] = _importantNotesController.text.trim();
        _client['status'] = _status;
        _client['preferred_contact_method'] = _preferredContactMethod;
        _client['birthday'] = _birthday?.toIso8601String().split('T').first;
        _editing = false;
        _saving = false;
      });
      ref.invalidate(clientsProvider);
      ref.invalidate(clientCrmRecordsProvider);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) _snack('Error: $e', AppColors.error);
    }
  }

  void _confirmDeleteClient() {
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
              _handle(),
              const SizedBox(height: 24),
              Text(
                'Delete ${_client['name']}?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.t1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'This will permanently remove the client and all linked data.',
                style: TextStyle(fontSize: 14, color: AppColors.t3),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _actionBtn(
                label: 'Delete Client',
                color: AppColors.error,
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(clientsRepositoryProvider)
                      .delete(_client['id'] as String);
                  ref.invalidate(clientsProvider);
                  if (mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
              _cancelBtn(ctx),
            ],
          ),
        ),
      ),
    );
  }

  // ── Contact actions ───────────────────────────────────────────────────────

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

  Future<void> _callPhone(String phone) async =>
      launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(' ', '')));

  Future<void> _sendEmail(String email) async =>
      launchUrl(Uri(scheme: 'mailto', path: email));

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final clientId = _client['id'] as String;
    final appointments = ref.watch(clientAppointmentsProvider(clientId));
    final tasks = ref.watch(clientTasksProvider(clientId));
    final payments = ref.watch(clientPaymentsProvider(clientId));
    final phone = _client['phone'] as String? ?? '';
    final email = _client['email'] as String? ?? '';
    final address = _client['address'] as String? ?? '';
    final name = _client['name'] as String? ?? '?';
    final initials = name
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.t1,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  if (_editing) ...[
                    GestureDetector(
                      onTap: _confirmDeleteClient,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.errorDim,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  GestureDetector(
                    onTap: () =>
                        _editing ? _save() : setState(() => _editing = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _editing ? AppColors.green : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _editing ? AppColors.green : AppColors.border,
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _editing ? 'Save' : 'Edit',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _editing ? Colors.white : AppColors.t2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            if (_editing)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _editForm(),
                  ),
                ),
              ),

            if (!_editing) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ClientCompactHeader(
                  initials: initials,
                  status: _client['status'] as String? ?? 'active',
                  preferredContact: _contactLabel(
                    _client['preferred_contact_method'] as String? ?? 'phone',
                  ),
                  phone: phone,
                  email: email,
                  address: address,
                  onCall: phone.isEmpty ? null : () => _callPhone(phone),
                  onEmail: email.isEmpty ? null : () => _sendEmail(email),
                ),
              ),
              const SizedBox(height: 8),

              // ── Tabs ─────────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.all(3),
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.t3,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: [
                      const Tab(text: 'Overview'),
                      Tab(
                        text: 'Bookings (${appointments.value?.length ?? 0})',
                      ),
                      Tab(text: 'Payments (${payments.value?.length ?? 0})'),
                      Tab(text: 'Tasks (${tasks.value?.length ?? 0})'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Tab content ──────────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ClientOverviewTab(
                      clientId: clientId,
                      clientName: name,
                      client: _client,
                      notes: _client['notes'] as String? ?? '',
                    ),
                    ClientAppointmentsTab(clientId: clientId),
                    ClientPaymentsTab(clientId: clientId, clientName: name),
                    ClientTasksTab(clientId: clientId, clientName: name),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Edit form ─────────────────────────────────────────────────────────────

  Widget _editForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _editField('Name', _nameController),
          const SizedBox(height: 12),
          _editField(
            'Phone',
            _phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _editField(
            'Email',
            _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _editField('Address', _addressController, maxLines: 2),
          const SizedBox(height: 12),
          _contactMethodEditor(),
          const SizedBox(height: 12),
          const Text(
            'Status',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.t3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: ['active', 'lead', 'inactive'].map((s) {
              final active = _status == s;
              return GestureDetector(
                onTap: () => setState(() => _status = s),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: active ? AppColors.green : AppColors.bgInteract,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active ? AppColors.green : AppColors.border,
                    ),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.t3,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SlateDisclosure(
            title: 'More client details',
            subtitle: 'Source, birthday, tags and notes',
            icon: LucideIcons.listPlus,
            expanded: _moreDetailsExpanded,
            onToggle: () =>
                setState(() => _moreDetailsExpanded = !_moreDetailsExpanded),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _editField('Source', _sourceController),
                const SizedBox(height: 12),
                _editField('Tags', _tagsController),
                const SizedBox(height: 12),
                _dateEditor(),
                const SizedBox(height: 12),
                _editField('Important', _importantNotesController, maxLines: 2),
                const SizedBox(height: 12),
                _editField('Notes', _notesController, maxLines: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactMethodEditor() {
    const options = {
      'phone': 'Phone',
      'sms': 'Text',
      'email': 'Email',
      'whatsapp': 'WhatsApp',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preferred contact',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.t3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map((entry) {
            final active = _preferredContactMethod == entry.key;
            return GestureDetector(
              onTap: () => setState(() => _preferredContactMethod = entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: active ? AppColors.green : AppColors.bgInteract,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: active ? AppColors.green : AppColors.border,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: active ? Colors.white : AppColors.t3,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _dateEditor() {
    return GestureDetector(
      onTap: _pickBirthday,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.bgInteract,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Text(
              'Birthday',
              style: TextStyle(color: AppColors.t3, fontSize: 13),
            ),
            const Spacer(),
            Text(
              _birthday == null
                  ? 'Add date'
                  : '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}',
              style: const TextStyle(
                color: AppColors.t2,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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

  Widget _editField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.t1, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.t3, fontSize: 13),
        filled: true,
        fillColor: AppColors.bgInteract,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}

class _ClientCompactHeader extends StatelessWidget {
  final String initials;
  final String status;
  final String preferredContact;
  final String phone;
  final String email;
  final String address;
  final VoidCallback? onCall;
  final VoidCallback? onEmail;

  const _ClientCompactHeader({
    required this.initials,
    required this.status,
    required this.preferredContact,
    required this.phone,
    required this.email,
    required this.address,
    required this.onCall,
    required this.onEmail,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = status == 'active'
        ? AppColors.green
        : status == 'lead'
        ? AppColors.warning
        : AppColors.t3;
    final detail = [
      if (phone.isNotEmpty) phone,
      if (email.isNotEmpty) email,
      if (address.isNotEmpty) address,
      if (phone.isEmpty && email.isEmpty && address.isEmpty)
        '$preferredContact preferred',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.greenDim,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(
                initials.isEmpty ? '?' : initials,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.green,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        preferredContact,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.t3,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.t2,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (onCall != null)
            _CompactContactButton(icon: LucideIcons.phone, onTap: onCall!),
          if (onEmail != null) ...[
            const SizedBox(width: 6),
            _CompactContactButton(icon: LucideIcons.mail, onTap: onEmail!),
          ],
        ],
      ),
    );
  }
}

class _CompactContactButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CompactContactButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.greenDim,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: AppColors.green, size: 17),
        ),
      ),
    );
  }
}

// ── Shared sheet helpers ──────────────────────────────────────────────────────
Widget _handle() => Center(
  child: Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: AppColors.border,
      borderRadius: BorderRadius.circular(2),
    ),
  ),
);

Widget _actionBtn({
  required String label,
  required VoidCallback onTap,
  Color color = AppColors.green,
}) => SizedBox(
  width: double.infinity,
  height: 52,
  child: ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
  ),
);

Widget _cancelBtn(BuildContext ctx) => SizedBox(
  width: double.infinity,
  height: 52,
  child: TextButton(
    onPressed: () => Navigator.pop(ctx),
    child: const Text(
      'Cancel',
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.t3,
      ),
    ),
  ),
);

String _contactLabel(String value) {
  return switch (value) {
    'sms' => 'Text message',
    'email' => 'Email',
    'whatsapp' => 'WhatsApp',
    _ => 'Phone',
  };
}
