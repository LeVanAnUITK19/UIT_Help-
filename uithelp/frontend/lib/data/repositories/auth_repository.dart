import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../data/providers/auth_remote_datasource.dart';
import '../../core/constants/token_storage.dart';
import '../../data/models/user_model.dart';
import 'package:dio/dio.dart';

// Dùng record type (Dart 3+) cho gọn
typedef AuthResult<T> = ({T? data, Failure? failure});

class AuthRepository {
  final AuthRemoteDatasource _remote;
  final TokenStorage _tokenStorage;

  AuthRepository(this._remote, this._tokenStorage);

  Future<AuthResult<String>> register(
    String mssv,
    String name,
    String password,
    String confirmPassword,
  ) async {
    try {
      final email = await _remote.register(
        mssv,
        name,
        password,
        confirmPassword,
      );
      return (data: email, failure: null);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Lỗi server';
      return (data: null, failure: ServerFailure(msg));
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<AuthResult<UserModel>> login(String mssv, String password) async {
    try {
      final raw = await _remote.login(mssv, password);
      // lưu token
      await _tokenStorage.saveAccessToken(raw['accessToken']);
      final user = UserModel.fromJson(raw['user']);
      return (data: user, failure: null);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Lỗi server';
      return (data: null, failure: ServerFailure(msg));
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }
  Future<AuthResult<void>> forgetPassword(String mssv) async {
    try{
      await _remote.forgotPassword(mssv);
      return (data: null, failure: null);
    }on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Lỗi server';
      return (data: null, failure: ServerFailure(msg));
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<AuthResult<void>> verifyRegisterOtp(String email, String otp) async {
    try {
      await _remote.verifyRegisterOtp(email, otp);
      return (data: null, failure: null);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Lỗi server';
      return (data: null, failure: ServerFailure(msg));
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<AuthResult<String>> verifyForgotOtp(String email, String otp) async {
    try {
      final resetToken = await _remote.verifyForgotOtp(email, otp);
      return (data: resetToken, failure: null);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Lỗi server';
      return (data: null, failure: ServerFailure(msg));
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }

  Future<AuthResult<void>> resetPassword(String resetToken, String newPassword) async {
    try {
      await _remote.resetPassword(resetToken, newPassword);
      return (data: null, failure: null);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Lỗi server';
      return (data: null, failure: ServerFailure(msg));
    } on Exception {
      return (data: null, failure: const NetworkFailure());
    }
  }
}
