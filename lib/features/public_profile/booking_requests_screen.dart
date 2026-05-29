import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/slate_models.dart';
import '../../shared/providers/workspace_provider.dart';
import '../../shared/repositories/slate_repositories.dart';

final bookingRequestsProvider = FutureProvider<List<BookingRequest>>((
  ref,
) async {
  final workspaceId = await ref.watch(workspaceIdProvider.future);
  if (workspaceId == null) return [];
  try {
    return ref.watch(profileRepositoryProvider).bookingRequests(workspaceId);
  } catch (_) {
    return [];
  }
});

class BookingRequestsScreen extends ConsumerWidget {
  const BookingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(bookingRequestsProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
                  const SizedBox(width: 14),
                  const Text(
                    'Booking requests',
                    style: TextStyle(
                      color: AppColors.t1,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: requests.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.green),
                ),
                error: (_, __) => const _EmptyRequests(
                  title: 'Could not load requests',
                  subtitle: 'Try again in a moment.',
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const _EmptyRequests(
                      title: 'No booking requests',
                      subtitle:
                          'Requests from your public profile will appear here.',
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.green,
                    onRefresh: () async =>
                        ref.invalidate(bookingRequestsProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      itemBuilder: (context, index) =>
                          _RequestCard(request: items[index]),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: items.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  final BookingRequest request;
  const _RequestCard({required this.request});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _saving = false;

  Future<void> _setStatus(String status) async {
    setState(() => _saving = true);
    await ref
        .read(profileRepositoryProvider)
        .updateBookingRequestStatus(widget.request.id, status);
    ref.invalidate(bookingRequestsProvider);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final pending = request.status == 'pending';
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
          Row(
            children: [
              Expanded(
                child: Text(
                  request.name,
                  style: const TextStyle(
                    color: AppColors.t1,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusBadge(status: request.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(request.phone, style: const TextStyle(color: AppColors.t2)),
          if (request.message?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              request.message!,
              style: const TextStyle(color: AppColors.t3, height: 1.35),
            ),
          ],
          if (pending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Decline',
                    color: AppColors.error,
                    loading: _saving,
                    onTap: () => _setStatus('declined'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'Confirm',
                    color: AppColors.green,
                    loading: _saving,
                    onTap: () => _setStatus('confirmed'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'confirmed' => AppColors.success,
      'declined' => AppColors.error,
      _ => AppColors.warning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  final String title;
  final String subtitle;
  const _EmptyRequests({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.inbox, color: AppColors.t3, size: 38),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.t1,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.t3),
            ),
          ],
        ),
      ),
    );
  }
}
