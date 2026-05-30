import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/providers/appointments_provider.dart';
import '../../shared/providers/calendar_sync_provider.dart';
import '../../shared/providers/dashboard_provider.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/providers/workspace_settings_provider.dart';
import '../../shared/repositories/slate_repositories.dart';
import '../../shared/utils/calendar_export.dart';

class CalendarSyncScreen extends ConsumerWidget {
  const CalendarSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(calendarSyncProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
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
                const SizedBox(width: 14),
                const Text(
                  'Calendar sync',
                  style: TextStyle(
                    color: AppColors.t1,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            sync.when(
              loading: () => const _SyncLoadingCard(),
              error: (_, __) => const _SyncInfoCard(
                enabled: false,
                provider: null,
                lastSyncedAt: null,
              ),
              data: (state) => _SyncInfoCard(
                enabled: state.enabled,
                provider: state.account?['provider'] as String?,
                lastSyncedAt: DateTime.tryParse(
                  state.account?['last_synced_at']?.toString() ?? '',
                )?.toLocal(),
              ),
            ),
            const SizedBox(height: 16),
            sync.when(
              data: (state) => state.enabled
                  ? _ConnectedActions(
                      onExport: () => _copyIcsFeed(context, ref),
                      onDisconnect: () => _disconnect(ref),
                    )
                  : _ProviderActions(
                      onConnect: (provider) {
                        _connect(ref, provider);
                      },
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => _ProviderActions(
                onConnect: (provider) {
                  _connect(ref, provider);
                },
              ),
            ),
            const SizedBox(height: 22),
            const _SyncRow(
              icon: LucideIcons.repeat,
              label: 'Two-way sync',
              value: 'Ready for provider OAuth',
            ),
            const _SyncRow(
              icon: LucideIcons.alertTriangle,
              label: 'Conflict detection',
              value: 'Active in booking form',
            ),
            const _SyncRow(
              icon: LucideIcons.calendarRange,
              label: 'Imported busy blocks',
              value: 'Next integration step',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connect(WidgetRef ref, String provider) async {
    final workspaceId = await ref.read(workspaceIdProvider.future);
    if (workspaceId == null) return;
    await ref
        .read(calendarSyncRepositoryProvider)
        .connect(workspaceId: workspaceId, provider: provider);
    ref.invalidate(calendarSyncProvider);
    ref.invalidate(workspaceSettingsProvider);
    ref.invalidate(dashboardFocusProvider);
  }

  Future<void> _disconnect(WidgetRef ref) async {
    final workspaceId = await ref.read(workspaceIdProvider.future);
    if (workspaceId == null) return;
    await ref.read(calendarSyncRepositoryProvider).disconnect(workspaceId);
    ref.invalidate(calendarSyncProvider);
    ref.invalidate(workspaceSettingsProvider);
    ref.invalidate(dashboardFocusProvider);
  }

  Future<void> _copyIcsFeed(BuildContext context, WidgetRef ref) async {
    final rows = await ref.read(appointmentsProvider.future);
    final ics = buildSlateIcs(rows);
    await Clipboard.setData(ClipboardData(text: ics));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calendar feed copied'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SyncInfoCard extends StatelessWidget {
  final bool enabled;
  final String? provider;
  final DateTime? lastSyncedAt;

  const _SyncInfoCard({
    required this.enabled,
    required this.provider,
    required this.lastSyncedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: enabled
              ? AppColors.green.withValues(alpha: 0.32)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            enabled ? LucideIcons.calendarCheck : LucideIcons.calendarClock,
            color: enabled ? AppColors.green : AppColors.t3,
            size: 28,
          ),
          const SizedBox(height: 16),
          Text(
            enabled ? 'Calendar connected' : 'Connect your calendar',
            style: const TextStyle(
              color: AppColors.t1,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            enabled
                ? '${provider ?? 'Calendar'} sync is enabled. Slate can now warn about conflicts while provider OAuth is completed.'
                : 'Keep sync contained here: provider account, sync status, conflict checks and disconnect controls.',
            style: const TextStyle(
              color: AppColors.t3,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (lastSyncedAt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Last synced ${_formatDateTime(lastSyncedAt!)}',
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SyncLoadingCard extends StatelessWidget {
  const _SyncLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 178,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      ),
    );
  }
}

class _ProviderActions extends StatelessWidget {
  final ValueChanged<String> onConnect;
  const _ProviderActions({required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ProviderButton(
            icon: LucideIcons.mail,
            label: 'Google',
            onTap: () => onConnect('google'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ProviderButton(
            icon: LucideIcons.apple,
            label: 'Apple',
            onTap: () => onConnect('apple'),
          ),
        ),
      ],
    );
  }
}

class _ConnectedActions extends StatelessWidget {
  final VoidCallback onExport;
  final VoidCallback onDisconnect;
  const _ConnectedActions({required this.onExport, required this.onDisconnect});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onExport,
            icon: const Icon(LucideIcons.download, size: 17),
            label: const Text('Copy .ics calendar feed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.slateLight.withValues(alpha: 0.82),
              foregroundColor: AppColors.panelInk,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: onDisconnect,
            icon: const Icon(LucideIcons.unlink, size: 17),
            label: const Text('Disconnect calendar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.35)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProviderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProviderButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.slateLight.withValues(alpha: 0.82),
          foregroundColor: AppColors.panelInk,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class _SyncRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SyncRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.t3, size: 17),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.t1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.t3,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime dt) {
  return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
