import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';
import 'package:flutter/material.dart';
import '../../core/services/fcm_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repo;

  AuthViewModel(this._repo);

  bool isLoading = false;
  String? errorMessage;
  UserModel? currentUser;

  Future<bool> login(String mssv, String password) async {
    _setLoading(true);
    final result = await _repo.login(mssv, password);
    _setLoading(false);

    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return false;
    }
    currentUser = result.data;
    errorMessage = null;
    notifyListeners();

    // Gửi FCM token lên backend sau khi login thành công
    try {
      final fcmToken = await FcmService.init();
      if (fcmToken != null) {
        await _repo.updateFcmToken(fcmToken);
      }
    } catch (e) {
      debugPrint('[FCM] Token update failed: $e');
    }

    return true;
  }

  Future<bool> register(
    String mssv,
    String name,
    String password,
    String confirmPassword,
  ) async {
    _setLoading(true);
    final result = await _repo.register(mssv, name, password, confirmPassword);
    _setLoading(false);
    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<bool> forgetPassword(String mssv) async {
    _setLoading(true);
    final result = await _repo.forgetPassword(mssv);
    _setLoading(false);
     if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<bool> verifyRegisterOtp(String email, String otp) async {
    _setLoading(true);
    final result = await _repo.verifyRegisterOtp(email, otp);
    _setLoading(false);
    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  // resetToken nhận được sau verifyForgotOtp, dùng cho resetPassword
  String? resetToken;

  Future<String?> verifyForgotOtp(String email, String otp) async {
    _setLoading(true);
    final result = await _repo.verifyForgotOtp(email, otp);
    _setLoading(false);
    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return null;
    }
    resetToken = result.data;
    notifyListeners();
    return resetToken;
  }

  Future<bool> resetPassword(String newPassword) async {
    if (resetToken == null) {
      errorMessage = 'Phiên hết hạn, vui lòng thử lại';
      notifyListeners();
      return false;
    }
    _setLoading(true);
    final result = await _repo.resetPassword(resetToken!, newPassword);
    _setLoading(false);
    if (result.failure != null) {
      errorMessage = result.failure!.message;
      notifyListeners();
      return false;
    }
    resetToken = null;
    notifyListeners();
    return true;
  }

  void _setLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    final result = await _repo.fetchProfile();
    if (result.failure == null && result.data != null) {
      currentUser = result.data;
      notifyListeners();
    }
  }
}
