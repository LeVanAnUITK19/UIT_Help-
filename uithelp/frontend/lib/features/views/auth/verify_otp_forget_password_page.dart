import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/auth_background.dart';
import '../../../widgets/auth_card.dart';
import '../../../widgets/logo_header.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/app_button.dart';
import '../../../core/themes/app_theme.dart';
import '../../../features/viewmodels/auth_viewmodel.dart';
import 'reset_password_page.dart';

class VerifyOtpForgetPasswordPage extends StatefulWidget {
  final String email;
  const VerifyOtpForgetPasswordPage({super.key, required this.email});

  @override
  State<VerifyOtpForgetPasswordPage> createState() =>
      _VerifyOtpForgetPasswordPageState();
}

class _VerifyOtpForgetPasswordPageState
    extends State<VerifyOtpForgetPasswordPage> {
  final _otpController = TextEditingController();
  int _seconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) {
        t.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _resend() async {
    final vm = context.read<AuthViewModel>();
    // Tách mssv từ email (bỏ @gm.uit.edu.vn)
    final mssv = widget.email.replaceAll('@gm.uit.edu.vn', '');
    await vm.forgetPassword(mssv);
    if (!mounted) return;
    setState(() => _seconds = 60);
    _timer?.cancel();
    _startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập OTP')),
      );
      return;
    }

    final vm = context.read<AuthViewModel>();
    final token = await vm.verifyForgotOtp(widget.email, _otpController.text.trim());

    if (!mounted) return;

    if (token != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Lỗi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: AuthCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LogoHeader(),
                    const SizedBox(height: 24),
                    RichText(
                      text: TextSpan(
                        style: (isDark
                                ? AppTextStyles.appSubtitleDark
                                : AppTextStyles.appSubtitleLight)
                            .copyWith(fontSize: 14),
                        children: [
                          const TextSpan(text: 'OTP gửi về email '),
                          TextSpan(
                            text: widget.email,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.uitBlueAccent
                                  : AppColors.uitBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      hint: '• • • • • •',
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: _seconds > 0
                          ? Text(
                              '$_seconds s',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            )
                          : TextButton(
                              onPressed: _resend,
                              child: const Text('Gửi lại OTP'),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<AuthViewModel>(
                      builder: (_, vm, __) => AppButton(
                        label: vm.isLoading ? 'Đang xử lý...' : 'Xác nhận',
                        onPressed: vm.isLoading ? null : _handleVerify,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Quay lại'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
