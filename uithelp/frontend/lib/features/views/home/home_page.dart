import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_theme.dart';
import '../../../features/viewmodels/auth_viewmodel.dart';
import '../../../features/viewmodels/post_viewmodel.dart';
import '../../../features/viewmodels/notification_viewmodel.dart';
import '../../../features/viewmodels/locket_viewmodel.dart';
import '../../../features/views/chat/conversation_list_sheet.dart';
import 'myWrite_page.dart';
import 'notification_page.dart';
import 'setting_page.dart';
import 'locket_page.dart';
import 'widgets/post_card.dart';
import 'widgets/create_post_sheet.dart';
import 'widgets/comment_sheet.dart';
import 'widgets/locket_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final _scrollCtrl = ScrollController();
  // Map itemIndex → GlobalKey để scroll đến post
  final Map<String, GlobalKey> _postKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostViewModel>().loadPosts(refresh: true);
      context.read<NotificationViewModel>().fetchUnreadCount();
    });
    _scrollCtrl.addListener(_onScroll);
  }

  void _handlePendingScroll() {
    final vm = context.read<PostViewModel>();
    final targetId = vm.pendingScrollToPostId;
    if (targetId == null) return;
    vm.clearPendingScroll();
    setState(() => _selectedIndex = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _postKeys[targetId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
    });
  }

  void _handleNotifNav(NotificationViewModel notifVm) {
    final nav = notifVm.pendingNav;
    if (nav == null) return;
    notifVm.clearPendingNav();

    switch (nav.type) {
      case NotifNavType.post:
        if (nav.id != null) {
          // Switch về feed tab rồi scroll đến post, đồng thời mở comment sheet
          setState(() => _selectedIndex = 0);
          context.read<PostViewModel>().requestScrollToPost(nav.id!);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => CommentSheet(postId: nav.id!),
              );
            }
          });
        }
        break;
      case NotifNavType.locket:
        if (nav.id != null) {
          // Switch sang tab Locket (index 2)
          setState(() => _selectedIndex = 2);
          // Mở comment sheet của locket
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _LocketCommentSheetProxy(locketId: nav.id!),
              );
            }
          });
        }
        break;
      case NotifNavType.none:
        break;
    }
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<PostViewModel>().loadPosts();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Lắng nghe pendingScrollToPostId
    final vm = context.watch<PostViewModel>();
    if (vm.pendingScrollToPostId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingScroll());
    }

    // Lắng nghe notification navigation
    final notifVm = context.watch<NotificationViewModel>();
    if (notifVm.pendingNav != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleNotifNav(notifVm));
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF0F2F5),
      body: Column(
        children: [
          _AppBar(isDark: isDark),
          _NavBar(
            selectedIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
          ),
          Expanded(child: _buildBody(isDark)),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    switch (_selectedIndex) {
      case 1:
        return const MyWritePage();
      case 2:
        return const LocketPage();
      case 3:
        return const NotificationPage();
      case 4:
        return const SettingPage();
      default:
        return _FeedView(scrollCtrl: _scrollCtrl, postKeys: _postKeys);
    }
  }
}

// ── APP BAR ───────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final bool isDark;
  const _AppBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final topPad = MediaQuery.of(context).padding.top;
    final bg = isDark ? const Color(0xFF1A2235) : Colors.white;
    final divColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.grey.shade200;

    return Container(
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: topPad),
          // ── Row 1: Logo + name + actions ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 2, 2),
            child: Row(
              children: [
                // UIT logo circle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'UIT Connect',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                          shadows: [
                            Shadow(
                              offset: Offset(0.5, 0.9),
                              blurRadius: 0.5,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // MSSV chip
                const SizedBox(width: 6),
                // Chat
                _AppBarBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  isDark: isDark,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const ConversationListSheet(),
                  ),
                ),
                const SizedBox(width: 4),
                // Theme toggle
                Consumer<ThemeNotifier>(
                  builder: (_, n, __) => _AppBarBtn(
                    icon: n.isDark
                        ? Icons.nightlight_round
                        : Icons.nightlight_outlined,
                    isDark: isDark,
                    onTap: n.toggle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBarBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  const _AppBarBtn({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white70 : Colors.grey[700],
        ),
      ),
    );
  }
}

// ── NAV BAR ───────────────────────────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _NavBar({required this.selectedIndex, required this.onTap});

  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Trang chủ'),
    (Icons.edit_rounded, Icons.edit_outlined, 'Bài viết'),
    (Icons.camera_alt_rounded, Icons.camera_alt_outlined, 'Camera'),
    (Icons.notifications_rounded, Icons.notifications_outlined, 'Thông báo'),
    (Icons.person_rounded, Icons.person_outlined, 'Thông tin'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A2235) : Colors.white;
    final activeColor = const Color(0xFF2563EB);
    final inactiveColor = isDark ? Colors.white38 : Colors.grey[500]!;
    final divColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.grey.shade200;
    final unreadCount = context.watch<NotificationViewModel>().unreadCount;

    return Container(
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: List.generate(_items.length, (i) {
                final active = selectedIndex == i;
                final isNotif = i == 3;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                active ? _items[i].$1 : _items[i].$2,
                                color: active ? activeColor : inactiveColor,
                                size: 26,
                              ),
                              if (isNotif && unreadCount > 0)
                                Positioned(
                                  top: -4,
                                  right: -6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: bg,
                                        width: 1.5,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                    child: Text(
                                      unreadCount > 99 ? '99+' : '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 3,
                          width: active ? 28 : 0,
                          decoration: BoxDecoration(
                            color: activeColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Divider(height: 1, thickness: 1, color: divColor),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── FEED VIEW ─────────────────────────────────────────────────────────────────
class _FeedView extends StatelessWidget {
  final ScrollController scrollCtrl;
  final Map<String, GlobalKey> postKeys;
  const _FeedView({required this.scrollCtrl, required this.postKeys});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vm = context.watch<PostViewModel>();
    final authVm = context.watch<AuthViewModel>();

    return Column(
      children: [
        // ── Create post bar (giống Facebook) ──
        Container(
          color: isDark ? const Color(0xFF1A2235) : Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              // Avatar nhỏ
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              // Fake input — mở create sheet
              Expanded(
                child: GestureDetector(
                  onTap: () => _openCreatePost(context),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${authVm.currentUser?.name ?? 'Bạn'} ơi, bạn đang cần gì?',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white38 : Colors.grey[500],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 8,
          thickness: 8,
          color: isDark ? AppColors.darkBackground : const Color(0xFFE4E6EB),
        ),

        // ── Feed ──
        Expanded(
          child: vm.isLoading && vm.posts.isEmpty
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.uitBlue,
                    strokeWidth: 2.5,
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.uitBlue,
                  backgroundColor: isDark
                      ? AppColors.darkSurface
                      : Colors.white,
                  onRefresh: () =>
                      context.read<PostViewModel>().loadPosts(refresh: true),
                  child: ListView.builder(
                    controller: scrollCtrl,
                    padding: EdgeInsets.zero,
                    itemCount: vm.posts.length + (vm.isLoadingMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == vm.posts.length) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      final post = vm.posts[i];
                      final key = postKeys.putIfAbsent(post.id, () => GlobalKey());
                      return PostCard(key: key, post: post);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _openCreatePost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreatePostSheet(),
    );
  }
}

/// Proxy để mở LocketCommentSheet từ bên ngoài locket_card.dart
class _LocketCommentSheetProxy extends StatefulWidget {
  final String locketId;
  const _LocketCommentSheetProxy({required this.locketId});

  @override
  State<_LocketCommentSheetProxy> createState() => _LocketCommentSheetProxyState();
}

class _LocketCommentSheetProxyState extends State<_LocketCommentSheetProxy> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocketViewModel>().loadComments(widget.locketId);
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A2235) : Colors.white;
    final vm = context.watch<LocketViewModel>();
    final comments = vm.commentsFor(widget.locketId);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_rounded, color: Color(0xFF2563EB), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Bình luận (${comments.length})',
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF050505),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          Expanded(
            child: vm.isLoadingComments
                ? const Center(child: CircularProgressIndicator())
                : comments.isEmpty
                    ? Center(child: Text('Chưa có bình luận nào',
                        style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: comments.length,
                        itemBuilder: (_, i) {
                          final c = comments[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                                    ),
                                  ),
                                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF0F2F5),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.userName,
                                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                                                color: isDark ? Colors.white : const Color(0xFF050505))),
                                        const SizedBox(height: 3),
                                        Text(c.content,
                                            style: TextStyle(fontSize: 14,
                                                color: isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF1C1E21))),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Bình luận...',
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF0F2F5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 38, height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    await context.read<LocketViewModel>().addComment(widget.locketId, text);
  }
}
