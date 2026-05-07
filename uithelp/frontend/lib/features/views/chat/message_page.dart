import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/token_storage.dart';
import '../../../core/themes/app_colors.dart';
import '../../../data/models/conversation_model.dart';
import '../../../features/viewmodels/auth_viewmodel.dart';
import '../../../features/viewmodels/conversation_viewmodel.dart';

class MessagePage extends StatefulWidget {
  final ConversationModel conversation;
  final String otherUserName;

  const MessagePage({
    super.key,
    required this.conversation,
    required this.otherUserName,
  });

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  String? _myId;

  @override
  void initState() {
    super.initState();
    _myId = context.read<AuthViewModel>().currentUser?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<ConversationViewModel>();
      await vm.loadMessages(widget.conversation.id, refresh: true);
      _scrollToBottom();

      // Connect socket
      final token = await TokenStorage().getAccessToken();
      if (token != null && mounted) {
        vm.connectSocket(widget.conversation.id, token);
      }

      // Mark as read
      if (_myId != null) {
        vm.markRead(widget.conversation.id, _myId!);
      }
    });

    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    // Load more khi scroll lên đầu
    if (_scrollCtrl.position.pixels <= 100) {
      context.read<ConversationViewModel>().loadMessages(widget.conversation.id);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    context.read<ConversationViewModel>().disconnectSocket();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    final vm = context.read<ConversationViewModel>();
    await vm.sendMessage(widget.conversation.id, text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : const Color(0xFFF0F2F5);
    final appBarBg = isDark ? const Color(0xFF1A2235) : Colors.white;
    final vm = context.watch<ConversationViewModel>();
    final messages = vm.messagesFor(widget.conversation.id);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
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
            Text(
              widget.otherUserName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: vm.isLoadingMsgs && messages.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.uitBlue, strokeWidth: 2.5))
                : messages.isEmpty
                    ? Center(
                        child: Text(
                          'Hãy bắt đầu cuộc trò chuyện!',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: messages.length,
                        itemBuilder: (_, i) {
                          final msg = messages[i];
                          final isMe = msg.senderId == _myId;
                          final showAvatar = !isMe &&
                              (i == 0 || messages[i - 1].senderId != msg.senderId);
                          return _MessageBubble(
                            msg: msg,
                            isMe: isMe,
                            showAvatar: showAvatar,
                            otherName: widget.otherUserName,
                            isDark: isDark,
                            onLongPress: isMe
                                ? () => _confirmDelete(context, msg.id)
                                : null,
                          );
                        },
                      ),
          ),
          // Input bar
          _InputBar(
            controller: _inputCtrl,
            focusNode: _focusNode,
            isSending: vm.isSending,
            isDark: isDark,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String msgId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A2235)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              title: const Text('Xóa tin nhắn', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                context.read<ConversationViewModel>()
                    .deleteMessage(widget.conversation.id, msgId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: const Text('Hủy'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  final bool showAvatar;
  final String otherName;
  final bool isDark;
  final VoidCallback? onLongPress;

  const _MessageBubble({
    required this.msg,
    required this.isMe,
    required this.showAvatar,
    required this.otherName,
    required this.isDark,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe
        ? AppColors.uitBlue
        : (isDark ? const Color(0xFF1E2D4A) : Colors.white);
    final textColor = isMe
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    final timeColor = isMe
        ? Colors.white60
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar người kia
          if (!isMe) ...[
            if (showAvatar)
              Container(
                width: 32, height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF64748B), Color(0xFF475569)],
                  ),
                ),
                child: Center(
                  child: Text(
                    otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              )
            else
              const SizedBox(width: 32),
            const SizedBox(width: 8),
          ],

          // Bubble
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.68,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(msg.content, style: TextStyle(fontSize: 14, color: textColor, height: 1.4)),
                    const SizedBox(height: 3),
                    Text(
                      _formatTime(msg.createdAt),
                      style: TextStyle(fontSize: 10, color: timeColor),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Input Bar ─────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final bool isDark;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.isDark,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A2235) : Colors.white;

    return Container(
      color: bg,
      padding: EdgeInsets.only(
        left: 12, right: 12, top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Nhắn tin...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey[500],
                  fontSize: 14,
                ),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFF0F2F5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSending
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                      ),
                color: isSending ? Colors.grey.shade300 : null,
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
