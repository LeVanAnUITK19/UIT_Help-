import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_theme.dart';
import '../../../features/viewmodels/post_viewmodel.dart';
import '../../../features/viewmodels/locket_viewmodel.dart';
import '../../../features/viewmodels/ride_viewmodel.dart';
import '../../../data/models/ride_model.dart';
import '../ride/ride_detail_page.dart';
import '../ride/create_ride_page.dart';
import 'widgets/post_card.dart';
import 'widgets/create_post_sheet.dart';
import 'widgets/create_locket_sheet.dart';
import 'my_locket_page.dart';

class MyWritePage extends StatefulWidget {
  const MyWritePage({super.key});

  @override
  State<MyWritePage> createState() => _MyWritePageState();
}

class _MyWritePageState extends State<MyWritePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostViewModel>().loadMyPosts(refresh: true);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      if (_tabCtrl.index == 0) {
        context.read<PostViewModel>().loadMyPosts();
      } else if (_tabCtrl.index == 2) {
        context.read<RideViewModel>().loadMyRides();
      }
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A2235) : Colors.white;

    return Column(
      children: [
        // ── Header + Tab buttons ──────────────────────────────────────────
        Container(
          color: bg,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _tabCtrl,
                    builder: (_, __) {
                      final titles = ['Bài viết của tôi', 'Locket của tôi', 'Lịch đi học của tôi'];
                      return Text(
                        titles[_tabCtrl.index],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF050505),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  // FAB tạo nhanh
                  _buildFab(context, isDark),
                ],
              ),
              const SizedBox(height: 7),
              // Tab bar kiểu pill
              _buildTabBar(isDark),
            ],
          ),
        ),
        // ── Tab content ───────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _MyPostsTab(scrollCtrl: _scrollCtrl),
              const MyLocketPage(),
              _MyRidesTab(scrollCtrl: _scrollCtrl),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white54 : Colors.grey[600],
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_rounded, size: 16),
                SizedBox(width: 6),
                Text('Bài viết'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_rounded, size: 16),
                SizedBox(width: 6),
                Text('Locket'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_bike_rounded, size: 16),
                SizedBox(width: 6),
                Text('Đi học'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context, bool isDark) {
    return AnimatedBuilder(
      animation: _tabCtrl,
      builder: (_, __) {
        final idx = _tabCtrl.index;
        final isPost = idx == 0;
        final isRide = idx == 2;

        Color c1, c2;
        IconData icon;
        String label;
        if (isPost) {
          c1 = const Color(0xFF2563EB); c2 = const Color(0xFF4F46E5);
          icon = Icons.edit_rounded; label = 'Đăng bài';
        } else if (isRide) {
          c1 = const Color(0xFF2563EB); c2 = const Color(0xFF4F46E5);
          icon = Icons.directions_bike_rounded; label = 'Đăng lịch';
        } else {
          c1 = const Color(0xFFFF6B6B); c2 = const Color(0xFFFF8E53);
          icon = Icons.add_a_photo_rounded; label = 'Tạo locket';
        }

        return GestureDetector(
          onTap: () {
            if (isPost) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const CreatePostSheet(),
              );
            } else if (isRide) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateRidePage()),
              ).then((_) => context.read<RideViewModel>().loadMyRides(refresh: true));
            } else {
              // Tab Locket
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const CreateLocketSheet(),
              ).then((_) => context.read<LocketViewModel>().loadMyLockets(refresh: true));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [c1, c2]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 15),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── MY POSTS TAB ──────────────────────────────────────────────────────────────
class _MyPostsTab extends StatelessWidget {
  final ScrollController scrollCtrl;
  const _MyPostsTab({required this.scrollCtrl});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vm = context.watch<PostViewModel>();

    if (vm.isLoadingMy && vm.myPosts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.myPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.article_outlined,
              size: 56,
              color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
            ),
            const SizedBox(height: 10),
            Text(
              'Bạn chưa có bài viết nào',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const CreatePostSheet(),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Tạo bài viết đầu tiên',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<PostViewModel>().loadMyPosts(refresh: true),
      child: ListView.builder(
        controller: scrollCtrl,
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: vm.myPosts.length + (vm.isLoadingMy ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == vm.myPosts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return PostCard(post: vm.myPosts[i], showActions: true);
        },
      ),
    );
  }
}

// ── MY RIDES TAB ──────────────────────────────────────────────────────────────
class _MyRidesTab extends StatefulWidget {
  final ScrollController scrollCtrl;
  const _MyRidesTab({required this.scrollCtrl});

  @override
  State<_MyRidesTab> createState() => _MyRidesTabState();
}

class _MyRidesTabState extends State<_MyRidesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RideViewModel>().loadMyRides(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vm = context.watch<RideViewModel>();

    if (vm.isLoadingMy && vm.myRides.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.uitBlue),
      );
    }

    if (vm.myRides.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.uitBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_bike_rounded,
                    size: 40, color: AppColors.uitBlue),
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có lịch đi học nào',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Đăng lịch để rủ bạn cùng lớp đi học nhé!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateRidePage()),
                ).then((_) => context.read<RideViewModel>().loadMyRides(refresh: true)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.uitBlue, AppColors.slateBlue],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Đăng lịch đi học',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.uitBlue,
      onRefresh: () => context.read<RideViewModel>().loadMyRides(refresh: true),
      child: ListView.builder(
        controller: widget.scrollCtrl,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: vm.myRides.length + (vm.isLoadingMy ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == vm.myRides.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final ride = vm.myRides[i];
          return _MyRideCard(ride: ride, isDark: isDark);
        },
      ),
    );
  }
}

class _MyRideCard extends StatelessWidget {
  final RideModel ride;
  final bool isDark;
  const _MyRideCard({required this.ride, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final isFind = ride.type == 'find';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RideDetailPage(rideId: ride.id)),
      ).then((_) => context.read<RideViewModel>().loadMyRides(refresh: true)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark ? AppColors.darkCardShadow : AppColors.lightCardShadow,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────
            Row(
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isFind ? AppColors.uitBlue : AppColors.success).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFind ? Icons.search_rounded : Icons.directions_bike_rounded,
                        size: 12,
                        color: isFind ? AppColors.uitBlue : AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFind ? 'Tìm bạn đi' : 'Rủ đi cùng',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isFind ? AppColors.uitBlue : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _StatusDot(status: ride.status),
              ],
            ),
            const SizedBox(height: 12),

            // ── Route ────────────────────────────────────────────────────
            Row(
              children: [
                Column(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.uitBlue, shape: BoxShape.circle)),
                    Container(width: 2, height: 18, color: AppColors.uitBlue.withOpacity(0.3)),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ride.from.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                      const SizedBox(height: 10),
                      Text(ride.to.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Footer ───────────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 13, color: AppColors.uitBlue),
                const SizedBox(width: 4),
                Text(_fmtDt(ride.departureTime), style: TextStyle(fontSize: 12, color: AppColors.uitBlue, fontWeight: FontWeight.w500)),
                const Spacer(),
                Icon(Icons.people_rounded, size: 13, color: textSecondary),
                const SizedBox(width: 4),
                Text('${ride.participants.length} người', style: TextStyle(fontSize: 12, color: textSecondary)),
                const SizedBox(width: 12),
                // Quick actions
                if (ride.status == 'active' || ride.status == 'full')
                  _QuickActions(ride: ride),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDt(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$h:$m  $d/$mo';
  }
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'full':     color = AppColors.warning;            label = 'Đã đầy';      break;
      case 'done':     color = AppColors.lightTextSecondary; label = 'Hoàn thành';  break;
      case 'cancelled':color = AppColors.error;              label = 'Đã hủy';      break;
      default:         color = AppColors.success;            label = 'Còn chỗ';
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final RideModel ride;
  const _QuickActions({required this.ride});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz_rounded, size: 18, color: AppColors.lightTextSecondary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (val) async {
        final vm = context.read<RideViewModel>();
        if (val == 'complete') {
          await vm.completeRide(ride.id);
        } else if (val == 'cancel') {
          await vm.cancelRide(ride.id);
        } else if (val == 'delete') {
          await vm.deleteRide(ride.id);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'complete',
          child: Row(children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
            SizedBox(width: 8),
            Text('Hoàn thành'),
          ]),
        ),
        const PopupMenuItem(
          value: 'cancel',
          child: Row(children: [
            Icon(Icons.cancel_rounded, color: AppColors.warning, size: 18),
            SizedBox(width: 8),
            Text('Hủy lịch'),
          ]),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_rounded, color: AppColors.error, size: 18),
            SizedBox(width: 8),
            Text('Xóa', style: TextStyle(color: AppColors.error)),
          ]),
        ),
      ],
    );
  }
}
