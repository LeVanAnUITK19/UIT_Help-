import 'package:dio/dio.dart';
import '../providers/post_remote_datasource.dart';
import '../models/post_model.dart';
import '../../core/errors/failures.dart';

typedef PostResult<T> = ({T? data, Failure? failure});

class PostRepository {
  final PostRemoteDatasource _remote;
  PostRepository(this._remote);

  Future<PostResult<({List<PostModel> posts, String? nextCursor})>> getPosts({String? cursor}) async {
    try {
      final raw = await _remote.getPosts(cursor: cursor);
      final posts = (raw['posts'] as List).map((e) => PostModel.fromJson(e)).toList();
      return (data: (posts: posts, nextCursor: raw['nextCursor'] as String?), failure: null);
    } on DioException catch (e) {
      return (data: null, failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server'));
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<PostResult<({List<PostModel> posts, String? nextCursor})>> getMyPosts({String? cursor}) async {
    try {
      final raw = await _remote.getMyPosts(cursor: cursor);
      final posts = (raw['posts'] as List).map((e) => PostModel.fromJson(e)).toList();
      return (data: (posts: posts, nextCursor: raw['nextCursor'] as String?), failure: null);
    } on DioException catch (e) {
      return (data: null, failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server'));
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<PostResult<PostModel>> createPost(FormData formData) async {
    try {
      final raw = await _remote.createPost(formData);
      return (data: PostModel.fromJson(raw), failure: null);
    } on DioException catch (e) {
      return (data: null, failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server'));
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<PostResult<void>> deletePost(String id) async {
    try {
      await _remote.deletePost(id);
      return (data: null, failure: null);
    } on DioException catch (e) {
      return (data: null, failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server'));
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<PostResult<PostModel>> updatePost(String id, Map<String, dynamic> data) async {
    try {
      final raw = await _remote.updatePost(id, data);
      return (data: PostModel.fromJson(raw), failure: null);
    } on DioException catch (e) {
      return (data: null, failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server'));
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<PostResult<PostModel>> getPostById(String id) async {
    try {
      final raw = await _remote.getPostById(id);
      return (data: PostModel.fromJson(raw), failure: null);
    } on DioException catch (e) {
      return (data: null, failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server'));
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }
}
