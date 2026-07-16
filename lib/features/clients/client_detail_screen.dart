import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/widgets/slate_ui.dart';
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
    _tabController.addListener(_handleTabChanged);
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
    _tabController.removeListener(_handleTabChanged);
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

  void _handleTabChanged() {
    if (mounted) setState(() {});
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

  Future<void> _sendText(String phone) async =>
      launchUrl(Uri(scheme: 'sms', path: phone.replaceAll(' ', '')));

  Future<void> _openWhatsApp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    await launchUrl(
      Uri.parse('https://wa.me/$digits'),
      mode: LaunchMode.externalApplication,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final clientId = _client['id'] as String;
    final phone = _client['phone'] as String? ?? '';
    final email = _client['email'] as String? ?? '';
    final preferredMethod =
        _client['preferred_contact_method'] as String? ?? 'phone';
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      WorkloopIconButton(
                        icon: LucideIcons.chevronLeft,
                        semanticLabel: 'Back to clients',
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 26,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            color: AppColors.t1,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _HeaderAction(
                        label: _editing ? 'Save' : 'Edit',
                        primary: _editing,
                        loading: _saving,
                        onTap: _saving
                            ? null
                            : () => _editing
                                  ? _save()
                                  : setState(() => _editing = true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_editing)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageX,
                        0,
                        AppSpacing.pageX,
                        AppSpacing.xxl,
                      ),
                      child: _editForm(),
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageX,
                    ),
                    child: _ClientCompactHeader(
                      initials: initials,
                      status: _client['status'] as String? ?? 'active',
                      preferredContact: _contactLabel(preferredMethod),
                      onCall: phone.isEmpty ? null : () => _callPhone(phone),
                      preferredIcon: _preferredContactIcon(preferredMethod),
                      onPreferred: switch (preferredMethod) {
                        'email' =>
                          email.isEmpty ? null : () => _sendEmail(email),
                        'sms' => phone.isEmpty ? null : () => _sendText(phone),
                        'whatsapp' =>
                          phone.isEmpty ? null : () => _openWhatsApp(phone),
                        _ => phone.isEmpty ? null : () => _callPhone(phone),
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageX,
                    ),
                    child: _ClientWorkspaceNavigation(
                      index: _tabController.index,
                      onChanged: _tabController.animateTo,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ClientOverviewTab(
                          clientId: clientId,
                          client: _client,
                          onEdit: () => setState(() => _editing = true),
                          onOpenBookings: () => _tabController.animateTo(1),
                          onOpenPayments: () => _tabController.animateTo(2),
                          onOpenTasks: () => _tabController.animateTo(3),
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
        ],
      ),
    );
  }

  // ── Edit form ─────────────────────────────────────────────────────────────

  Widget _editForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _editSectionTitle('Basic details'),
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
        const SizedBox(height: 24),
        _editSectionTitle('Work details'),
        _editField('Address', _addressController, maxLines: 2),
        const SizedBox(height: 12),
        _contactMethodEditor(),
        const SizedBox(height: 12),
        _statusEditor(),
        const SizedBox(height: 12),
        SlateDisclosure(
          title: 'More client details',
          subtitle: 'Source, birthday and tags',
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
            ],
          ),
        ),
        const SizedBox(height: 24),
        _editSectionTitle('Notes'),
        _editField('Notes', _notesController, maxLines: 4),
        const SizedBox(height: 12),
        _editField('Important notes', _importantNotesController, maxLines: 2),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: TextButton(
            onPressed: _confirmDeleteClient,
            child: const Text(
              'Delete client',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _editSectionTitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.t1,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _statusEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  color: active
                      ? AppColors.accentPrimaryStrong.withValues(alpha: 0.32)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: active
                        ? AppColors.accentPrimaryStrong.withValues(alpha: 0.64)
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  s,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: active ? AppColors.t1 : AppColors.t3,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
  final VoidCallback? onCall;
  final IconData preferredIcon;
  final VoidCallback? onPreferred;

  const _ClientCompactHeader({
    required this.initials,
    required this.status,
    required this.preferredContact,
    required this.onCall,
    required this.preferredIcon,
    required this.onPreferred,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = status == 'active'
        ? AppColors.modClients
        : status == 'lead'
        ? AppColors.warning
        : AppColors.t3;
    return SlateGlassSurface(
      blur: 18,
      color: AppColors.bgCard.withValues(alpha: 0.72),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.modClients.withValues(alpha: 0.09),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials.isEmpty ? '?' : initials,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.modClients,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Prefers $preferredContact',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.t2,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _CompactContactButton(
                  icon: LucideIcons.phone,
                  label: 'Call',
                  onTap: onCall,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _CompactContactButton(
                  icon: preferredIcon,
                  label: preferredContact,
                  onTap: onPreferred,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _CompactContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null
          ? AppColors.bgInteract.withValues(alpha: 0.55)
          : AppColors.modClients.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: SizedBox(
          height: AppSpacing.minTouch,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: onTap == null ? AppColors.t4 : AppColors.modClients,
                size: 17,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onTap == null ? AppColors.t4 : AppColors.modClients,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final String label;
  final bool primary;
  final bool loading;
  final VoidCallback? onTap;

  const _HeaderAction({
    required this.label,
    required this.primary,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary
          ? AppColors.accentPrimary.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 58, minHeight: 42),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: AppColors.accentPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: primary ? AppColors.accentPrimary : AppColors.t2,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ClientWorkspaceNavigation extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _ClientWorkspaceNavigation({
    required this.index,
    required this.onChanged,
  });

  static const _labels = ['Overview', 'Bookings', 'Money', 'Tasks'];

  @override
  Widget build(BuildContext context) {
    return SlateGlassSurface(
      blur: 22,
      color: AppColors.bgCard.withValues(alpha: 0.90),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: SizedBox(
        height: 54,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / _labels.length;

            void select(int next) {
              if (next == index) return;
              SlateHaptics.tap();
              onChanged(next);
            }

            void handleDrag(double dx) {
              select((dx / itemWidth).floor().clamp(0, _labels.length - 1));
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (details) {
                handleDrag(details.localPosition.dx);
              },
              onHorizontalDragUpdate: (details) {
                handleDrag(details.localPosition.dx);
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedPositioned(
                    duration: AppMotion.deliberate,
                    curve: AppMotion.emphasized,
                    left: index * itemWidth,
                    top: 6,
                    width: itemWidth,
                    height: 42,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.accentPrimary.withValues(
                            alpha: 0.14,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.accentPrimary.withValues(
                              alpha: 0.22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(
                      _labels.length,
                      (tabIndex) => Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => select(tabIndex),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: AppMotion.standard,
                              style: TextStyle(
                                color: tabIndex == index
                                    ? AppColors.accentPrimary
                                    : AppColors.t3,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              child: Text(_labels[tabIndex]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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

IconData _preferredContactIcon(String value) {
  return switch (value) {
    'sms' => LucideIcons.messageSquare,
    'email' => LucideIcons.mail,
    'whatsapp' => LucideIcons.messageCircle,
    _ => LucideIcons.phone,
  };
}

String _statusLabel(String value) {
  return switch (value) {
    'lead' => 'LEAD',
    'inactive' => 'INACTIVE',
    _ => 'ACTIVE',
  };
}
