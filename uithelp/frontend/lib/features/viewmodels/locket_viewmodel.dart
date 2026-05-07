import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../data/models/locket_model.dart';
import '../../data/repositories/locket_repository.dart';

class LocketViewModel extends ChangeNotifier {
  final LocketRepository _repo;
  LocketViewModel(this._repo);

  // ── Feed lockets ──────────────────────────────────────────────────────────
  List<LocketModel> lockets = [];
  String? _nextCursor;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  String? errorMessage;

  Future<void> loadLockets({bool refresh = false}) async {
    if (refresh) {
      lockets = [];
      _nextCursor = null;
      hasMore = true;
    }
    if (!hasMore) return;
    refresh ? isLoading = true : isLoadingMore = true;
    notifyListeners();

    final result = await _repo.getLockets(cursor: _nextCursor);
    isLoading = false;
    isLoadingMore = false;

    if (result.failure != null) {
      errorMessage = result.failure!.message;
    } else {
      lockets = refresh
          ? result.data!.lockets
          : [...lockets, ...result.data!.lockets];
      _nextCursor = result.data!.nextCursor;
      hasMore = _nextCursor != null;
    }
    notifyListeners();
  }

  // ── My lockets ────────────────────────────────────────────────────────────
  List<LocketModel> myLockets = [];
  String? _myNextCursor;
  bool isLoadingMy = false;
  bool hasMoreMy = true;

  Future<void> loadMyLockets({bool refresh = false}) async {
    if (refresh) {
      myLockets = [];
      _myNextCursor = null;
      hasMoreMy = true;
    }
    if (!hasMoreMy) return;
    isLoadingMy = true;
    notifyListeners();

    final result = await _repo.getMyLockets(cursor: _myNextCursor);
    isLoadingMy = false;

    if (result.failure != null) {
      errorMessage = result.failure!.message;
    } else {
      myLockets = refresh
          ? result.data!.lockets
          : [...myLockets, ...result.data!.lockets];
      _myNextCursor = result.data!.nextCursor;
      hasMoreMy = _myNextCursor != null;
    }
    notifyListeners();
  }

  // ── Create ────────────────────────────────────────────────────────────────
  bool isCreating = false;

  Future<bool> createLocket(FormData formData) async {
    isCreating = true;
    notifyListeners();
    final result = await _repo.createLocket(formData);
    isCreating = false;
    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return false;
    }
    lockets = [result.data!, ...lockets];
    myLockets = [result.data!, ...myLockets];
    notifyListeners();
    return true;
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<bool> deleteLocket(String id) async {
    final result = await _repo.deleteLocket(id);
    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return false;
    }
    lockets = lockets.where((l) => l.id != id).toList();
    myLockets = myLockets.where((l) => l.id != id).toList();
    notifyListeners();
    return true;
  }

  // ── Reactions ─────────────────────────────────────────────────────────────
  Map<String, List<LocketReactionModel>> _reactions = {};

  List<LocketReactionModel> reactionsFor(String locketId) =>
      _reactions[locketId] ?? [];

  bool isLoadingReactions = false;

  // Track which lockets the current user has reacted to (locketId -> type)
  final Map<String, String?> _myReactions = {};

  String? myReactionFor(String locketId) => _myReactions[locketId];

  Future<void> reactLocket(String locketId, String type) async {
    final wasReacted = _myReactions[locketId] == type;
    final result = await _repo.reactLocket(locketId, type);
    if (result.failure != null) return;

    // Toggle: nếu cùng type thì bỏ, khác type thì đổi
    final delta = wasReacted ? -1 : (_myReactions[locketId] == null ? 1 : 0);
    _myReactions[locketId] = wasReacted ? null : type;

    _updateReactionCount(lockets, locketId, delta);
    _updateReactionCount(myLockets, locketId, delta);
    notifyListeners();
  }

  void _updateReactionCount(List<LocketModel> list, String locketId, int delta) {
    final idx = list.indexWhere((l) => l.id == locketId);
    if (idx == -1) return;
    final old = list[idx];
    list[idx] = LocketModel(
      id: old.id,
      userId: old.userId,
      userName: old.userName,
      imageUrl: old.imageUrl,
      caption: old.caption,
      reactionsCount: (old.reactionsCount + delta).clamp(0, 999999),
      createdAt: old.createdAt,
    );
  }

  Future<void> loadReactions(String locketId) async {
    isLoadingReactions = true;
    notifyListeners();
    final result = await _repo.getReactions(locketId);
    isLoadingReactions = false;
    if (result.failure == null) {
      _reactions[locketId] = result.data!;
    }
    notifyListeners();
  }

  // ── Comments ──────────────────────────────────────────────────────────────
  Map<String, List<LocketCommentModel>> _comments = {};

  List<LocketCommentModel> commentsFor(String locketId) =>
      _comments[locketId] ?? [];

  bool isLoadingComments = false;
  bool isSendingComment = false;

  Future<void> loadComments(String locketId) async {
    isLoadingComments = true;
    notifyListeners();
    final result = await _repo.getComments(locketId);
    isLoadingComments = false;
    if (result.failure == null) {
      _comments[locketId] = result.data!;
    }
    notifyListeners();
  }

  Future<bool> addComment(String locketId, String content) async {
    isSendingComment = true;
    notifyListeners();
    final result = await _repo.addComment(locketId, content);
    isSendingComment = false;
    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return false;
    }
    await loadComments(locketId);
    return true;
  }
}
