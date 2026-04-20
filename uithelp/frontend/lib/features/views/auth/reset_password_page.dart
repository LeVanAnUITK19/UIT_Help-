import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/auth_background.dart';
import '../../../widgets/auth_card.dart';
import '../../../widgets/logo_header.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/app_button.dart';
import '../../../features/viewmodels/auth_viewmodel.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<AuthViewModel>();
    final success = await vm.resetPassword(_newPasswordController.text);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi mật khẩu thành công')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Lỗi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      const SizedBox(height: 28),
                      AppTextField(
                        hint: 'Mật khẩu mới',
                        isPassword: true,
                        controller: _newPasswordController,
                        validator: (v) =>
                            (v == null || v.length < 6) ? 'Tối thiểu 6 ký tự' : null,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        hint: 'Xác nhận mật khẩu mới',
                        isPassword: true,
                        controller: _confirmController,
                        validator: (v) => v != _newPasswordController.text
                            ? 'Mật khẩu không khớp'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      Consumer<AuthViewModel>(
                        builder: (_, vm, __) => AppButton(
                          label: vm.isLoading ? 'Đang xử lý...' : 'Tạo mật khẩu',
                          onPressed: vm.isLoading ? null : _handleReset,
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
