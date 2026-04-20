import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/auth_background.dart';
import '../../../widgets/auth_card.dart';
import '../../../widgets/logo_header.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/app_button.dart';
import '../../../core/themes/app_theme.dart';
import '../../../features/views/auth/register_page.dart';
import '../../../features/views/auth/forget_password_page.dart';
import '../../../features/viewmodels/auth_viewmodel.dart';
import '../../../features/views/home/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _mssvController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _mssvController.dispose();
    _passwordController.dispose();
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
                        hint: 'Mật khẩu',
                        isPassword: true,
                        controller: _passwordController,
                        validator: (v) =>
                            (v == null || v.length < 6) ? 'Tối thiểu 6 ký tự' : null,
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: 'Đăng nhập',
                        onPressed: _handleLogin,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgetPasswordPage(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Quên mật khẩu ?',
                              style: isDark
                                  ? AppTextStyles.linkDark
                                  : AppTextStyles.linkLight,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterPage(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Đăng ký',
                              style: isDark
                                  ? AppTextStyles.linkDark
                                  : AppTextStyles.linkLight,
                            ),
                          ),
                        ],
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<AuthViewModel>();
    final success = await vm.login(
      _mssvController.text,
      _passwordController.text,
    );

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(vm.errorMessage ?? 'Lỗi')));
    }
  }
}
