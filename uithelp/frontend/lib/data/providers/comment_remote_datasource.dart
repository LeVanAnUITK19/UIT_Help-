import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';

class CommentRemoteDatasource {
  final Dio _dio;
  CommentRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> getComments(String postId, {String? cursor}) async {
    final res = await _dio.get(
      Api.getComment(postId),
      queryParameters: cursor != null ? {'cursor': cursor} : null,
    );
    return res.data;
  }

  Future<Map<String, dynamic>> createComment(String postId, String content) async {
    final res = await _dio.post(
      Api.createComment,
      data: {'postId': postId, 'content': content},
    );
    return res.data;
  }

  Future<void> deleteComment(String id) async {
    await _dio.delete(Api.deleteComment(id));
  }
}
