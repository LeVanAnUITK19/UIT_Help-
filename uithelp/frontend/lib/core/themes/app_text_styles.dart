import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const String fontFamily = 'Roboto';

  // Light
  static const TextStyle appTitleLight = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.uitBlue,
    letterSpacing: 0.3,
  );
  static const TextStyle appSubtitleLight = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.lightTextSecondary,
    letterSpacing: 0.2,
  );
  static const TextStyle bodyLight = TextStyle(
    fontSize: 14,
    color: AppColors.lightTextPrimary,
  );
  static const TextStyle linkLight = TextStyle(
    fontSize: 13,
    color: AppColors.uitBlue,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle hintLight = TextStyle(
    fontSize: 14,
    color: AppColors.lightTextHint,
  );
  static const TextStyle labelLight = TextStyle(
    fontSize: 13,
    color: AppColors.lightTextSecondary,
  );

  // Dark
  static const TextStyle appTitleDark = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.uitBlueAccent,
    letterSpacing: 0.3,
  );
  static const TextStyle appSubtitleDark = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.darkTextSecondary,
    letterSpacing: 0.2,
  );
  static const TextStyle bodyDark = TextStyle(
    fontSize: 14,
    color: AppColors.darkTextPrimary,
  );
  static const TextStyle linkDark = TextStyle(
    fontSize: 13,
    color: AppColors.uitBlueAccent,
    fontWeight: FontWeight.w500,
  );
}
