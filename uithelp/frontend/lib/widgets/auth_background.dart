import 'package:flutter/material.dart';
import '../core/themes/app_theme.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.darkBackground,
                  const Color(0xFF162040),
                  AppColors.darkBackground,
                ]
              : [
                  const Color(0xFFDDE8F5),
                  const Color(0xFFEEF2F7),
                  const Color(0xFFE8F0FA),
                ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}
