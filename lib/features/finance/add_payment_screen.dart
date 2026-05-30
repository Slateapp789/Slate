import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/providers/dashboard_provider.dart';
import '../../shared/providers/finance_provider.dart';
import '../../shared/providers/notifications_provider.dart';
import '../../shared/repositories/slate_repositories.dart';

class AddPaymentScreen extends ConsumerStatefulWidget {
  final String? initialClientId;
  const AddPaymentScreen({super.key, this.initialClientId});

  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedClientId;
  String _status = 'paid';
  DateTime _date = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.initialClientId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _amountController.text.trim().isNotEmpty &&
      double.tryParse(_amountController.text.trim()) != null;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      final workspaceId = await ref.read(workspaceIdProvider.future);
      if (workspaceId == null) return;

      final amount = double.parse(_amountController.text.trim());
      final description = _descriptionController.text.trim();

      await ref
          .read(paymentsRepositoryProvider)
          .create(
            workspaceId: workspaceId,
            amount: amount,
            status: _status,
            date: _date,
            dueDate: _status == 'paid' ? _date : _dueDate,
            contactId: _selectedClientId,
            notes: description,
          );
      await ref
          .read(notificationsRepositoryProvider)
          .create(
            workspaceId: workspaceId,
            type: _status == 'paid' ? 'payment_received' : 'invoice_overdue',
            title: _status == 'paid' ? 'Payment recorded' : 'Payment pending',
            body:
                '£${amount.toStringAsFixed(0)} ${_status == 'paid' ? 'was recorded' : 'needs follow-up'}.',
            deepLink: '/payments',
          );

      ref.invalidate(invoicesProvider);
      ref.invalidate(dashboardRevenueProvider);
      ref.invalidate(clientCrmRecordsProvider);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationsProvider);
      if (mounted) Navigator.pop(context);
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.green,
            surface: AppColors.bgCard,
            onSurface: AppColors.t1,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.green,
            surface: AppColors.bgCard,
            onSurface: AppColors.t1,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
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
                      'Record Payment',
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
              const SizedBox(height: 32),

              // Amount — big and prominent
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.panelSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.panelSoftRaised),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AMOUNT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        color: AppColors.panelMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          '£',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: AppColors.panelMuted,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: AppColors.panelInk,
                              letterSpacing: 0,
                            ),
                            decoration: const InputDecoration(
                              hintText: '0',
                              hintStyle: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: AppColors.panelMuted,
                              ),
                              border: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Status toggle
              Container(
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
                        _statusChip('paid', 'Received', AppColors.green),
                        const SizedBox(width: 8),
                        _statusChip('sent', 'Pending', AppColors.warning),
                        const SizedBox(width: 8),
                        _statusChip('overdue', 'Overdue', AppColors.error),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Client
              Container(
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
                      'CLIENT (OPTIONAL)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        color: AppColors.t3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    clients.when(
                      data: (data) => DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedClientId,
                          isExpanded: true,
                          dropdownColor: AppColors.bgRaised,
                          icon: const Icon(
                            LucideIcons.chevronDown,
                            color: AppColors.t3,
                            size: 16,
                          ),
                          hint: const Text(
                            'Select a client',
                            style: TextStyle(color: AppColors.t3, fontSize: 14),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text(
                                'No client',
                                style: TextStyle(
                                  color: AppColors.t3,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            ...data.map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  c.name,
                                  style: const TextStyle(
                                    color: AppColors.t1,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedClientId = v),
                        ),
                      ),
                      loading: () => const CircularProgressIndicator(
                        color: AppColors.green,
                      ),
                      error: (_, __) => const Text(
                        'Error loading clients',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Container(
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
                      'DESCRIPTION (OPTIONAL)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        color: AppColors.t3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 2,
                      style: const TextStyle(color: AppColors.t1, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'e.g. PT session, weekly package...',
                        hintStyle: TextStyle(color: AppColors.t3),
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Date
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.calendar,
                        color: AppColors.t3,
                        size: 16,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'DATE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                          color: AppColors.t3,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(_date),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.green,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        LucideIcons.chevronRight,
                        color: AppColors.t3,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
              if (_status != 'paid') ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickDueDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.alarmClock,
                          color: AppColors.t3,
                          size: 16,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'DUE DATE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                            color: AppColors.t3,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(_dueDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          LucideIcons.chevronRight,
                          color: AppColors.t3,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Save button
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
                          'Save Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String value, String label, Color color) {
    final active = _status == value;
    return GestureDetector(
      onTap: () => setState(() => _status = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
}
