import 'package:flutter/material.dart';
import '../core/themes/app_theme.dart';

class LogoHeader extends StatelessWidget {
  const LogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        // UIT Logo SVG-style using CustomPaint
        SizedBox(
          width: 52,
          height: 52,
          child: Image.asset(
            'assets/images/uit_logo.jpg',
            errorBuilder: (_, __, ___) => _buildFallbackLogo(isDark),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UIT Connect',
                style: isDark
                    ? AppTextStyles.appTitleDark
                    : AppTextStyles.appTitleLight,
              ),
              Text(
                '20 năm kết nối -',
                style: isDark
                    ? AppTextStyles.appSubtitleDark
                    : AppTextStyles.appSubtitleLight,
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  '- Ba chạm kết nối',
                  style: isDark
                      ? AppTextStyles.appSubtitleDark
                      : AppTextStyles.appSubtitleLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackLogo(bool isDark) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputFill : AppColors.lightInputFill,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.uitBlueAccent : AppColors.uitBlue,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.school_rounded,
        color: isDark ? AppColors.uitBlueAccent : AppColors.uitBlue,
        size: 28,
      ),
    );
  }
}
