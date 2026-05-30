import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/widgets/slate_ui.dart';
import 'add_client_screen.dart';
import 'client_detail_screen.dart';

enum _ClientView { all, leads, followUps }

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _ClientView _view = _ClientView.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(clientCrmRecordsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: records.when(
          loading: () => const _ClientsLoading(),
          error: (_, __) => Padding(
            padding: const EdgeInsets.all(AppSpacing.pageX),
            child: SlateErrorState(message: 'Error loading clients'),
          ),
          data: (data) {
            final filtered = _filterAndSort(data);
            return RefreshIndicator(
              color: AppColors.green,
              onRefresh: () async {
                ref.invalidate(clientsProvider);
                ref.invalidate(clientCrmRecordsProvider);
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageX,
                        AppSpacing.lg,
                        AppSpacing.pageX,
                        0,
                      ),
                      child: _Header(
                        total: data.length,
                        leads: data.where((item) => item.isLead).length,
                        attention: data
                            .where((item) => item.needsAttention)
                            .length,
                        onAdd: _openAddClient,
                      ),
                    ),
                  ),
                  if (data.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pageX,
                          AppSpacing.md,
                          AppSpacing.pageX,
                          0,
                        ),
                        child: _SearchAndSort(
                          controller: _searchController,
                          onQueryChanged: (value) =>
                              setState(() => _query = value.trim()),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: _ViewRail(
                          selected: _view,
                          records: data,
                          onChanged: (value) => setState(() => _view = value),
                        ),
                      ),
                    ),
                  ],
                  if (data.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(onAdd: _openAddClient),
                    )
                  else if (filtered.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _NoMatches(),
                    )
                  else
                    SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final record = filtered[index];
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.pageX,
                            index == 0 ? AppSpacing.sm : 0,
                            AppSpacing.pageX,
                            index == filtered.length - 1 ? 132 : 0,
                          ),
                          child: _ClientRow(
                            record: record,
                            onTap: () => _openClient(record),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<ClientCrmRecord> _filterAndSort(List<ClientCrmRecord> data) {
    final query = _query.toLowerCase();
    final filtered = data.where((record) {
      final client = record.client;
      final matchesQuery =
          query.isEmpty ||
          client.name.toLowerCase().contains(query) ||
          (client.phone ?? '').toLowerCase().contains(query) ||
          (client.email ?? '').toLowerCase().contains(query) ||
          client.tags.any((tag) => tag.toLowerCase().contains(query));

      final matchesView = switch (_view) {
        _ClientView.all => true,
        _ClientView.leads => record.isLead,
        _ClientView.followUps => record.openTaskCount > 0,
      };
      return matchesQuery && matchesView;
    }).toList();

    filtered.sort((a, b) {
      final nextComparison = _nextDate(a).compareTo(_nextDate(b));
      if (nextComparison != 0) return nextComparison;
      final taskComparison = b.openTaskCount.compareTo(a.openTaskCount);
      if (taskComparison != 0) return taskComparison;
      return a.client.name.compareTo(b.client.name);
    });
    return filtered;
  }

  DateTime _nextDate(ClientCrmRecord record) {
    return record.nextBooking?.startTime ?? DateTime(9999);
  }

  Future<void> _openAddClient() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddClientScreen()),
    );
    ref.invalidate(clientsProvider);
    ref.invalidate(clientCrmRecordsProvider);
  }

  Future<void> _openClient(ClientCrmRecord record) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientDetailScreen(client: record.client.toMap()),
      ),
    );
    ref.invalidate(clientsProvider);
    ref.invalidate(clientCrmRecordsProvider);
  }
}

class _Header extends StatelessWidget {
  final int total;
  final int leads;
  final int attention;
  final VoidCallback onAdd;

  const _Header({
    required this.total,
    required this.leads,
    required this.attention,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Clients',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.t1,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                total == 0
                    ? 'Build your client base'
                    : '$total clients · $leads leads · $attention follow-ups',
                style: const TextStyle(color: AppColors.t3, fontSize: 13),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.t1.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.t1.withValues(alpha: 0.08)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.userPlus, color: AppColors.t1, size: 16),
                SizedBox(width: 8),
                Text(
                  'New',
                  style: TextStyle(
                    color: AppColors.t1,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchAndSort extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;

  const _SearchAndSort({
    required this.controller,
    required this.onQueryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onQueryChanged,
      style: const TextStyle(color: AppColors.t1, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search clients or tags',
        prefixIcon: const Icon(
          LucideIcons.search,
          color: AppColors.t3,
          size: 16,
        ),
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}

class _ViewRail extends StatelessWidget {
  final _ClientView selected;
  final List<ClientCrmRecord> records;
  final ValueChanged<_ClientView> onChanged;

  const _ViewRail({
    required this.selected,
    required this.records,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
        children: [
          _chip(_ClientView.all, 'All', records.length),
          _chip(
            _ClientView.leads,
            'Leads',
            records.where((item) => item.isLead).length,
          ),
          _chip(
            _ClientView.followUps,
            'Follow-ups',
            records.where((item) => item.openTaskCount > 0).length,
          ),
        ],
      ),
    );
  }

  Widget _chip(_ClientView value, String label, int count) {
    final active = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: AppMotion.standard,
          curve: AppMotion.curve,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? AppColors.t1.withValues(alpha: 0.12)
                : AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: active
                  ? AppColors.t1.withValues(alpha: 0.16)
                  : AppColors.border,
            ),
          ),
          child: Text(
            '$label $count',
            style: TextStyle(
              color: active ? AppColors.t1 : AppColors.t3,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientRow extends StatelessWidget {
  final ClientCrmRecord record;
  final VoidCallback onTap;

  const _ClientRow({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final client = record.client;
    final initials = client.name
        .trim()
        .split(RegExp(r'\s+'))
        .map((word) => word.isEmpty ? '' : word[0])
        .take(2)
        .join()
        .toUpperCase();
    final next = record.nextBooking;
    final nextText = next == null
        ? null
        : 'Next booking ${_friendlyDate(next.startTime)}';
    final taskText = record.openTaskCount == 0
        ? null
        : record.overdueTaskCount > 0
        ? '${record.overdueTaskCount} overdue task${record.overdueTaskCount == 1 ? '' : 's'}'
        : '${record.openTaskCount} open task${record.openTaskCount == 1 ? '' : 's'}';

    return SlateSurface(
      onTap: onTap,
      radius: AppRadius.xl,
      color: AppColors.bgCard,
      borderColor: record.overdueTaskCount > 0
          ? AppColors.error.withValues(alpha: 0.20)
          : AppColors.border,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.t1.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    initials.isEmpty ? '?' : initials,
                    style: const TextStyle(
                      color: AppColors.t2,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            client.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.t1,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (record.isLead) const _StatusPill(label: 'Lead'),
                      ],
                    ),
                    if (client.tags.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        client.tags.take(2).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.t3,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                LucideIcons.chevronRight,
                color: AppColors.t3,
                size: 16,
              ),
            ],
          ),
          if (nextText != null ||
              taskText != null ||
              record.outstandingBalance > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (nextText != null)
                  _InfoChip(icon: LucideIcons.calendarDays, label: nextText),
                if (taskText != null)
                  _InfoChip(
                    icon: LucideIcons.listChecks,
                    label: taskText,
                    urgent: record.overdueTaskCount > 0,
                  ),
                if (record.outstandingBalance > 0)
                  _InfoChip(
                    icon: LucideIcons.walletCards,
                    label:
                        '£${record.outstandingBalance.toStringAsFixed(0)} unpaid',
                    urgent: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.warning,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool urgent;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.urgent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = urgent ? AppColors.error : AppColors.t2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientsLoading extends StatelessWidget {
  const _ClientsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        AppSpacing.pageTop,
        AppSpacing.pageX,
        132,
      ),
      itemCount: 7,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, index) => SlateLoadingBlock(
        height: index == 0 ? 116 : 98,
        radius: AppRadius.xl,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SlateEmptyState(
              icon: LucideIcons.users,
              title: 'No clients yet',
              subtitle:
                  'Add a client, capture their preferences, then build bookings, payments, and tasks around them.',
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(LucideIcons.userPlus, size: 17),
                label: const Text(
                  'Add Client',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.searchX, color: AppColors.t3, size: 32),
          SizedBox(height: 12),
          Text(
            'No clients match that view',
            style: TextStyle(color: AppColors.t3, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

String _friendlyDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  if (target == today) return 'today';
  if (target == today.add(const Duration(days: 1))) return 'tomorrow';
  return '${date.day}/${date.month}';
}
