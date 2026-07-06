import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/business_feed_item.dart';
import '../../shared/providers/appointments_provider.dart';
import '../../shared/providers/business_feed_provider.dart';
import '../../shared/providers/clients_provider.dart';
import '../../shared/providers/finance_provider.dart';
import '../../shared/providers/notes_provider.dart';
import '../../shared/providers/tasks_provider.dart';
import '../../shared/widgets/business_feed_list.dart';
import '../../shared/widgets/slate_ui.dart';

class BusinessFeedScreen extends ConsumerStatefulWidget {
  const BusinessFeedScreen({super.key});

  @override
  ConsumerState<BusinessFeedScreen> createState() => _BusinessFeedScreenState();
}

class _BusinessFeedScreenState extends ConsumerState<BusinessFeedScreen> {
  BusinessFeedFilter _filter = BusinessFeedFilter.all;

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(businessFeedProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: _refreshFeed,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageX,
                  AppSpacing.lg,
                  AppSpacing.pageX,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      SlateIconButton(
                        icon: LucideIcons.chevronLeft,
                        semanticLabel: 'Back',
                        onTap: () => Navigator.maybePop(context),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: SlateFeatureHeader(
                          icon: LucideIcons.activity,
                          title: 'Business Feed',
                          subtitle:
                              'What happened and what needs your attention.',
                          color: AppColors.modHome,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: _FeedFilterRail(
                    selected: _filter,
                    onChanged: (filter) => setState(() => _filter = filter),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageX,
                  AppSpacing.md,
                  AppSpacing.pageX,
                  40,
                ),
                sliver: SliverToBoxAdapter(
                  child: feed.when(
                    loading: () => _loadingFeed(),
                    error: (_, __) =>
                        const SlateErrorState(message: 'Could not load feed'),
                    data: (items) => BusinessFeedList(
                      items: filteredBusinessFeedItems(items, _filter),
                      emptyMessage: _emptyMessageFor(_filter),
                      onItemTap: _openFeedItem,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshFeed() async {
    SlateHaptics.action();
    ref.invalidate(appointmentsProvider);
    ref.invalidate(clientsProvider);
    ref.invalidate(invoicesProvider);
    ref.invalidate(expensesProvider);
    ref.invalidate(financeSummaryProvider);
    ref.invalidate(allTasksProvider);
    ref.invalidate(allNotesProvider);
    ref.invalidate(businessFeedProvider);
  }

  Widget _loadingFeed() {
    return Column(
      children: List.generate(
        7,
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.xs),
          child: SlateLoadingBlock(height: 82, radius: AppRadius.lg),
        ),
      ),
    );
  }

  void _openFeedItem(BusinessFeedItem item) {
    final route = item.routeTarget;
    if (route == null) return;
    SlateHaptics.action();
    context.push(route);
  }

  String _emptyMessageFor(BusinessFeedFilter filter) {
    return switch (filter) {
      BusinessFeedFilter.all =>
        'Your business feed will appear here as bookings, payments, tasks and notes happen.',
      BusinessFeedFilter.attention =>
        'Nothing needs attention right now. New follow-ups, overdue tasks and payment reminders will appear here.',
      BusinessFeedFilter.money =>
        'Money activity will appear here as payments and expenses are logged.',
      BusinessFeedFilter.bookings =>
        'Booking activity will appear here as bookings and requests come in.',
      BusinessFeedFilter.tasks =>
        'Task activity will appear here when tasks are due or overdue.',
      BusinessFeedFilter.clients =>
        'Client follow-ups will appear here when a customer or lead needs attention.',
    };
  }
}

class _FeedFilterRail extends StatelessWidget {
  final BusinessFeedFilter selected;
  final ValueChanged<BusinessFeedFilter> onChanged;

  const _FeedFilterRail({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
      child: Row(
        children: [
          for (final filter in BusinessFeedFilter.values) ...[
            _FeedFilterChip(
              label: _labelFor(filter),
              selected: selected == filter,
              onTap: () => onChanged(filter),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }

  String _labelFor(BusinessFeedFilter filter) {
    return switch (filter) {
      BusinessFeedFilter.all => 'All',
      BusinessFeedFilter.attention => 'Needs attention',
      BusinessFeedFilter.money => 'Money',
      BusinessFeedFilter.bookings => 'Bookings',
      BusinessFeedFilter.tasks => 'Tasks',
      BusinessFeedFilter.clients => 'Clients',
    };
  }
}

class _FeedFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FeedFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        SlateHaptics.tap();
        onTap();
      },
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.modHome : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.modHome : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.bgCard : AppColors.t2,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
