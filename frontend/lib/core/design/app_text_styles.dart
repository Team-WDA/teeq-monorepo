import 'package:flutter/painting.dart';

import 'package:teeq/core/design/app_colors.dart';

/// 디자인 토큰: 글자 스타일. 행간 1.4, 자간은 글자 크기의 -1.2%로 모든 스타일에 공통 적용한다.
abstract final class AppTextStyles {
  static const String fontFamily = 'Pretendard';
  static const double lineHeight = 1.4;
  static const double letterSpacingRatio = -0.012;
  // 여러 줄 설명 본문용 행간. 14px 글자에 22px 줄 높이다.
  static const double relaxedLineHeight = 22 / 14;

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: lineHeight,
    letterSpacing: 32 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: lineHeight,
    letterSpacing: 20 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle label16 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: lineHeight,
    letterSpacing: 16 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle label14 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: lineHeight,
    letterSpacing: 14 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle body16Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: lineHeight,
    letterSpacing: 16 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle body14Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: lineHeight,
    letterSpacing: 14 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle body14MediumRelaxed = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: relaxedLineHeight,
    letterSpacing: 14 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle paragraph16 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: lineHeight,
    letterSpacing: 16 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle paragraph14 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: lineHeight,
    letterSpacing: 14 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: lineHeight,
    letterSpacing: 24 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption12Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: lineHeight,
    letterSpacing: 12 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption10Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: lineHeight,
    letterSpacing: 10 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption10 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: lineHeight,
    letterSpacing: 10 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption12 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: lineHeight,
    letterSpacing: 12 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );
}
