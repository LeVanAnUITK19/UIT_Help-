import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../data/models/post_model.dart';
import '../../../../features/viewmodels/post_viewmodel.dart';
import '../../../../features/viewmodels/comment_viewmodel.dart';
import '../../../../features/views/profile/user_profile_page.dart';
import 'comment_sheet.dart';
class PostCard extends StatelessWidget {
  final PostModel post;
  final bool showActions;

  const PostCard({super.key, required this.post, this.showActions = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLost = post.type == 'lost';
    final bg = isDark ? const Color(0xFF1A2235) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDark, isLost),
          if (post.description.isNotEmpty) _buildCaption(isDark),
          _buildInfoChips(isDark),
          if (post.imageUrl.isNotEmpty) _buildImage(),
          _buildActionBar(context, isDark),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.shade100,
          ),
        ],
      ),
    );
  }

  // ── HEADER (giống Facebook: avatar + tên + thời gian + badge + menu) ────────
  Widget _buildHeader(BuildContext context, bool isDark, bool isLost) {
    final nameColor = isDark ? Colors.white : const Color(0xFF050505);
    final timeColor = isDark ? Colors.white38 : Colors.grey[500]!;
    final badgeColor = isLost
        ? const Color(0xFFEF4444)
        : const Color(0xFF22C55E);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.uitBlue, AppColors.slateBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              // online dot
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1A2235) : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // Name + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _openProfile(context),
                  child: Text(
                    post.userName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: nameColor,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 11, color: timeColor),
                    const SizedBox(width: 3),
                    Text(
                      formatTimeSmart(post.createdAt),
                      style: TextStyle(fontSize: 11, color: timeColor),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.public_rounded, size: 11, color: timeColor),
                  ],
                ),
              ],
            ),
          ),
          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isLost ? '🔍 Lost' : '✅ Found',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // More menu
          if (showActions)
            _moreMenu(context, isDark)
          else
            IconButton(
              icon: Icon(
                Icons.more_horiz,
                color: isDark ? Colors.white38 : Colors.grey[500],
              ),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
        ],
      ),
    );
  }

  // ── CAPTION (mô tả) ─────────────────────────────────────────────────────────
  Widget _buildCaption(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Text(
        post.description,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          color: isDark
              ? Colors.white.withOpacity(0.85)
              : const Color(0xFF1C1E21),
          height: 1.5,
        ),
      ),
    );
  }

  // ── INFO CHIPS (title, location, contact) ───────────────────────────────────
  Widget _buildInfoChips(bool isDark) {
    final chips = <_ChipData>[];
    if (post.title.isNotEmpty)
      chips.add(
        _ChipData(Icons.label_outline_rounded, post.title, AppColors.uitBlue),
      );
    if (post.location.isNotEmpty)
      chips.add(
        _ChipData(
          Icons.location_on_outlined,
          post.location,
          const Color(0xFFEF4444),
        ),
      );
    if (post.contact.isNotEmpty)
      chips.add(
        _ChipData(Icons.phone_outlined, post.contact, const Color(0xFF22C55E)),
      );

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: chips.map((c) => _infoChip(c, isDark)).toList(),
      ),
    );
  }

  Widget _infoChip(_ChipData c, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(c.icon, size: 13, color: c.color),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              c.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: c.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── IMAGE (full width, giống Facebook) ──────────────────────────────────────
  Widget _buildImage() {
    return Image.network(
      post.imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          height: 200,
          color: const Color(0xFFF1F5F9),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }

  // ── ACTION BAR (giống Facebook: Bình luận + Trạng thái) ─────────────────────
  Widget _buildActionBar(BuildContext context, bool isDark) {
    final iconColor = isDark ? Colors.white54 : Colors.grey[600]!;
    // lấy count local từ CommentViewModel nếu đã load, fallback về post.commentCount
    final commentVm = context.watch<CommentViewModel>();
    final localComments = commentVm.commentsFor(post.id);
    final count = localComments.isNotEmpty
        ? localComments.length
        : post.commentCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _actionBtn(
            context,
            icon: Icons.chat_bubble_outline_rounded,
            label: count > 0 ? '$count Bình luận' : 'Bình luận',
            color: iconColor,
            onTap: () => _openComments(context),
          ),
          const Spacer(),
          _statusBadge(post.status),
        ],
      ),
    );
  }

  Widget _actionBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'searching':
        color = const Color(0xFFEF4444);
        label = 'Đang tìm';
        break;
      case 'found':
        color = const Color(0xFF22C55E);
        label = 'Đã tìm thấy';
        break;
      case 'unclaimed':
        color = AppColors.uitBlue;
        label = 'Chưa nhận';
        break;
      case 'claimed':
        color = const Color(0xFF22C55E);
        label = 'Đã nhận';
        break;
      case 'closed':
        color = Colors.grey;
        label = 'Đã đóng';
        break;
      default:
        color = Colors.orange;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5), width: 1.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _moreMenu(BuildContext context, bool isDark) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        color: isDark ? Colors.white38 : Colors.grey[500],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      onSelected: (val) => _handleMenu(context, val),
      itemBuilder: (_) => [
        if (post.matches.isNotEmpty)
          PopupMenuItem(
            value: 'matches',
            child: Row(
              children: [
                const Icon(Icons.link_rounded, size: 18, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Text('Bài viết liên quan (${post.matches.length})'),
              ],
            ),
          ),
        const PopupMenuItem(value: 'delete', child: Text('Xóa bài')),
        const PopupMenuItem(value: 'searching', child: Text('Đang tìm')),
        const PopupMenuItem(value: 'found', child: Text('Đã tìm thấy')),
        const PopupMenuItem(value: 'closed', child: Text('Đóng')),
      ],
    );
  }

  void _handleMenu(BuildContext context, String action) async {
    if (action == 'matches') {
      _showMatchesSheet(context);
      return;
    }
    final vm = context.read<PostViewModel>();
    if (action == 'delete') {
      final ok = await vm.deletePost(post.id);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(vm.errorMessage ?? 'Lỗi')));
      }
    } else {
      await vm.updateStatus(post.id, action);
    }
  }

  void _showMatchesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MatchesSheet(matches: post.matches),
    );
  }

  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentSheet(postId: post.id),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfilePage(userId: post.userId, knownName: post.userName),
      ),
    );
  }

  String formatTimeSmart(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    // 🔥 Nếu quá 7 ngày → format cũ
    if (diff.inDays >= 7) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} '
          '${dt.day}/${dt.month}/${dt.year}';
    }

    // < 1 phút
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s trước';
    }

    // < 1 giờ
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}p trước';
    }

    // < 1 ngày
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      return minutes == 0 ? '${hours}h trước' : '${hours}h ${minutes}p trước';
    }

    // < 7 ngày
    final days = diff.inDays;
    final hours = diff.inHours % 24;

    return hours == 0 ? '${days} ngày trước' : '${days} ngày ${hours}h trước';
  }
}

class _ChipData {
  final IconData icon;
  final String label;
  final Color color;
  const _ChipData(this.icon, this.label, this.color);
}

// ── MATCHES BOTTOM SHEET ──────────────────────────────────────────────────────
class _MatchesSheet extends StatelessWidget {
  final List<MatchedPostModel> matches;
  const _MatchesSheet({required this.matches});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A2235) : Colors.white;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.link_rounded, color: Color(0xFF2563EB), size: 20),
              const SizedBox(width: 8),
              Text(
                'Bài viết liên quan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${matches.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: matches.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark ? Colors.white12 : Colors.grey.shade100,
              ),
              itemBuilder: (_, i) => _MatchTile(match: matches[i], isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final MatchedPostModel match;
  final bool isDark;
  const _MatchTile({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isLost = match.type == 'lost';
    final typeColor = isLost ? const Color(0xFFEF4444) : const Color(0xFF22C55E);
    final scoreColor = match.score >= 70
        ? const Color(0xFF22C55E)
        : match.score >= 50
            ? const Color(0xFFF59E0B)
            : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // thumbnail hoặc placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: match.imageUrl.isNotEmpty
                ? Image.network(
                    match.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isLost ? 'Lost' : 'Found',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // score badge
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 12, color: scoreColor),
                        const SizedBox(width: 3),
                        Text(
                          '${match.score}đ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scoreColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  match.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF050505),
                  ),
                ),
                if (match.location.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 12,
                          color: isDark ? Colors.white38 : Colors.grey[500]),
                      const SizedBox(width: 3),
                      Text(
                        match.location,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
                if (match.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    match.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showDetail(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                      ),
                    ),
                    child: const Text(
                      'Xem chi tiết',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    // Đóng tất cả sheet, switch về Home tab, scroll đến post
    context.read<PostViewModel>().requestScrollToPost(match.id);
    // Đóng hết các sheet đang mở (matches sheet + bất kỳ sheet nào phía trên)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _placeholder() {
    return Container(
      width: 60,
      height: 60,
      color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
      child: Icon(
        Icons.image_outlined,
        color: isDark ? Colors.white24 : Colors.grey.shade400,
        size: 28,
      ),
    );
  }
}

// ── MATCH DETAIL SHEET ────────────────────────────────────────────────────────
class _MatchDetailSheet extends StatefulWidget {
  final MatchedPostModel match;
  final bool isDark;
  const _MatchDetailSheet({required this.match, required this.isDark});

  @override
  State<_MatchDetailSheet> createState() => _MatchDetailSheetState();
}

class _MatchDetailSheetState extends State<_MatchDetailSheet> {
  PostModel? _post;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final vm = context.read<PostViewModel>();
    final result = await vm.getPostById(widget.match.id);
    if (mounted) {
      setState(() {
        _post = result;
        _error = result == null ? 'Không tải được bài viết' : null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF1A2235) : Colors.white;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _loading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : _error != null
              ? SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(_error!,
                        style: TextStyle(color: cs.error)),
                  ),
                )
              : _buildContent(context, cs),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme cs) {
    final post = _post!;
    final isDark = widget.isDark;
    final isLost = post.type == 'lost';
    final typeColor = isLost ? const Color(0xFFEF4444) : const Color(0xFF22C55E);
    final scoreColor = widget.match.score >= 70
        ? const Color(0xFF22C55E)
        : widget.match.score >= 50
            ? const Color(0xFFF59E0B)
            : const Color(0xFF6B7280);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // image
          if (post.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                post.imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 14),
          // type + score row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isLost ? '🔍 Lost' : '✅ Found',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scoreColor.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 14, color: scoreColor),
                    const SizedBox(width: 4),
                    Text(
                      'Độ khớp: ${widget.match.score}đ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // title
          Text(
            post.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          if (post.location.isNotEmpty)
            _infoRow(Icons.location_on_outlined, post.location,
                const Color(0xFFEF4444), isDark),
          if (post.contact.isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow(Icons.phone_outlined, post.contact,
                const Color(0xFF22C55E), isDark),
          ],
          if (post.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow(Icons.notes_rounded, post.description,
                AppColors.uitBlue, isDark),
          ],
          const SizedBox(height: 8),
          _infoRow(Icons.person_outline_rounded, post.userName,
              const Color(0xFF6B7280), isDark),
          const SizedBox(height: 8),
          _infoRow(Icons.access_time_rounded,
              _formatTime(post.createdAt), const Color(0xFF6B7280), isDark),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : const Color(0xFF374151),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
