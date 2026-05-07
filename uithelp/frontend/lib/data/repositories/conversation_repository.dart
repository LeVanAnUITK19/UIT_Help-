import '../models/conversation_model.dart';
import '../models/user_model.dart';
import '../providers/conversation_remote_datasource.dart';

class ConversationRepository {
  final ConversationRemoteDatasource _remote;
  ConversationRepository(this._remote);

  Future<List<ConversationModel>> getConversations() async {
    final raw = await _remote.getConversations();
    return raw.map((e) => ConversationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ConversationModel> getOrCreateConversation(String targetUserId) async {
    final raw = await _remote.getOrCreateConversation(targetUserId);
    return ConversationModel.fromJson(raw);
  }

  Future<({List<MessageModel> messages, String? nextCursor})> getMessages(
    String convId, {
    String? cursor,
  }) async {
    final raw = await _remote.getMessages(convId, cursor: cursor);
    final msgs = (raw['messages'] as List<dynamic>)
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (messages: msgs, nextCursor: raw['nextCursor'] as String?);
  }

  Future<MessageModel> sendMessage(String convId, String content) async {
    final raw = await _remote.sendMessage(convId, content);
    return MessageModel.fromJson(raw);
  }

  Future<void> markRead(String convId) => _remote.markRead(convId);

  Future<void> deleteMessage(String convId, String msgId) =>
      _remote.deleteMessage(convId, msgId);

  Future<UserModel> getUserById(String userId) async {
    final raw = await _remote.getUserById(userId);
    return UserModel.fromJson(raw);
  }
}
