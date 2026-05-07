import 'package:dio/dio.dart';
import '../constants/token_storage.dart';
import '../constants/api_constants.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final TokenStorage _storage;
  // Dio riêng để gọi refresh, tránh vòng lặp interceptor
  final Dio _refreshDio = Dio();

  AuthInterceptor(this._dio, this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        // không có refresh token → bắt đăng nhập lại
        handler.next(err);
        return;
      }

      try {
        // dùng _refreshDio riêng, không qua interceptor này
        final res = await _refreshDio.post(
          '${Api.baseUrl}${Api.refresh}',
          data: {'refreshToken': refreshToken},
        );
        final newAccess = res.data['accessToken'];
        final newRefresh = res.data['refreshToken'];

        await _storage.saveTokens(newAccess, newRefresh);

        // retry request gốc với token mới
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccess';
        final retryRes = await _dio.fetch(opts);
        handler.resolve(retryRes);
      } catch (_) {
        await _storage.clearAll();
        // navigate về login (dùng global key hoặc event bus)
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
}
