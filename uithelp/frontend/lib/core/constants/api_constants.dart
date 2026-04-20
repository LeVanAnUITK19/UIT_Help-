class Api {
  // static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator
  static const String baseUrl = 'http://localhost:3000/api'; // Web/iOS

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String forgotPassword = '/auth/forgetPassword';
  static const String verifyForgotOtp = '/auth/verifyForgotOtp';
  static const String resetPassword = '/auth/resetPassword';
  static const String verifyRegisterOtp = '/auth/verifyRegisterOtp';
}
