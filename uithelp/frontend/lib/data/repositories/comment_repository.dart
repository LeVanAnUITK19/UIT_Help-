import 'package:dio/dio.dart';
import '../providers/comment_remote_datasource.dart';
import '../models/comment_model.dart';
import '../../core/errors/failures.dart';

typedef CommentResult<T> = ({T? data, Failure? failure});

class CommentRepository {
  final CommentRemoteDatasource _remote;
  CommentRepository(this._remote);

  Future<CommentResult<({List<CommentModel> comments, String? nextCursor})>> getComments(
    String postId, {String? cursor}) async {
    try {
      final raw = await _remote.getComments(postId, cursor: cursor);
      final comments = (raw['comments'] as List).map((e) => CommentModel.fromJson(e)).toList();
      return (data: (comments: comments, nextCursor: raw['nextCursor'] as String?), failure: null);
    } on DioException catch (e) {
      return (data: null, failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server'));
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<CommentResult<CommentModel>> createComment(String postId, String content) async {
    try {
      final raw = await _remote.createComment(postId, content);
      return (data: CommentModel.fromJson(raw), failure: null);
    } on DioException catch (e) {
      return (data: null, failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server'));
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<CommentResult<void>> deleteComment(String id) async {
    try {
      await _remote.deleteComment(id);
      return (data: null, failure: null);
    } on DioException catch (e) {
      return (data: null, failure: ServerFailure(e.response?.data['message'] ?? 'Lỗi server'));
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }
}
