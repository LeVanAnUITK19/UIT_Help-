import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../features/viewmodels/comment_viewmodel.dart';
import '../../../../features/viewmodels/auth_viewmodel.dart';
import '../../../../features/views/profile/user_profile_page.dart';

class CommentSheet extends StatefulWidget {
  final String postId;
  const CommentSheet({super.key, required this.postId});

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<CommentViewModel>();
      vm.connectSocket(widget.postId);
      vm.loadComments(widget.postId, refresh: true);
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    context.read<CommentViewModel>().disconnectSocket(widget.postId);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A2235) : Colors.white;
    final vm = context.watch<CommentViewModel>();
    final authVm = context.read<AuthViewModel>();
    final currentUserId = authVm.currentUser?.id ?? '';
    final comments = vm.commentsFor(widget.postId);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          // ── Handle ────────────────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Title ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_rounded, color: Color(0xFF2563EB), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Bình luận (${comments.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF050505),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20),

          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : comments.isEmpty
                    ? Center(
                        child: Text(
                          'Chưa có bình luận nào',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: comments.length,
                        itemBuilder: (_, i) {
                          final c = comments[i];
                          final isMe = c.userId == currentUserId;
                          return _CommentItem(
                            userName: c.userName,
                            userId: c.userId,
                            content: c.content,
                            createdAt: c.createdAt,
                            isMe: isMe,
                            onDelete: isMe
                                ? () => vm.deleteComment(widget.postId, c.id)
                                : null,
                            isDark: isDark,
                          );
                        },
                      ),
          ),

          // ── Input ─────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: bg,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.grey.shade200,
                ),
              ),
            ),
            child: Row(
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
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Bạn đang nghĩ gì ?',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey[500],
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.06)
                          : const Color(0xFFF0F2F5),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1C1E21),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
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
                      gradient: LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                      ),
                    ),
                    child: vm.isSending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
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
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await context.read<CommentViewModel>().sendComment(widget.postId, text);
  }
}

// ── COMMENT ITEM ──────────────────────────────────────────────────────────────
class _CommentItem extends StatelessWidget {
  final String userName;
  final String userId;
  final String content;
  final DateTime createdAt;
  final bool isMe;
  final VoidCallback? onDelete;
  final bool isDark;

  const _CommentItem({
    required this.userName,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.isMe,
    required this.isDark,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isMe
                    ? [const Color(0xFF2563EB), const Color(0xFF4F46E5)]
                    : [const Color(0xFF64748B), const Color(0xFF475569)],
              ),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          // Bubble
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.uitBlue.withOpacity(isDark ? 0.2 : 0.08)
                    : (isDark
                        ? Colors.white.withOpacity(0.06)
                        : const Color(0xFFF0F2F5)),
                borderRadius: BorderRadius.circular(14),
                border: isMe
                    ? Border.all(
                        color: AppColors.uitBlue.withOpacity(0.25),
                        width: 1,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: isMe ? null : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfilePage(userId: userId, knownName: userName),
                          ),
                        ),
                        child: Text(
                          userName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF050505),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.grey[500],
                        ),
                      ),
                      if (isMe && onDelete != null) ...[
                        const Spacer(),
                        GestureDetector(
                          onTap: onDelete,
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 15,
                            color: isDark ? Colors.white30 : Colors.grey[400],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white.withOpacity(0.85)
                          : const Color(0xFF1C1E21),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s trước';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p trước';
    if (diff.inHours < 24) return '${diff.inHours}h trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
