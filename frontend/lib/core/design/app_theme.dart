import 'package:flutter/material.dart';

import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 앱 전역 테마. 라이트 테마만 제공한다.
abstract final class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    fontFamily: AppTextStyles.fontFamily,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accent,
      onPrimary: AppColors.textPrimary,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      outline: AppColors.borderSubtle,
    ),
    textTheme: const TextTheme(
      displayLarge: AppTextStyles.display,
      headlineMedium: AppTextStyles.heading,
      titleMedium: AppTextStyles.label16,
      titleSmall: AppTextStyles.label14,
      bodyLarge: AppTextStyles.paragraph16,
      bodyMedium: AppTextStyles.paragraph14,
      labelSmall: AppTextStyles.caption12,
    ),
    // 디자인 시안 확정 전 임시: AppButton을 디자이너 컴포넌트 명세로 만들기 전까지 쓰는 Material 버튼 임시 스타일.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textPrimary,
        disabledBackgroundColor: AppColors.disabled,
        disabledForegroundColor: AppColors.textSecondary,
        minimumSize: const Size.fromHeight(AppLayout.buttonHeight),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadiusMd,
        ),
        textStyle: AppTextStyles.label16,
      ),
    ),
  );
}
