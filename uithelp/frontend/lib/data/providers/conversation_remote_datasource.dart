import 'package:dio/dio.dart';
import '../../../core/constants/dio_client.dart';

class ConversationRemoteDatasource {
  final Dio _dio = DioClient().dio;

  Future<List<dynamic>> getConversations() async {
    final res = await _dio.get('/conversations');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getOrCreateConversation(String targetUserId) async {
    final res = await _dio.post('/conversations', data: {'targetUserId': targetUserId});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMessages(String convId, {String? cursor}) async {
    final res = await _dio.get(
      '/conversations/$convId/messages',
      queryParameters: cursor != null ? {'cursor': cursor} : null,
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendMessage(String convId, String content) async {
    final res = await _dio.post(
      '/conversations/$convId/messages',
      data: {'content': content, 'type': 'text'},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<void> markRead(String convId) async {
    await _dio.patch('/conversations/$convId/read');
  }

  Future<void> deleteMessage(String convId, String msgId) async {
    await _dio.delete('/conversations/$convId/messages/$msgId');
  }

  Future<Map<String, dynamic>> getUserById(String userId) async {
    final res = await _dio.get('/auth/users/$userId');
    return res.data as Map<String, dynamic>;
  }
}
