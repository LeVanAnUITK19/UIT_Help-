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
import '../../../features/views/auth/login_page.dart';

class VerifyOtpRegisterPage extends StatefulWidget {
  final String email;
  const VerifyOtpRegisterPage({super.key, required this.email});

  @override
  State<VerifyOtpRegisterPage> createState() => _VerifyOtpRegisterPageState();
}

class _VerifyOtpRegisterPageState extends State<VerifyOtpRegisterPage> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
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

  void _resend() {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: AuthCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LogoHeader(),
                      const SizedBox(height: 24),
                      RichText(
                        text: TextSpan(
                          style: isDark
                              ? AppTextStyles.appSubtitleDark.copyWith(
                                  fontSize: 14,
                                )
                              : AppTextStyles.appSubtitleLight.copyWith(
                                  fontSize: 14,
                                ),
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
                        textAlign: TextAlign.center,
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
                      AppButton(
                        label: 'Xác thực',
                        onPressed: _handleVerifyRegisterOtp,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Quay lại Đăng nhập'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleVerifyRegisterOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<AuthViewModel>();
    final success = await vm.verifyRegisterOtp(
      widget.email,
      _otpController.text,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Xác thực thành công",
            style: TextStyle(color: Colors.green),
          ),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(vm.errorMessage ?? 'Lỗi')));
    }
  }
}
