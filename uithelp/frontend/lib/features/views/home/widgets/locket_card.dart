import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uithelp/core/themes/app_theme.dart';
import 'package:uithelp/data/models/locket_model.dart';
import 'package:uithelp/features/viewmodels/locket_viewmodel.dart';
import 'package:uithelp/features/views/profile/user_profile_page.dart';

class LocketCard extends StatefulWidget {
  final LocketModel locket;
  final bool isActive;
  final bool showActions;

  const LocketCard({
    super.key,
    required this.locket,
    this.isActive = true,
    this.showActions = false,
  });

  @override
  State<LocketCard> createState() => _LocketCardState();
}

class _LocketCardState extends State<LocketCard> {
  final _commentCtrl = TextEditingController();
  // Key để lấy vị trí của reaction row
  final _reactionRowKey = GlobalKey();
  // Danh sách các emoji đang bay
  final List<_FloatingEmoji> _floatingEmojis = [];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _triggerFloatEmoji(String emoji) {
    final id = DateTime.now().microsecondsSinceEpoch;
    final rand = Random();
    setState(() {
      _floatingEmojis.add(_FloatingEmoji(
        id: id,
        emoji: emoji,
        // random x offset nhẹ để nhiều emoji không chồng nhau
        xOffset: (rand.nextDouble() - 0.5) * 60,
      ));
    });
    // Xóa sau khi animation xong
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _floatingEmojis.removeWhere((e) => e.id == id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A2235) : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Card chính ──────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImage(context, isDark),
                _buildAuthorRow(isDark),
                _buildReactions(context),
                _buildCommentInput(context, isDark),
                const SizedBox(height: 12),
              ],
            ),
          ),
          // ── Floating emojis ─────────────────────────────────────────────
          ..._floatingEmojis.map((fe) => _FloatingEmojiWidget(
            key: ValueKey(fe.id),
            emoji: fe.emoji,
            xOffset: fe.xOffset,
          )),
        ],
      ),
    );
  }

  // ── IMAGE ──────────────────────────────────────────────────────────────────
  Widget _buildImage(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _openFullImage(context),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Stack(
          children: [
            Image.network(
              widget.locket.imageUrl,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 300,
                color: const Color(0xFFF1F5F9),
                child: const Center(
                  child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                ),
              ),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 300,
                  color: const Color(0xFFF1F5F9),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              },
            ),
            // Caption overlay
            if (widget.locket.caption != null && widget.locket.caption!.isNotEmpty)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 32, 14, 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Text(
                    widget.locket.caption!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            // More menu (chỉ khi showActions)
            if (widget.showActions)
              Positioned(
                top: 10, right: 10,
                child: _moreMenu(context, isDark),
              ),
          ],
        ),
      ),
    );
  }

  // ── AUTHOR ROW ─────────────────────────────────────────────────────────────
  Widget _buildAuthorRow(bool isDark) {
    final nameColor = isDark ? Colors.white : const Color(0xFF050505);
    final timeColor = isDark ? Colors.white38 : Colors.grey[500]!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
              ),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfilePage(
                    userId: widget.locket.userId,
                    knownName: widget.locket.userName,
                  ),
                ),
              ),
              child: Text(
                widget.locket.userName,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: nameColor),
              ),
            ),
          ),
          Text(
            _formatTime(widget.locket.createdAt),
            style: TextStyle(fontSize: 12, color: timeColor),
          ),
        ],
      ),
    );
  }

  // ── REACTIONS ──────────────────────────────────────────────────────────────
  Widget _buildReactions(BuildContext context) {
    final vm = context.watch<LocketViewModel>();
    final myReaction = vm.myReactionFor(widget.locket.id);

    return Padding(
      key: _reactionRowKey,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ReactionButton(
            emoji: '👍', type: 'like', isActive: myReaction == 'like',
            onTap: () {
              context.read<LocketViewModel>().reactLocket(widget.locket.id, 'like');
              if (myReaction != 'like') _triggerFloatEmoji('👍');
            },
          ),
          _ReactionButton(
            emoji: '❤️', type: 'heart', isActive: myReaction == 'heart',
            onTap: () {
              context.read<LocketViewModel>().reactLocket(widget.locket.id, 'heart');
              if (myReaction != 'heart') _triggerFloatEmoji('❤️');
            },
          ),
          _ReactionButton(
            emoji: '😊', type: 'smile', isActive: myReaction == 'smile',
            onTap: () {
              context.read<LocketViewModel>().reactLocket(widget.locket.id, 'smile');
              if (myReaction != 'smile') _triggerFloatEmoji('😊');
            },
          ),
          _ReactionButton(
            emoji: '😢', type: 'sad', isActive: myReaction == 'sad',
            onTap: () {
              context.read<LocketViewModel>().reactLocket(widget.locket.id, 'sad');
              if (myReaction != 'sad') _triggerFloatEmoji('😢');
            },
          ),
        ],
      ),
    );
  }

  // ── COMMENT INPUT ──────────────────────────────────────────────────────────
  Widget _buildCommentInput(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openComments(context),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.07)
                      : const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bạn đang nghĩ gì ?',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.grey[500],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _openComments(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.07)
                    : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.send_rounded,
                size: 18,
                color: AppColors.uitBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── MORE MENU ──────────────────────────────────────────────────────────────
  Widget _moreMenu(BuildContext context, bool isDark) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.more_horiz, color: Colors.white, size: 18),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      onSelected: (val) => _handleMenu(context, val),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'reactions',
          child: Row(children: [
            Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 18),
            SizedBox(width: 10),
            Text('Xem lượt thả tim'),
          ]),
        ),
        const PopupMenuItem(
          value: 'comments',
          child: Row(children: [
            Icon(Icons.chat_bubble_rounded, color: Color(0xFF2563EB), size: 18),
            SizedBox(width: 10),
            Text('Xem bình luận'),
          ]),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
            SizedBox(width: 10),
            Text('Xóa locket', style: TextStyle(color: Color(0xFFEF4444))),
          ]),
        ),
      ],
    );
  }

  void _handleMenu(BuildContext context, String action) {
    if (action == 'delete') {
      _confirmDelete(context);
    } else if (action == 'reactions') {
      _openReactions(context);
    } else if (action == 'comments') {
      _openComments(context);
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa locket?'),
        content: const Text('Locket này sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final vm = context.read<LocketViewModel>();
              final ok = await vm.deleteLocket(widget.locket.id);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(vm.errorMessage ?? 'Xóa thất bại')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  void _openReactions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReactionsSheet(locketId: widget.locket.id),
    );
  }

  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocketCommentSheet(locketId: widget.locket.id),
    );
  }

  void _openFullImage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullImagePage(imageUrl: widget.locket.imageUrl),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }
}


// ── FLOATING EMOJI DATA ───────────────────────────────────────────────────────
class _FloatingEmoji {
  final int id;
  final String emoji;
  final double xOffset;
  const _FloatingEmoji({required this.id, required this.emoji, required this.xOffset});
}

// ── FLOATING EMOJI WIDGET ─────────────────────────────────────────────────────
class _FloatingEmojiWidget extends StatefulWidget {
  final String emoji;
  final double xOffset;
  const _FloatingEmojiWidget({super.key, required this.emoji, required this.xOffset});

  @override
  State<_FloatingEmojiWidget> createState() => _FloatingEmojiWidgetState();
}

class _FloatingEmojiWidgetState extends State<_FloatingEmojiWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _y;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _y = Tween<double>(begin: 0, end: -220).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 35),
    ]).animate(_ctrl);
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.3), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 65),
    ]).animate(_ctrl);

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // Đặt ở giữa bottom của card, trên reaction row
      bottom: 60,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.translate(
          offset: Offset(widget.xOffset, _y.value),
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Center(
                child: Text(widget.emoji, style: const TextStyle(fontSize: 36)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── REACTION BUTTON ───────────────────────────────────────────────────────────
class _ReactionButton extends StatefulWidget {
  final String emoji;
  final String type;
  final bool isActive;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.emoji,
    required this.type,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<_ReactionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = Tween(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _ctrl.reverse().then((_) => _ctrl.forward());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 62,
          height: 48,
          decoration: BoxDecoration(
            // Active: gradient nhẹ theo màu emoji
            gradient: widget.isActive
                ? LinearGradient(
                    colors: [
                      _activeColor(widget.type).withOpacity(0.18),
                      _activeColor(widget.type).withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.isActive ? null : Colors.grey.withOpacity(0.09),
            borderRadius: BorderRadius.circular(16),
            border: widget.isActive
                ? Border.all(
                    color: _activeColor(widget.type).withOpacity(0.5),
                    width: 1.5,
                  )
                : Border.all(color: Colors.transparent, width: 1.5),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: _activeColor(widget.type).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              widget.emoji,
              style: TextStyle(fontSize: widget.isActive ? 26 : 22),
            ),
          ),
        ),
      ),
    );
  }

  Color _activeColor(String type) {
    switch (type) {
      case 'heart': return const Color(0xFFEF4444);
      case 'smile': return const Color(0xFFF59E0B);
      case 'sad':   return const Color(0xFF3B82F6);
      default:      return const Color(0xFF2563EB); // like
    }
  }
}


class _ReactionsSheet extends StatefulWidget {
  final String locketId;
  const _ReactionsSheet({required this.locketId});

  @override
  State<_ReactionsSheet> createState() => _ReactionsSheetState();
}

class _ReactionsSheetState extends State<_ReactionsSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocketViewModel>().loadReactions(widget.locketId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A2235) : Colors.white;
    final vm = context.watch<LocketViewModel>();
    final reactions = vm.reactionsFor(widget.locketId);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Lượt thả tim (${reactions.length})',
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF050505),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (vm.isLoadingReactions)
            const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())
          else if (reactions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text('Chưa có ai thả tim', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: reactions.length,
                itemBuilder: (_, i) {
                  final r = reactions[i];
                  return ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)]),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      r.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF050505),
                      ),
                    ),
                    trailing: Text(
                      r.type == 'heart' ? '❤️' : r.type == 'like' ? '👍' : r.type == 'smile' ? '😊' : '😢',
                      style: const TextStyle(fontSize: 20),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── LOCKET COMMENT SHEET ──────────────────────────────────────────────────────
class _LocketCommentSheet extends StatefulWidget {
  final String locketId;
  const _LocketCommentSheet({required this.locketId});

  @override
  State<_LocketCommentSheet> createState() => _LocketCommentSheetState();
}

class _LocketCommentSheetState extends State<_LocketCommentSheet> {
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
                    ? Center(
                        child: Text(
                          'Chưa có bình luận nào',
                          style: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                        ),
                      )
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
                                      color: isDark
                                          ? Colors.white.withOpacity(0.06)
                                          : const Color(0xFFF0F2F5),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              c.userName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: isDark ? Colors.white : const Color(0xFF050505),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _formatTimeSmart(c.createdAt),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isDark ? Colors.white38 : Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          c.content,
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
                        },
                      ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: bg,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    onSubmitted: (_) => _send(context),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _send(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]),
                    ),
                    child: vm.isSendingComment
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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

  void _send(BuildContext context) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    await context.read<LocketViewModel>().addComment(widget.locketId, text);
  }

  String _formatTimeSmart(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s trước';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p trước';
    if (diff.inHours < 24) return '${diff.inHours}h trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── FULL IMAGE PAGE ───────────────────────────────────────────────────────────
class _FullImagePage extends StatelessWidget {
  final String imageUrl;
  const _FullImagePage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
