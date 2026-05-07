import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';

class LocketRemoteDatasource {
  final Dio _dio;
  LocketRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> getLockets({String? cursor}) async {
    final res = await _dio.get(
      Api.getLockets,
      queryParameters: cursor != null ? {'cursor': cursor} : null,
    );
    return res.data;
  }

  Future<Map<String, dynamic>> getMyLockets({String? cursor}) async {
    final res = await _dio.get(
      Api.getMyLockets,
      queryParameters: cursor != null ? {'cursor': cursor} : null,
    );
    return res.data;
  }

  Future<Map<String, dynamic>> createLocket(FormData formData) async {
    final res = await _dio.post(
      Api.createLocket,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return res.data;
  }

  Future<void> deleteLocket(String id) async {
    await _dio.delete(Api.deleteLocket(id));
  }

  Future<dynamic> reactLocket(String id, String type) async {
    final res = await _dio.post(Api.reactLocket(id), data: {'type': type});
    return res.data;
  }

  Future<List<dynamic>> getLocketReactions(String id) async {
    final res = await _dio.get(Api.getLocketReactions(id));
    return res.data as List;
  }

  Future<Map<String, dynamic>> commentLocket(String id, String content) async {
    final res = await _dio.post(Api.commentLocket(id), data: {'content': content});
    return res.data;
  }

  Future<List<dynamic>> getLocketComments(String id) async {
    final res = await _dio.get(Api.getLocketComments(id));
    return res.data as List;
  }
}
