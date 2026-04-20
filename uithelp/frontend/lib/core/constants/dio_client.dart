import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio dio;
  final _storage = const FlutterSecureStorage();

  DioClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: Api.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // thử refresh token
          final refreshed = await _refreshToken();
          if (refreshed) {
            // retry request gốc với token mới
            final token = await _storage.read(key: 'access_token');
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      // backend dùng cookie cho refreshToken nên chỉ cần gọi endpoint
      final response = await Dio().post(
        '${Api.baseUrl}${Api.refresh}',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final newToken = response.data['accessToken'];
      await _storage.write(key: 'access_token', value: newToken);
      return true;
    } catch (_) {
      await _storage.delete(key: 'access_token');
      return false;
    }
  }
}
