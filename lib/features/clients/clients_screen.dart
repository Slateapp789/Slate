import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/widgets/slate_ui.dart';
import 'add_client_screen.dart';
import 'client_detail_screen.dart';

enum _ClientView { all, attention, leads, regulars, dormant }

enum _ClientSort { priority, recent, value, name }

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _ClientView _view = _ClientView.all;
  _ClientSort _sort = _ClientSort.priority;

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
                        child: _CrmCommandBar(records: data),
                      ),
                    ),
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
                          sort: _sort,
                          onQueryChanged: (value) =>
                              setState(() => _query = value.trim()),
                          onSortChanged: (value) =>
                              setState(() => _sort = value),
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
                            index == 0 ? AppSpacing.md : 0,
                            AppSpacing.pageX,
                            index == filtered.length - 1 ? 132 : 0,
                          ),
                          child: _ClientCrmRow(
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
        _ClientView.attention => record.needsAttention,
        _ClientView.leads => record.isLead,
        _ClientView.regulars => record.completedBookingCount >= 3,
        _ClientView.dormant => record.isDormant,
      };
      return matchesQuery && matchesView;
    }).toList();

    filtered.sort((a, b) {
      return switch (_sort) {
        _ClientSort.priority => b.attentionScore.compareTo(a.attentionScore),
        _ClientSort.recent => _activityDate(b).compareTo(_activityDate(a)),
        _ClientSort.value => b.lifetimeValue.compareTo(a.lifetimeValue),
        _ClientSort.name => a.client.name.compareTo(b.client.name),
      };
    });
    return filtered;
  }

  DateTime _activityDate(ClientCrmRecord record) {
    return record.client.lastActivityAt ??
        record.lastBooking?.startTime ??
        record.client.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
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
                    : '$total contacts · $leads leads · $attention need attention',
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

class _CrmCommandBar extends StatelessWidget {
  final List<ClientCrmRecord> records;

  const _CrmCommandBar({required this.records});

  @override
  Widget build(BuildContext context) {
    final outstanding = records.fold<double>(
      0,
      (sum, item) => sum + item.outstandingBalance,
    );
    final nextBookingCount = records
        .where((item) => item.nextBooking != null)
        .length;
    final overdueFollowUps = records.fold<int>(
      0,
      (sum, item) => sum + item.overdueTaskCount,
    );

    return SlateSurface(
      radius: AppRadius.xl,
      color: AppColors.panelSoft,
      borderColor: AppColors.panelSoftRaised,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _CommandMetric(
              label: 'Follow-ups',
              value: overdueFollowUps == 0 ? 'Clear' : '$overdueFollowUps due',
              icon: LucideIcons.bell,
              urgent: overdueFollowUps > 0,
            ),
          ),
          _Divider(),
          Expanded(
            child: _CommandMetric(
              label: 'Unpaid',
              value: outstanding == 0
                  ? '£0'
                  : '£${outstanding.toStringAsFixed(0)}',
              icon: LucideIcons.walletCards,
              urgent: outstanding > 0,
            ),
          ),
          _Divider(),
          Expanded(
            child: _CommandMetric(
              label: 'Booked',
              value: '$nextBookingCount',
              icon: LucideIcons.calendarCheck,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool urgent;

  const _CommandMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.urgent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = urgent ? AppColors.error : AppColors.t2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(height: 10),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.t3,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: AppColors.t1.withValues(alpha: 0.10),
    );
  }
}

class _SearchAndSort extends StatelessWidget {
  final TextEditingController controller;
  final _ClientSort sort;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<_ClientSort> onSortChanged;

  const _SearchAndSort({
    required this.controller,
    required this.sort,
    required this.onQueryChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onQueryChanged,
            style: const TextStyle(color: AppColors.t1, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search name, phone, email, tag',
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
                borderSide: const BorderSide(
                  color: AppColors.green,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<_ClientSort>(
              value: sort,
              icon: const Icon(
                LucideIcons.chevronDown,
                color: AppColors.t3,
                size: 16,
              ),
              dropdownColor: AppColors.bgRaised,
              borderRadius: BorderRadius.circular(AppRadius.md),
              onChanged: (value) {
                if (value != null) onSortChanged(value);
              },
              items: const [
                DropdownMenuItem(
                  value: _ClientSort.priority,
                  child: Text('Priority'),
                ),
                DropdownMenuItem(
                  value: _ClientSort.recent,
                  child: Text('Recent'),
                ),
                DropdownMenuItem(
                  value: _ClientSort.value,
                  child: Text('Value'),
                ),
                DropdownMenuItem(value: _ClientSort.name, child: Text('Name')),
              ],
            ),
          ),
        ),
      ],
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
            _ClientView.attention,
            'Attention',
            records.where((item) => item.needsAttention).length,
          ),
          _chip(
            _ClientView.leads,
            'Leads',
            records.where((item) => item.isLead).length,
          ),
          _chip(
            _ClientView.regulars,
            'Regulars',
            records.where((item) => item.completedBookingCount >= 3).length,
          ),
          _chip(
            _ClientView.dormant,
            'Dormant',
            records.where((item) => item.isDormant).length,
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

class _ClientCrmRow extends StatelessWidget {
  final ClientCrmRecord record;
  final VoidCallback onTap;

  const _ClientCrmRow({required this.record, required this.onTap});

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
        ? 'No booking set'
        : 'Next ${_friendlyDate(next.startTime)}';
    final meta = [
      if ((client.phone ?? '').isNotEmpty) client.phone!,
      if ((client.source ?? '').isNotEmpty) client.source!,
    ].join(' · ');

    return SlateSurface(
      onTap: onTap,
      radius: AppRadius.xl,
      color: AppColors.bgCard,
      borderColor: record.needsAttention
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
                        _SegmentPill(record: record),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta.isEmpty ? nextText : '$meta · $nextText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.t3, fontSize: 12),
                    ),
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
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _MiniSignal(
                label: 'Value',
                value: '£${record.lifetimeValue.toStringAsFixed(0)}',
                icon: LucideIcons.banknote,
              ),
              _MiniSignal(
                label: 'Bookings',
                value: '${record.bookingCount}',
                icon: LucideIcons.calendarDays,
              ),
              _MiniSignal(
                label: 'Tasks',
                value: record.openTaskCount == 0
                    ? 'Clear'
                    : '${record.openTaskCount}',
                icon: LucideIcons.listChecks,
                urgent: record.overdueTaskCount > 0,
              ),
              if (record.outstandingBalance > 0)
                _MiniSignal(
                  label: 'Owes',
                  value: '£${record.outstandingBalance.toStringAsFixed(0)}',
                  icon: LucideIcons.walletCards,
                  urgent: true,
                ),
            ],
          ),
          if (client.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: client.tags.take(4).map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgInteract,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: AppColors.t3,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SegmentPill extends StatelessWidget {
  final ClientCrmRecord record;

  const _SegmentPill({required this.record});

  @override
  Widget build(BuildContext context) {
    final color = switch (record.segment) {
      'Attention' => AppColors.error,
      'Lead' => AppColors.warning,
      'Dormant' => AppColors.t3,
      _ => AppColors.green,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        record.segment,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MiniSignal extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool urgent;

  const _MiniSignal({
    required this.label,
    required this.value,
    required this.icon,
    this.urgent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = urgent ? AppColors.error : AppColors.t2;
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '$label $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
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
