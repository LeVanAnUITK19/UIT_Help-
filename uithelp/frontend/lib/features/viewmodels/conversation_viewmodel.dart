import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../data/models/conversation_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../core/constants/api_constants.dart';

class ConversationViewModel extends ChangeNotifier {
  final ConversationRepository _repo;
  ConversationViewModel(this._repo);

  // ── Conversation list ─────────────────────────────────────────────────────
  List<ConversationModel> conversations = [];
  bool isLoadingConvs = false;

  Future<void> loadConversations() async {
    isLoadingConvs = true;
    notifyListeners();
    try {
      conversations = await _repo.getConversations();
    } catch (_) {}
    isLoadingConvs = false;
    notifyListeners();
  }

  Future<ConversationModel?> getOrCreate(String targetUserId) async {
    try {
      final conv = await _repo.getOrCreateConversation(targetUserId);
      // Upsert vào list
      final idx = conversations.indexWhere((c) => c.id == conv.id);
      if (idx == -1) {
        conversations = [conv, ...conversations];
      } else {
        conversations[idx] = conv;
      }
      notifyListeners();
      return conv;
    } catch (_) {
      return null;
    }
  }

  // ── Messages ──────────────────────────────────────────────────────────────
  final Map<String, List<MessageModel>> _messages = {};
  final Map<String, String?> _cursors = {};
  final Map<String, bool> _hasMore = {};
  bool isLoadingMsgs = false;
  bool isSending = false;
  String? errorMessage;

  List<MessageModel> messagesFor(String convId) => _messages[convId] ?? [];

  Future<void> loadMessages(String convId, {bool refresh = false}) async {
    if (refresh) {
      _cursors[convId] = null;
      _hasMore[convId] = true;
      _messages[convId] = [];
    }
    if (_hasMore[convId] == false) return;
    isLoadingMsgs = true;
    notifyListeners();
    try {
      final result = await _repo.getMessages(convId, cursor: _cursors[convId]);
      _messages[convId] = [...(_messages[convId] ?? []), ...result.messages];
      _cursors[convId] = result.nextCursor;
      _hasMore[convId] = result.nextCursor != null;
    } catch (_) {}
    isLoadingMsgs = false;
    notifyListeners();
  }

  Future<bool> sendMessage(String convId, String content) async {
    isSending = true;
    notifyListeners();
    try {
      final msg = await _repo.sendMessage(convId, content);
      _appendMessage(convId, msg);
      _updateConvLastMessage(convId, content);
      isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Gửi thất bại';
      isSending = false;
      notifyListeners();
      return false;
    }
  }

  void _appendMessage(String convId, MessageModel msg) {
    final list = List<MessageModel>.from(_messages[convId] ?? []);
    // Tránh duplicate nếu socket đã thêm trước
    if (!list.any((m) => m.id == msg.id)) list.add(msg);
    _messages[convId] = list;
  }

  void _updateConvLastMessage(String convId, String content) {
    final idx = conversations.indexWhere((c) => c.id == convId);
    if (idx == -1) return;
    final old = conversations[idx];
    conversations[idx] = ConversationModel(
      id: old.id,
      participants: old.participants,
      lastMessage: content,
      lastMessageAt: DateTime.now(),
      unreadCount: old.unreadCount,
    );
    // Đưa conversation lên đầu
    final updated = conversations.removeAt(idx);
    conversations.insert(0, updated);
  }

  Future<void> markRead(String convId, String myId) async {
    try {
      await _repo.markRead(convId);
      final idx = conversations.indexWhere((c) => c.id == convId);
      if (idx != -1) {
        final old = conversations[idx];
        final newCount = Map<String, int>.from(old.unreadCount)..[myId] = 0;
        conversations[idx] = ConversationModel(
          id: old.id,
          participants: old.participants,
          lastMessage: old.lastMessage,
          lastMessageAt: old.lastMessageAt,
          unreadCount: newCount,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> deleteMessage(String convId, String msgId) async {
    try {
      await _repo.deleteMessage(convId, msgId);
      _messages[convId] = (_messages[convId] ?? [])
          .where((m) => m.id != msgId)
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  // ── User profile ──────────────────────────────────────────────────────────
  final Map<String, UserModel> _userCache = {};

  Future<UserModel?> getUserById(String userId) async {
    if (_userCache.containsKey(userId)) return _userCache[userId];
    try {
      final user = await _repo.getUserById(userId);
      _userCache[userId] = user;
      return user;
    } catch (_) {
      return null;
    }
  }

  // ── Socket.io ─────────────────────────────────────────────────────────────
  IO.Socket? _socket;
  String? _activeConvId;

  void connectSocket(String convId, String accessToken) {
    if (_activeConvId == convId && _socket?.connected == true) return;
    disconnectSocket();
    _activeConvId = convId;

    _socket = IO.io(
      Api.baseUrl.replaceAll('/api', ''),
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'Authorization': 'Bearer $accessToken'})
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _socket!.emit('join_conversation', convId);
    });

    _socket!.on('new_message', (data) {
      final msg = MessageModel.fromJson(data as Map<String, dynamic>);
      if (msg.conversationId == convId) {
        _appendMessage(convId, msg);
        _updateConvLastMessage(convId, msg.content);
        notifyListeners();
      }
    });

    _socket!.on('message_deleted', (data) {
      final msgId = (data as Map<String, dynamic>)['messageId'] as String?;
      if (msgId != null) {
        _messages[convId] = (_messages[convId] ?? [])
            .where((m) => m.id != msgId)
            .toList();
        notifyListeners();
      }
    });
  }

  void disconnectSocket() {
    if (_activeConvId != null) {
      _socket?.emit('leave_conversation', _activeConvId);
    }
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _activeConvId = null;
  }

  // Typing state
  bool isTyping = false;
  void emitTyping(String convId, String userId) {
    _socket?.emit('typing', {'conversationId': convId, 'userId': userId});
  }

  void emitStopTyping(String convId, String userId) {
    _socket?.emit('stop_typing', {'conversationId': convId, 'userId': userId});
  }

  @override
  void dispose() {
    disconnectSocket();
    super.dispose();
  }
}
