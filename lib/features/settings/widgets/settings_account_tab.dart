import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/workspace_provider.dart';
import '../../../shared/repositories/slate_repositories.dart';
import 'settings_helpers.dart';

class SettingsAccountTab extends ConsumerStatefulWidget {
  const SettingsAccountTab({super.key});

  @override
  ConsumerState<SettingsAccountTab> createState() => _SettingsAccountTabState();
}

class _SettingsAccountTabState extends ConsumerState<SettingsAccountTab> {
  bool _changingPassword = false;
  bool _savingPassword = false;
  bool _exporting = false;
  bool _requestingDeletion = false;
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
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

  Future<void> _changePassword() async {
    final newPass = _newPasswordCtrl.text.trim();
    final confirm = _confirmPasswordCtrl.text.trim();
    if (newPass.isEmpty) return;
    if (newPass != confirm) {
      _snack("Passwords don't match", AppColors.error);
      return;
    }
    if (newPass.length < 6) {
      _snack('Password must be at least 6 characters', AppColors.error);
      return;
    }
    setState(() => _savingPassword = true);
    try {
      await ref.read(authRepositoryProvider).updatePassword(newPass);
      setState(() {
        _changingPassword = false;
        _savingPassword = false;
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
      });
      if (mounted) _snack('Password updated', AppColors.green);
    } catch (e) {
      setState(() => _savingPassword = false);
      if (mounted) _snack('Error: $e', AppColors.error);
    }
  }

  void _showSignOutSheet() {
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
              const Text(
                'Sign out?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.t1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You can sign back in at any time.',
                style: TextStyle(fontSize: 14, color: AppColors.t3),
              ),
              const SizedBox(height: 24),
              saveBtn(
                label: 'Sign out',
                color: AppColors.error,
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(authRepositoryProvider).signOut();
                  ref.invalidate(workspaceProvider);
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

  Future<void> _exportData() async {
    setState(() => _exporting = true);
    try {
      final workspaceId = await ref.read(workspaceIdProvider.future);
      if (workspaceId == null) return;
      final json = await ref
          .read(privacyRepositoryProvider)
          .exportWorkspaceData(workspaceId);
      if (!mounted) return;
      setState(() => _exporting = false);
      _showExportSheet(json);
    } catch (e) {
      setState(() => _exporting = false);
      if (mounted) _snack('Could not export data: $e', AppColors.error);
    }
  }

  void _showExportSheet(String json) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              settingsHandle(),
              const SizedBox(height: 20),
              const Text(
                'Workspace export',
                style: TextStyle(
                  color: AppColors.t1,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'This includes the workspace data Slate currently stores for your account.',
                style: TextStyle(color: AppColors.t3, height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.42,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgInteract,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    json,
                    style: const TextStyle(
                      color: AppColors.t2,
                      fontSize: 11,
                      height: 1.35,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              saveBtn(
                label: 'Copy export',
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: json));
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) _snack('Export copied', AppColors.green);
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

  void _showDeleteAccountSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                settingsHandle(),
                const SizedBox(height: 22),
                const Icon(
                  LucideIcons.shieldAlert,
                  color: AppColors.warning,
                  size: 28,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Request account deletion',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.t1,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This creates an auditable deletion request. A trusted backend process should then remove auth, storage, and workspace rows together.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.t3, height: 1.4),
                ),
                const SizedBox(height: 22),
                saveBtn(
                  label: 'Request deletion',
                  color: AppColors.warning,
                  loading: _requestingDeletion,
                  onTap: () async {
                    setSheetState(() => _requestingDeletion = true);
                    setState(() => _requestingDeletion = true);
                    try {
                      final workspaceId = await ref.read(
                        workspaceIdProvider.future,
                      );
                      if (workspaceId == null) return;
                      await ref
                          .read(privacyRepositoryProvider)
                          .requestAccountDeletion(
                            workspaceId: workspaceId,
                            email: ref
                                .read(authRepositoryProvider)
                                .currentEmail,
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        _snack('Deletion request created', AppColors.green);
                      }
                    } catch (e) {
                      if (mounted) {
                        _snack(
                          'Could not create deletion request: $e',
                          AppColors.error,
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _requestingDeletion = false);
                      }
                    }
                  },
                ),
                const SizedBox(height: 10),
                cancelBtn(ctx),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authRepositoryProvider).currentEmail;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        // ── Profile ────────────────────────────────────────────────────
        sectionLabel('Profile'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: infoRow('Email', email),
        ),
        const SizedBox(height: 28),

        // ── Password ───────────────────────────────────────────────────
        sectionLabel('Password'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: _changingPassword
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _passwordField(
                        label: 'NEW PASSWORD',
                        controller: _newPasswordCtrl,
                        obscure: _obscureNew,
                        onToggle: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                      const SizedBox(height: 12),
                      _passwordField(
                        label: 'CONFIRM PASSWORD',
                        controller: _confirmPasswordCtrl,
                        obscure: _obscureConfirm,
                        onToggle: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _changingPassword = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.bgInteract,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
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
                              onTap: _savingPassword ? null : _changePassword,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: _savingPassword
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Update',
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
              : tappableRow(
                  label: 'Change password',
                  value: '••••••••',
                  onTap: () => setState(() => _changingPassword = true),
                  valueColor: AppColors.t3,
                ),
        ),
        const SizedBox(height: 28),

        // ── Security & Data ─────────────────────────────────────────────
        sectionLabel('Security & Data'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              tappableRow(
                label: 'Export workspace data',
                value: _exporting ? 'Preparing...' : 'JSON',
                onTap: _exporting ? () {} : _exportData,
                valueColor: AppColors.green,
              ),
              Divider(height: 1, color: AppColors.border),
              tappableRow(
                label: 'Delete account',
                value: 'Request',
                onTap: _showDeleteAccountSheet,
                valueColor: AppColors.warning,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── Session ────────────────────────────────────────────────────
        sectionLabel('Session'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showSignOutSheet,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.logOut,
                      color: AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Sign out',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      LucideIcons.chevronRight,
                      color: AppColors.t3,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
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
          obscureText: obscure,
          style: const TextStyle(color: AppColors.t1, fontSize: 14),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: AppColors.t3),
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
            suffixIcon: GestureDetector(
              onTap: onToggle,
              child: Icon(
                obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                color: AppColors.t3,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
