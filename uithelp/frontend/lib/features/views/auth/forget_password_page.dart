import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/auth_background.dart';
import '../../../widgets/auth_card.dart';
import '../../../widgets/logo_header.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/app_button.dart';
import '../../../core/themes/app_theme.dart';
import '../../../features/viewmodels/auth_viewmodel.dart';
import 'verify_otp_forget_password_page.dart';

class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _mssvController = TextEditingController();

  @override
  void dispose() {
    _mssvController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<AuthViewModel>();
    final success = await vm.forgetPassword(_mssvController.text.trim());

    if (!mounted) return;

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyOtpForgetPasswordPage(
            email: '${_mssvController.text.trim()}@gm.uit.edu.vn',
          ),
        ),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LogoHeader(),
                      const SizedBox(height: 24),
                      Text(
                        'Nhập MSSV để nhận OTP đặt lại mật khẩu',
                        style: (isDark
                                ? AppTextStyles.appSubtitleDark
                                : AppTextStyles.appSubtitleLight)
                            .copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        hint: 'MSSV',
                        controller: _mssvController,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Vui lòng nhập MSSV' : null,
                      ),
                      const SizedBox(height: 20),
                      Consumer<AuthViewModel>(
                        builder: (_, vm, __) => AppButton(
                          label: vm.isLoading ? 'Đang gửi...' : 'Xác nhận',
                          onPressed: vm.isLoading ? null : _handleSubmit,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Quay lại đăng nhập'),
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
}
