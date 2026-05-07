import 'package:flutter/material.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

// Loại navigate khi nhấn thông báo
enum NotifNavType { post, locket, none }

class NotifNavIntent {
  final NotifNavType type;
  final String? id; // postId hoặc locketId
  const NotifNavIntent(this.type, this.id);
}

class NotificationViewModel extends ChangeNotifier {
  final NotificationRepository _repo;
  NotificationViewModel(this._repo);

  List<NotificationModel> notifications = [];
  int unreadCount = 0;
  bool isLoading = false;
  bool isLoadingMore = false;
  int _page = 1;
  bool hasMore = true;

  // Pending navigation — HomePage lắng nghe và xử lý
  NotifNavIntent? pendingNav;

  void clearPendingNav() {
    pendingNav = null;
  }

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      hasMore = true;
      notifications = [];
    }
    if (!hasMore) return;
    if (_page == 1) {
      isLoading = true;
      notifyListeners();
    } else {
      isLoadingMore = true;
      notifyListeners();
    }
    try {
      final result = await _repo.getNotifications(page: _page);
      if (result.length < 20) hasMore = false;
      notifications = [...notifications, ...result];
      _page++;
    } catch (_) {}
    isLoading = false;
    isLoadingMore = false;
    notifyListeners();
  }

  Future<void> fetchUnreadCount() async {
    try {
      unreadCount = await _repo.getUnreadCount();
      notifyListeners();
    } catch (_) {}
  }

  /// Mark as read rồi emit navigation intent
  Future<void> tapNotification(NotificationModel notif) async {
    if (!notif.isRead) {
      await markAsRead(notif.id);
    }
    // Xác định loại navigate
    if (notif.postId != null && notif.postId!.isNotEmpty) {
      pendingNav = NotifNavIntent(NotifNavType.post, notif.postId);
    } else if (notif.locketId != null && notif.locketId!.isNotEmpty) {
      pendingNav = NotifNavIntent(NotifNavType.locket, notif.locketId);
    } else {
      pendingNav = const NotifNavIntent(NotifNavType.none, null);
    }
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
    notifications = notifications
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    if (unreadCount > 0) unreadCount--;
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    await _repo.markAllAsRead();
    notifications = notifications.map((n) => n.copyWith(isRead: true)).toList();
    unreadCount = 0;
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    await _repo.deleteNotification(id);
    final removed = notifications.firstWhere((n) => n.id == id, orElse: () => notifications.first);
    if (!removed.isRead && unreadCount > 0) unreadCount--;
    notifications = notifications.where((n) => n.id != id).toList();
    notifyListeners();
  }

  Future<void> deleteAll() async {
    await _repo.deleteAll();
    notifications = [];
    unreadCount = 0;
    notifyListeners();
  }
}
