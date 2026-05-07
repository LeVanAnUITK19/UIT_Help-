import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../features/viewmodels/auth_viewmodel.dart';
import '../../../features/viewmodels/conversation_viewmodel.dart';
import '../chat/message_page.dart';

class UserProfilePage extends StatefulWidget {
  /// Truyền userId để fetch, hoặc truyền thẳng user nếu đã có
  final String userId;
  final String? knownName; // tên hiển thị tạm trong khi load

  const UserProfilePage({super.key, required this.userId, this.knownName});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  UserModel? _user;
  bool _loading = true;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await context.read<ConversationViewModel>().getUserById(widget.userId);
    if (mounted) setState(() { _user = user; _loading = false; });
  }

  Future<void> _openChat() async {
    if (_navigating) return;
    setState(() => _navigating = true);
    final vm = context.read<ConversationViewModel>();
    final conv = await vm.getOrCreate(widget.userId);
    setState(() => _navigating = false);
    if (conv != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MessagePage(
            conversation: conv,
            otherUserName: _user?.name ?? widget.knownName ?? '...',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFEAEEF6);
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final dividerColor = isDark ? AppColors.darkDivider : const Color(0xFFE2E8F0);
    final myId = context.read<AuthViewModel>().currentUser?.id ?? '';
    final isMe = widget.userId == myId;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _user?.name ?? widget.knownName ?? '...',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.uitBlue, strokeWidth: 2.5))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    color: bgColor,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.darkDivider : Colors.grey.shade300,
                              width: 1.5,
                            ),
                            color: cardColor,
                          ),
                          child: Center(
                            child: Text(
                              (_user?.name.isNotEmpty == true)
                                  ? _user!.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.uitBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _user?.name ?? '—',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Info card ────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.uitBlue.withOpacity(0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                            child: Text(
                              'Thông tin',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          _InfoRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Tên người dùng',
                            value: _user?.name ?? '—',
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            dividerColor: dividerColor,
                          ),
                          _InfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: _user?.email ?? '—',
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            dividerColor: dividerColor,
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Chat button (chỉ hiện nếu không phải mình) ───────────
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _navigating ? null : _openChat,
                          icon: _navigating
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.chat_bubble_rounded, size: 20),
                          label: const Text(
                            'Nhắn tin',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.uitBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;
  final Color dividerColor;
  final bool showDivider;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
    required this.dividerColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 11, color: textSecondary)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: dividerColor, indent: 48),
      ],
    );
  }
}
