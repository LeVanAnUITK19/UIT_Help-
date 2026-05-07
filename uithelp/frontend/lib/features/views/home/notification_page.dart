import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_colors.dart';
import '../../../data/models/notification_model.dart';
import '../../viewmodels/notification_viewmodel.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationViewModel>().load(refresh: true);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<NotificationViewModel>().load();
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
    final vm = context.watch<NotificationViewModel>();
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final headerBg = isDark ? const Color(0xFF1A2235) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: headerBg,
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            children: [
              Text('Thông báo',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary)),
              const Spacer(),
              if (vm.unreadCount > 0)
                TextButton(
                  onPressed: vm.markAllAsRead,
                  child: const Text('Đọc tất cả',
                      style: TextStyle(fontSize: 13, color: AppColors.uitBlue, fontWeight: FontWeight.w500)),
                ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded, color: textSecondary),
                onSelected: (v) { if (v == 'delete_all') vm.deleteAll(); },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete_all',
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Xóa tất cả'),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: vm.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.uitBlue, strokeWidth: 2.5))
              : vm.notifications.isEmpty
                  ? _EmptyState(textSecondary: textSecondary)
                  : RefreshIndicator(
                      color: AppColors.uitBlue,
                      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                      onRefresh: () => vm.load(refresh: true),
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        padding: EdgeInsets.zero,
                        itemCount: vm.notifications.length + (vm.isLoadingMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == vm.notifications.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          }
                          final n = vm.notifications[i];
                          return _NotifTile(
                            notif: n,
                            isDark: isDark,
                            onTap: () => vm.tapNotification(n),
                            onDelete: () => vm.deleteNotification(n.id),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color textSecondary;
  const _EmptyState({required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded, size: 64, color: textSecondary.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text('Chưa có thông báo nào', style: TextStyle(fontSize: 15, color: textSecondary)),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotifTile({
    required this.notif,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final unreadBg = isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE8F0FE);
    final readBg = isDark ? AppColors.darkBackground : const Color(0xFFF0F2F5);
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: notif.isRead ? readBg : unreadBg,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _iconBg(notif.type)),
                child: Icon(_iconData(notif.type), color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: notif.isRead ? FontWeight.w400 : FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    if (notif.message != null && notif.message!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(notif.message!,
                          style: TextStyle(fontSize: 13, color: textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(notif.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: notif.isRead ? textSecondary : AppColors.uitBlue,
                        fontWeight: notif.isRead ? FontWeight.w400 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notif.isRead)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 8),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.uitBlue),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconData(String type) {
    switch (type) {
      case 'match': return Icons.search_rounded;
      case 'comment': return Icons.chat_bubble_rounded;
      case 'reaction': return Icons.favorite_rounded;
      case 'ride_join': return Icons.directions_car_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _iconBg(String type) {
    switch (type) {
      case 'match': return AppColors.uitBlue;
      case 'comment': return AppColors.success;
      case 'reaction': return AppColors.error;
      case 'ride_join': return AppColors.warning;
      default: return AppColors.lightTextSecondary;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
