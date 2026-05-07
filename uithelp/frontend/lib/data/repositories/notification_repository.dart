import '../models/notification_model.dart';
import '../providers/notification_remote_datasource.dart';

class NotificationRepository {
  final NotificationRemoteDatasource _remote;
  NotificationRepository(this._remote);

  Future<List<NotificationModel>> getNotifications({int page = 1}) async {
    final raw = await _remote.getNotifications(page: page);
    return raw.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> getUnreadCount() => _remote.getUnreadCount();

  Future<void> markAsRead(String id) => _remote.markAsRead(id);

  Future<void> markAllAsRead() => _remote.markAllAsRead();

  Future<void> deleteNotification(String id) => _remote.deleteNotification(id);

  Future<void> deleteAll() => _remote.deleteAll();
}
