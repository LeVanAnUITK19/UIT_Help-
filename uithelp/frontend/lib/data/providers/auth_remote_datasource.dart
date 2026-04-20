import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';

class AuthRemoteDatasource {
  final Dio _dio; // inject DioClient().dio

  AuthRemoteDatasource(this._dio);

  // Trả về email để navigate sang OTP page
  Future<String> register(
    String mssv,
    String name,
    String password,
    String confirm,
  ) async {
    // backend tự append @gm.uit.edu.vn nếu thiếu
    final res = await _dio.post(
      Api.register,
      data: {
        'mssv': mssv,
        'name': name,
        'password': password,
        'confirmPassword': confirm,
      },
    );
    return '$mssv@gm.uit.edu.vn';
  }

  Future<Map<String, dynamic>> login(String mssv, String password) async {
    final res = await _dio.post(
      Api.login,
      data: {'mssv': mssv, 'password': password},
    );
    return res.data; // { accessToken, user: {...} }
  }

  Future<void> logout() async {
    await _dio.post(Api.logout);
  }

  Future<void> forgotPassword(String mssv) async {
    await _dio.post(Api.forgotPassword, data: {'mssv': mssv});
  }

  Future<String> verifyForgotOtp(String email, String otp) async {
    final res = await _dio.post(
      Api.verifyForgotOtp,
      data: {'email': email, 'otp': otp},
    );
    return res.data['resetToken'] as String;
  }

  Future<void> verifyRegisterOtp(String email, String otp) async {
    await _dio.post(
      Api.verifyRegisterOtp,
      data: {'email': email, 'otp': otp},
    );
  }

  Future<void> resetPassword(String resetToken, String newPassword) async {
    await _dio.post(
      Api.resetPassword,
      data: {'resetToken': resetToken, 'newPassword': newPassword},
    );
  }
}
