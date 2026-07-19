import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/widgets/slate_ui.dart';
import 'add_client_screen.dart';
import 'client_detail_screen.dart';
import 'client_sort.dart';
import 'client_view.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';
  ClientView _view = ClientView.all;
  ClientSortOrder _sortOrder = ClientSortOrder.nextBooking;
  double _horizontalDragDistance = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(clientCrmRecordsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          records.when(
            loading: () => const _ClientsLoading(),
            error: (_, __) => Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageX,
                AppSpacing.pageTop + AppSpacing.xxl,
                AppSpacing.pageX,
                AppSpacing.pageX,
              ),
              child: SlateErrorState(message: 'Error loading clients'),
            ),
            data: (data) {
              final filtered = _filterAndSort(data);
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: (_) => _horizontalDragDistance = 0,
                onHorizontalDragUpdate: (details) {
                  _horizontalDragDistance += details.primaryDelta ?? 0;
                },
                onHorizontalDragEnd: _handleHorizontalSwipe,
                child: RefreshIndicator(
                  color: AppColors.accentPrimary,
                  onRefresh: () async {
                    ref.invalidate(clientsProvider);
                    ref.invalidate(clientCrmRecordsProvider);
                  },
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.pageX,
                            AppSpacing.pageTop + AppSpacing.xxl,
                            AppSpacing.pageX,
                            0,
                          ),
                          child: _Header(onAdd: _openAddClient),
                        ),
                      ),
                      if (data.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.pageX,
                              AppSpacing.xxl,
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
                              onChanged: _changeView,
                            ),
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
                            child: _SortToolbar(
                              resultCount: filtered.length,
                              sortOrder: _sortOrder,
                              onSort: _showSortPicker,
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
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _NoMatches(
                            view: _view,
                            hasQuery: _query.isNotEmpty,
                          ),
                        )
                      else
                        SliverList.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox.shrink(),
                          itemBuilder: (context, index) {
                            final record = filtered[index];
                            return Padding(
                              padding: EdgeInsets.fromLTRB(
                                AppSpacing.pageX,
                                index == 0 ? AppSpacing.xs : 0,
                                AppSpacing.pageX,
                                index == filtered.length - 1 ? 132 : 0,
                              ),
                              child: _ClientRow(
                                record: record,
                                showInactive:
                                    _view == ClientView.all &&
                                    record.isInactive,
                                onTap: () => _openClient(record),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
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

      final matchesView = clientStatusMatchesView(
        status: client.status,
        view: _view,
      );
      return matchesQuery && matchesView;
    }).toList();

    return sortClientRecords(filtered, _sortOrder);
  }

  void _handleHorizontalSwipe(DragEndDetails details) {
    final nextView = clientViewAfterSwipe(
      current: _view,
      dragDistance: _horizontalDragDistance,
      velocity: details.primaryVelocity ?? 0,
    );
    _horizontalDragDistance = 0;
    if (nextView == _view) return;

    SlateHaptics.tap();
    _changeView(nextView);
  }

  void _changeView(ClientView view) {
    if (view == _view) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _view = view);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: AppMotion.standard,
        curve: AppMotion.curve,
      );
    });
  }

  Future<void> _showSortPicker() async {
    final selected = await showModalBottomSheet<ClientSortOrder>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      builder: (context) => _ClientSortSheet(selected: _sortOrder),
    );
    if (selected != null && mounted) {
      setState(() => _sortOrder = selected);
    }
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
  final VoidCallback onAdd;

  const _Header({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clients',
                style: TextStyle(
                  color: AppColors.t1,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.04,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'People you work with.',
                style: TextStyle(
                  color: AppColors.t2,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.32,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        WorkloopIconButton(
          icon: LucideIcons.plus,
          semanticLabel: 'New client',
          color: AppColors.modClients,
          backgroundColor: AppColors.modClients.withValues(alpha: 0.10),
          size: 48,
          onTap: onAdd,
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
        fillColor: AppColors.t1.withValues(alpha: 0.028),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.62),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.62),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: const BorderSide(
            color: AppColors.accentPrimary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}

class _SortToolbar extends StatelessWidget {
  final int resultCount;
  final ClientSortOrder sortOrder;
  final VoidCallback onSort;

  const _SortToolbar({
    required this.resultCount,
    required this.sortOrder,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final countLabel = resultCount == 1 ? '1 client' : '$resultCount clients';
    return Row(
      children: [
        Expanded(
          child: Text(
            countLabel,
            style: const TextStyle(
              color: AppColors.t2,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              SlateHaptics.tap();
              onSort();
            },
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.bgCard.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.72),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.arrowUpDown,
                    size: 14,
                    color: AppColors.t2,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    sortOrder.label,
                    style: const TextStyle(
                      color: AppColors.t1,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClientSortSheet extends StatelessWidget {
  final ClientSortOrder selected;

  const _ClientSortSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    return SlateSheetFrame(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sort clients',
            style: TextStyle(
              color: AppColors.t1,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Choose how clients are ordered.',
            style: TextStyle(
              color: AppColors.t2,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final order in ClientSortOrder.values)
            _ClientSortOption(
              order: order,
              selected: order == selected,
              showDivider: order != ClientSortOrder.values.last,
              onTap: () => Navigator.pop(context, order),
            ),
        ],
      ),
    );
  }
}

class _ClientSortOption extends StatelessWidget {
  final ClientSortOrder order;
  final bool selected;
  final bool showDivider;
  final VoidCallback onTap;

  const _ClientSortOption({
    required this.order,
    required this.selected,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: selected
                ? AppColors.accentPrimary.withValues(alpha: 0.07)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.label,
                          style: TextStyle(
                            color: AppColors.t1,
                            fontSize: 14,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      AnimatedOpacity(
                        duration: AppMotion.fast,
                        opacity: selected ? 1 : 0,
                        child: const Icon(
                          LucideIcons.check,
                          color: AppColors.modHome,
                          size: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (showDivider)
            const Divider(
              height: 1,
              thickness: 1,
              indent: AppSpacing.sm,
              endIndent: AppSpacing.sm,
              color: AppColors.border,
            ),
        ],
      ),
    );
  }
}

class _ViewRail extends StatelessWidget {
  final ClientView selected;
  final List<ClientCrmRecord> records;
  final ValueChanged<ClientView> onChanged;

  const _ViewRail({
    required this.selected,
    required this.records,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = <({ClientView value, String label, int count})>[
      (value: ClientView.all, label: 'All', count: records.length),
      (
        value: ClientView.active,
        label: 'Active',
        count: records.where((item) => item.isActive).length,
      ),
      (
        value: ClientView.leads,
        label: 'Leads',
        count: records.where((item) => item.isLead).length,
      ),
      (
        value: ClientView.inactive,
        label: 'Inactive',
        count: records.where((item) => item.isInactive).length,
      ),
    ];
    final selectedIndex = items.indexWhere((item) => item.value == selected);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
      child: SlateGlassSurface(
        blur: 22,
        color: AppColors.bgCard.withValues(alpha: 0.90),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: SizedBox(
          height: 54,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / items.length;
              void selectView(ClientView value) {
                if (value == selected) return;
                SlateHaptics.tap();
                onChanged(value);
              }

              void handleDrag(double dx) {
                selectView(
                  clientViewAtHorizontalPosition(
                    position: dx,
                    width: constraints.maxWidth,
                  ),
                );
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
                      left: selectedIndex * itemWidth,
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
                      children: [
                        for (final item in items)
                          Expanded(
                            child: _ClientViewButton(
                              label: item.label,
                              count: item.count,
                              selected: item.value == selected,
                              onTap: () => selectView(item.value),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ClientViewButton extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _ClientViewButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count clients',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: AppMotion.standard,
            curve: AppMotion.curve,
            style: TextStyle(
              color: selected ? AppColors.accentPrimary : AppColors.t3,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            child: Text('$label $count'),
          ),
        ),
      ),
    );
  }
}

class _ClientRow extends StatelessWidget {
  final ClientCrmRecord record;
  final bool showInactive;
  final VoidCallback onTap;

  const _ClientRow({
    required this.record,
    required this.showInactive,
    required this.onTap,
  });

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
    final signal = _clientSignal(record);

    return WorkloopListRow(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.modClients.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initials.isEmpty ? '?' : initials,
            style: const TextStyle(
              color: AppColors.t1,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      title: Text(
        client.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.t1,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        signal,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.t2,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showInactive) ...[
            const Text(
              'Inactive',
              style: TextStyle(
                color: AppColors.t3,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          const Icon(LucideIcons.chevronRight, color: AppColors.t3, size: 16),
        ],
      ),
    );
  }

  String _clientSignal(ClientCrmRecord record) {
    final next = record.nextBooking;
    if (next != null) return 'Next booking ${_friendlyDate(next.startTime)}';
    final last = record.lastBooking;
    if (last != null) {
      final days = DateTime.now().difference(last.startTime).inDays;
      if (days <= 0) return 'Last job today';
      if (days == 1) return 'Last job yesterday';
      return 'Last job $days days ago';
    }
    if (record.client.tags.isNotEmpty) return record.client.tags.first;
    if (record.client.status == 'lead') return 'Lead';
    return 'No bookings yet';
  }
}

class _ClientsLoading extends StatelessWidget {
  const _ClientsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        AppSpacing.pageTop + AppSpacing.xxl,
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
            const WorkloopEmptyState(
              icon: LucideIcons.users,
              title: 'No clients yet',
              subtitle:
                  'Add a client, capture their preferences, then build bookings, payments, and tasks around them.',
            ),
            const SizedBox(height: 24),
            WorkloopPrimaryButton(
              label: 'Add client',
              icon: LucideIcons.userPlus,
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  final ClientView view;
  final bool hasQuery;

  const _NoMatches({required this.view, required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = hasQuery
        ? (
            LucideIcons.searchX,
            'No matching clients',
            'Try a different name, contact detail, or tag.',
          )
        : switch (view) {
            ClientView.all => (
              LucideIcons.users,
              'No clients yet',
              'Add your first client to begin.',
            ),
            ClientView.active => (
              LucideIcons.userCheck,
              'No active clients',
              'Clients marked active will appear here.',
            ),
            ClientView.leads => (
              LucideIcons.userPlus,
              'No leads yet',
              'New prospects will appear here.',
            ),
            ClientView.inactive => (
              LucideIcons.userMinus,
              'No inactive clients',
              'Clients you pause will appear here.',
            ),
          };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.t3, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.t2,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.t3, fontSize: 12),
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
