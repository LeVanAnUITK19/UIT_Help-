import 'package:flutter/material.dart';
import '../../data/models/comment_model.dart';
import '../../data/repositories/comment_repository.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class CommentViewModel extends ChangeNotifier {
  IO.Socket? _socket;
  final CommentRepository _repo;
  CommentViewModel(this._repo);

  final Map<String, List<CommentModel>> _commentsByPost = {};
  final Map<String, String?> _cursors = {};
  final Map<String, bool> _hasMore = {};

  bool isLoading = false;
  bool isSending = false;
  String? errorMessage;

  List<CommentModel> commentsFor(String postId) =>
      _commentsByPost[postId] ?? [];
  bool hasMoreFor(String postId) => _hasMore[postId] ?? true;

  Future<void> loadComments(String postId, {bool refresh = false}) async {
    if (refresh) {
      _commentsByPost[postId] = [];
      _cursors[postId] = null;
      _hasMore[postId] = true;
    }
    if (!(_hasMore[postId] ?? true)) return;

    isLoading = true;
    notifyListeners();

    final result = await _repo.getComments(postId, cursor: _cursors[postId]);
    isLoading = false;

    if (result.failure != null) {
      errorMessage = result.failure!.message;
    } else {
      final existing = _commentsByPost[postId] ?? [];
      // backend returns newest first, we want oldest first for display
      final incoming = result.data!.comments.reversed.toList();
      _commentsByPost[postId] = refresh ? incoming : [...incoming, ...existing];
      _cursors[postId] = result.data!.nextCursor;
      _hasMore[postId] = result.data!.nextCursor != null;
    }
    notifyListeners();
  }

  Future<bool> sendComment(String postId, String content) async {
    isSending = true;
    notifyListeners();
    final result = await _repo.createComment(postId, content);
    isSending = false;
    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return false;
    }
    final list = _commentsByPost[postId] ?? [];
    _commentsByPost[postId] = [...list, result.data!];
    notifyListeners();
    return true;
  }

  Future<bool> deleteComment(String postId, String commentId) async {
    final result = await _repo.deleteComment(commentId);
    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return false;
    }
    _commentsByPost[postId] = (_commentsByPost[postId] ?? [])
        .where((c) => c.id != commentId)
        .toList();
    notifyListeners();
    return true;
  }
  //Xử lý socket
  void connectSocket(String postId) {
    _socket = IO.io('http://localhost:3000', {
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _socket!.onConnect((_) {
      _socket!.emit('join_post', postId); // emit sau khi đã connected
    });
    _socket!.on('new_comment', (data) {
      final comment = CommentModel.fromJson(data);
      final list = _commentsByPost[postId] ?? [];
      if (list.any((c) => c.id == comment.id)) return;
      _commentsByPost[postId] = [...list, comment];
      notifyListeners();
    });
    _socket!.connect();
  }

  void disconnectSocket(String postId) {
    _socket?.emit('leave_post', postId);
    _socket?.disconnect();
    _socket = null;
  }
}
