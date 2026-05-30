import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/repositories/slate_repositories.dart';
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
            const SizedBox(height: 20),

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

            // ── Avatar + info card ───────────────────────────────────────────
            if (!_editing) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.greenDim,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.green,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: _infoView(phone, email, address),
                    ),
                  ],
                ),
              ),

              // ── Call / Email buttons ─────────────────────────────────────────
              if (phone.isNotEmpty || email.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      if (phone.isNotEmpty)
                        Expanded(
                          child: _ActionButton(
                            icon: LucideIcons.phone,
                            label: 'Call',
                            onTap: () => _callPhone(phone),
                          ),
                        ),
                      if (phone.isNotEmpty && email.isNotEmpty)
                        const SizedBox(width: 10),
                      if (email.isNotEmpty)
                        Expanded(
                          child: _ActionButton(
                            icon: LucideIcons.mail,
                            label: 'Email',
                            onTap: () => _sendEmail(email),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

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
              const SizedBox(height: 12),

              // ── Tab content ──────────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ClientOverviewTab(
                      clientId: clientId,
                      clientName: name,
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

  // ── Info view (read mode) ─────────────────────────────────────────────────

  Widget _infoView(String phone, String email, String address) {
    final status = _client['status'] as String? ?? 'active';
    final notes = _client['notes'] as String? ?? '';
    final important = _client['important_notes'] as String? ?? '';
    final source = _client['source'] as String? ?? '';
    final preferred = _client['preferred_contact_method'] as String? ?? 'phone';
    final birthday = DateTime.tryParse(_client['birthday']?.toString() ?? '');
    final tags = ((_client['tags'] as List?) ?? const [])
        .map((tag) => tag.toString())
        .where((tag) => tag.trim().isNotEmpty)
        .toList();
    final statusColor = status == 'active'
        ? AppColors.green
        : status == 'lead'
        ? AppColors.warning
        : AppColors.t3;

    return Column(
      children: [
        if (phone.isNotEmpty) ...[
          _tappableRow(
            LucideIcons.phone,
            'Phone',
            phone,
            () => _callPhone(phone),
          ),
          Divider(height: 1, color: AppColors.border),
        ],
        if (email.isNotEmpty) ...[
          _tappableRow(
            LucideIcons.mail,
            'Email',
            email,
            () => _sendEmail(email),
          ),
          Divider(height: 1, color: AppColors.border),
        ],
        if (address.isNotEmpty) ...[
          _plainRow(LucideIcons.mapPin, 'Address', address),
          Divider(height: 1, color: AppColors.border),
        ],
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(LucideIcons.tag, color: AppColors.t3, size: 16),
              const SizedBox(width: 12),
              const Text(
                'Status',
                style: TextStyle(fontSize: 13, color: AppColors.t3),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.border),
        _plainRow(
          LucideIcons.messageCircle,
          'Preferred contact',
          _contactLabel(preferred),
        ),
        if (source.isNotEmpty) ...[
          Divider(height: 1, color: AppColors.border),
          _plainRow(LucideIcons.radio, 'Source', source),
        ],
        if (birthday != null) ...[
          Divider(height: 1, color: AppColors.border),
          _plainRow(
            LucideIcons.cake,
            'Birthday',
            '${birthday.day}/${birthday.month}/${birthday.year}',
          ),
        ],
        if (tags.isNotEmpty) ...[
          Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgInteract,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: AppColors.t3,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        if (important.isNotEmpty) ...[
          Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.alertCircle,
                  color: AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    important,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.error,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (notes.isNotEmpty) ...[
          Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.fileText, color: AppColors.t3, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    notes,
                    style: const TextStyle(fontSize: 13, color: AppColors.t2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _plainRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.t3, size: 16),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.t3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.t2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tappableRow(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.green, size: 16),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: AppColors.t3),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.green,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                LucideIcons.externalLink,
                color: AppColors.green,
                size: 12,
              ),
            ],
          ),
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
          _editField('Source', _sourceController),
          const SizedBox(height: 12),
          _editField('Tags', _tagsController),
          const SizedBox(height: 12),
          _dateEditor(),
          const SizedBox(height: 12),
          _contactMethodEditor(),
          const SizedBox(height: 12),
          _editField('Important', _importantNotesController, maxLines: 2),
          const SizedBox(height: 12),
          _editField('Notes', _notesController, maxLines: 3),
          const SizedBox(height: 16),
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

// ── Call / Email action button ────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.green, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.green,
                ),
              ),
            ],
          ),
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
