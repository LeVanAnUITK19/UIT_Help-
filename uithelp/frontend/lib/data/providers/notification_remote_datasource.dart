import 'package:dio/dio.dart';
import '../../../core/constants/dio_client.dart';

class NotificationRemoteDatasource {
  final Dio _dio = DioClient().dio;

  Future<List<dynamic>> getNotifications({int page = 1, int limit = 20}) async {
    final res = await _dio.get('/notifications', queryParameters: {'page': page, 'limit': limit});
    return res.data as List<dynamic>;
  }

  Future<int> getUnreadCount() async {
    final res = await _dio.get('/notifications/unread-count');
    return (res.data['count'] as num).toInt();
  }

  Future<void> markAsRead(String id) async {
    await _dio.patch('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.patch('/notifications/read-all');
  }

  Future<void> deleteNotification(String id) async {
    await _dio.delete('/notifications/$id');
  }

  Future<void> deleteAll() async {
    await _dio.delete('/notifications');
  }
}
