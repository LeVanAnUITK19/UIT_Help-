import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/auth_background.dart';
import '../../../widgets/auth_card.dart';
import '../../../widgets/logo_header.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/app_button.dart';
import '../../../features/viewmodels/auth_viewmodel.dart';
import '../../../features/views/auth/verify_otp_register_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _mssvController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _mssvController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
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
                        hint: 'MSSV',
                        controller: _mssvController,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null) ? 'Vui lòng nhập MSSV' : null,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        hint: 'Họ và tên',
                        controller: _nameController,
                        validator: (v) =>
                            (v == null) ? 'Vui lòng nhập họ tên' : null,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        hint: 'Mật khẩu',
                        isPassword: true,
                        controller: _passwordController,
                        validator: (v) =>
                            (v == null || v.length < 6) ? 'Tối thiểu 6 ký tự' : null,
                      
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        hint: 'Xác nhận mật khẩu',
                        isPassword: true,
                        controller: _confirmController,
                        validator: (v) =>
                            (v == null || v.length < 6) ? 'Tối thiểu 6 ký tự' : null,
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: 'Đăng ký',
                        onPressed: _handleRegister,
                      ),
                      const SizedBox(height: 12),
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<AuthViewModel>();
    final success = await vm.register(
      _mssvController.text,
      _nameController.text,
      _passwordController.text,
      _confirmController.text,
    );

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyOtpRegisterPage(
            email: "${_mssvController.text}@gm.uit.edu.vn",
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(vm.errorMessage ?? 'Lỗi')));
    }
  }
}
