import 'package:flutter/material.dart';
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
            letterSpacing: 1.2,
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
