import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_theme.dart';
import '../../../features/viewmodels/post_viewmodel.dart';
import '../../../features/viewmodels/locket_viewmodel.dart';
import 'widgets/post_card.dart';
import 'widgets/create_post_sheet.dart';
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
    _tabCtrl = TabController(length: 2, vsync: this);
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
                      return Text(
                        _tabCtrl.index == 0
                            ? 'Bài viết của tôi'
                            : 'Locket của tôi',
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
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context, bool isDark) {
    return AnimatedBuilder(
      animation: _tabCtrl,
      builder: (_, __) {
        final isPost = _tabCtrl.index == 0;
        return GestureDetector(
          onTap: () {
            if (isPost) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const CreatePostSheet(),
              );
            } else {
              // Locket tab — handled inside MyLocketPage
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPost
                    ? [const Color(0xFF2563EB), const Color(0xFF4F46E5)]
                    : [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPost ? Icons.edit_rounded : Icons.add_a_photo_rounded,
                  color: Colors.white,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  isPost ? 'Đăng bài' : 'Tạo locket',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
