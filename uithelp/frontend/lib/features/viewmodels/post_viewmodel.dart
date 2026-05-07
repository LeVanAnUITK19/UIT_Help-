import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';

class PostViewModel extends ChangeNotifier {
  final PostRepository _repo;
  PostViewModel(this._repo);

  List<PostModel> posts = [];
  String? _nextCursor;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  String? errorMessage;

  // --- Home feed ---
  Future<void> loadPosts({bool refresh = false}) async {
    if (refresh) {
      posts = [];
      _nextCursor = null;
      hasMore = true;
    }
    if (!hasMore) return;
    if (refresh) {
      isLoading = true;
    } else {
      isLoadingMore = true;
    }
    notifyListeners();

    final result = await _repo.getPosts(cursor: _nextCursor);
    isLoading = false;
    isLoadingMore = false;

    if (result.failure != null) {
      errorMessage = result.failure!.message;
    } else {
      posts = refresh ? result.data!.posts : [...posts, ...result.data!.posts];
      _nextCursor = result.data!.nextCursor;
      hasMore = _nextCursor != null;
    }
    notifyListeners();
  }

  // --- My posts ---
  List<PostModel> myPosts = [];
  String? _myNextCursor;
  bool isLoadingMy = false;
  bool hasMoreMy = true;

  Future<void> loadMyPosts({bool refresh = false}) async {
    if (refresh) {
      myPosts = [];
      _myNextCursor = null;
      hasMoreMy = true;
    }
    if (!hasMoreMy) return;
    isLoadingMy = true;
    notifyListeners();

    final result = await _repo.getMyPosts(cursor: _myNextCursor);
    isLoadingMy = false;

    if (result.failure != null) {
      errorMessage = result.failure!.message;
    } else {
      myPosts = refresh ? result.data!.posts : [...myPosts, ...result.data!.posts];
      _myNextCursor = result.data!.nextCursor;
      hasMoreMy = _myNextCursor != null;
    }
    notifyListeners();
  }

  // --- Create ---
  bool isCreating = false;

  Future<bool> createPost(FormData formData) async {
    isCreating = true;
    notifyListeners();
    final result = await _repo.createPost(formData);
    isCreating = false;
    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return false;
    }
    // prepend to both lists
    posts = [result.data!, ...posts];
    myPosts = [result.data!, ...myPosts];
    notifyListeners();
    return true;
  }

  // --- Delete ---
  Future<bool> deletePost(String id) async {
    final result = await _repo.deletePost(id);
    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return false;
    }
    posts = posts.where((p) => p.id != id).toList();
    myPosts = myPosts.where((p) => p.id != id).toList();
    notifyListeners();
    return true;
  }

  // --- Update status ---
  Future<bool> updateStatus(String id, String status) async {
    final result = await _repo.updatePost(id, {'status': status});
    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return false;
    }
    _replacePost(result.data!);
    notifyListeners();
    return true;
  }

  void _replacePost(PostModel updated) {
    posts = posts.map((p) => p.id == updated.id ? updated : p).toList();
    myPosts = myPosts.map((p) => p.id == updated.id ? updated : p).toList();
  }

  Future<PostModel?> getPostById(String id) async {
    final result = await _repo.getPostById(id);
    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return null;
    }
    return result.data;
  }

  // ID của post cần highlight/scroll đến ở home feed
  String? pendingScrollToPostId;

  void requestScrollToPost(String postId) {
    pendingScrollToPostId = postId;
    notifyListeners();
  }

  void clearPendingScroll() {
    pendingScrollToPostId = null;
  }
}
