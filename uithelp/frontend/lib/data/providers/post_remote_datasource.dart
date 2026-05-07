import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';

class PostRemoteDatasource {
  final Dio _dio;
  PostRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> getPosts({String? cursor}) async {
    final res = await _dio.get(
      Api.getPost,
      queryParameters: cursor != null ? {'cursor': cursor} : null,
    );
    return res.data;
  }

  Future<Map<String, dynamic>> getMyPosts({String? cursor}) async {
    final res = await _dio.get(
      Api.getMyPosts,
      queryParameters: cursor != null ? {'cursor': cursor} : null,
    );
    return res.data;
  }

  Future<Map<String, dynamic>> createPost(FormData formData) async {
    final res = await _dio.post(
      Api.createPost,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return res.data;
  }

  Future<void> deletePost(String id) async {
    await _dio.delete(Api.deletePost(id));
  }

  Future<Map<String, dynamic>> updatePost(String id, Map<String, dynamic> data) async {
    final res = await _dio.put(Api.updatePost(id), data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> getPostById(String id) async {
    final res = await _dio.get(Api.getPostById(id));
    return res.data;
  }
}
