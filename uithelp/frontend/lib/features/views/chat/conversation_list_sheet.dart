import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../data/models/conversation_model.dart';
import '../../../features/viewmodels/auth_viewmodel.dart';
import '../../../features/viewmodels/conversation_viewmodel.dart';
import 'message_page.dart';

class ConversationListSheet extends StatefulWidget {
  const ConversationListSheet({super.key});

  @override
  State<ConversationListSheet> createState() => _ConversationListSheetState();
}

class _ConversationListSheetState extends State<ConversationListSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversationViewModel>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A2235) : const Color(0xFFEAEEF6);
    final cardBg = isDark ? const Color(0xFF1E2D4A) : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final vm = context.watch<ConversationViewModel>();
    final myId = context.read<AuthViewModel>().currentUser?.id ?? '';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Danh sách tin nhắn',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // List
          Expanded(
            child: vm.isLoadingConvs
                ? const Center(child: CircularProgressIndicator(color: AppColors.uitBlue, strokeWidth: 2.5))
                : vm.conversations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 56,
                                color: textSecondary.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text('Chưa có cuộc trò chuyện nào',
                                style: TextStyle(color: textSecondary)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.uitBlue,
                        onRefresh: () => vm.loadConversations(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: vm.conversations.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: isDark ? Colors.white12 : Colors.grey.shade200,
                            indent: 72,
                          ),
                          itemBuilder: (_, i) => _ConvTile(
                            conv: vm.conversations[i],
                            myId: myId,
                            cardBg: cardBg,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ConvTile extends StatefulWidget {
  final ConversationModel conv;
  final String myId;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _ConvTile({
    required this.conv,
    required this.myId,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  State<_ConvTile> createState() => _ConvTileState();
}

class _ConvTileState extends State<_ConvTile> {
  String _otherName = '...';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final otherId = widget.conv.otherParticipant(widget.myId);
    if (otherId.isEmpty) return;
    final user = await context.read<ConversationViewModel>().getUserById(otherId);
    if (mounted && user != null) setState(() => _otherName = user.name);
  }

  @override
  Widget build(BuildContext context) {
    final unread = widget.conv.unreadFor(widget.myId);
    final hasUnread = unread > 0;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MessagePage(
              conversation: widget.conv,
              otherUserName: _otherName,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48, height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                ),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otherName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                      color: widget.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.conv.lastMessage.isEmpty
                        ? 'Bắt đầu cuộc trò chuyện'
                        : widget.conv.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: hasUnread ? AppColors.uitBlue : widget.textSecondary,
                      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Time + unread badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(widget.conv.lastMessageAt),
                  style: TextStyle(fontSize: 11, color: widget.textSecondary),
                ),
                const SizedBox(height: 4),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes}p';
    if (diff.inDays < 1) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${dt.day}/${dt.month}';
  }
}
