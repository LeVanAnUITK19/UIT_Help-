import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../features/viewmodels/ride_viewmodel.dart';
import 'widgets/ride_card.dart';
import 'widgets/ride_filter_bar.dart';
import 'create_ride_page.dart';

class RidePage extends StatefulWidget {
  const RidePage({super.key});

  @override
  State<RidePage> createState() => _RidePageState();
}

class _RidePageState extends State<RidePage>
    with AutomaticKeepAliveClientMixin {
  final _scrollCtrl = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RideViewModel>().loadRides(refresh: true);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<RideViewModel>().loadRides();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bg,
      body: Consumer<RideViewModel>(
        builder: (context, vm, _) {
          return RefreshIndicator(
            color: AppColors.uitBlue,
            onRefresh: () => vm.loadRides(refresh: true),
            child: CustomScrollView(
              controller: _scrollCtrl,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Filter bar ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: RideFilterBar(
                    selectedType: vm.filterType,
                    selectedFromId: vm.filterFromId,
                    selectedToId: vm.filterToId,
                    onFilter: (type, fromId, toId) =>
                        vm.setFilter(type: type, fromId: fromId, toId: toId),
                  ),
                ),

                // ── Content ────────────────────────────────────────────────
                if (vm.isLoading)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => const _RideCardSkeleton(),
                      childCount: 5,
                    ),
                  )
                else if (vm.errorMessage != null)
                  SliverFillRemaining(
                    child: _ErrorState(
                      message: vm.errorMessage!,
                      onRetry: () => vm.loadRides(refresh: true),
                    ),
                  )
                else if (vm.rides.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyState(
                      onCreateRide: () => _openCreateRide(context),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => RideCard(
                          ride: vm.rides[i],
                          onRequestSent: () => vm.loadRides(refresh: true),
                        ),
                        childCount: vm.rides.length,
                      ),
                    ),
                  ),
                  if (vm.isLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.uitBlue,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),
                  if (!vm.hasMore && vm.rides.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Đã xem hết chuyến đi',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: _CreateFAB(
        onTap: () => _openCreateRide(context),
      ),
    );
  }

  void _openCreateRide(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateRidePage()),
    ).then((_) => context.read<RideViewModel>().loadRides(refresh: true));
  }
}

// ── FAB ─────────────────────────────────────────────────────────────────────

class _CreateFAB extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.uitBlue, AppColors.slateBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.uitBlue.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text(
              'Rủ đi học chung',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton ─────────────────────────────────────────────────────────────────

class _RideCardSkeleton extends StatefulWidget {
  const _RideCardSkeleton();

  @override
  State<_RideCardSkeleton> createState() => _RideCardSkeletonState();
}

class _RideCardSkeletonState extends State<_RideCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmer = isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE2E8F0);

    return FadeTransition(
      opacity: _anim,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: shimmer,
                        borderRadius: BorderRadius.circular(12))),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                            color: shimmer,
                            borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 6),
                    Container(
                        width: 60,
                        height: 10,
                        decoration: BoxDecoration(
                            color: shimmer,
                            borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
                width: double.infinity,
                height: 10,
                decoration: BoxDecoration(
                    color: shimmer, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 8),
            Container(
                width: 160,
                height: 10,
                decoration: BoxDecoration(
                    color: shimmer, borderRadius: BorderRadius.circular(6))),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateRide;
  const _EmptyState({required this.onCreateRide});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.uitBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_bike_rounded,
                size: 50,
                color: AppColors.uitBlue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có ai rủ đi học chung',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy là người đầu tiên rủ bạn cùng lớp\ncùng đi học hôm nay!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onCreateRide,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.uitBlue, AppColors.slateBlue],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Đăng lịch đi học',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 60, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('Thử lại',
                  style: TextStyle(color: AppColors.uitBlue)),
            ),
          ],
        ),
      ),
    );
  }
}
