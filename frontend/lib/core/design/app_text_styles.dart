import 'package:flutter/painting.dart';

import 'package:teeq/core/design/app_colors.dart';

/// 디자인 토큰: 글자 스타일.
///
/// 이름은 `{용도}{크기}{굵기}[Multiline]` 규칙을 따른다. 용도는 글자 크기로 정한다
/// (display 40·32, title 28·24, heading 20, body 16·14, caption 12·10).
/// 줄 높이(px)는 한 줄 기준 40→52, 32→42, 28→38, 24→32, 20→28, 16→22, 14→20, 12→16, 10→14이고,
/// 여러 줄이 될 수 있는 설명·도움말·본문·토스트·안내 문구용 `Multiline`은 16→24, 14→22, 12→18이다.
/// 버튼·칩·탭·행 라벨·한 줄 제목·입력창 텍스트는 `Multiline`을 쓰지 않는다.
/// 자간은 모든 스타일에 글자 크기의 -1.2%를 공통 적용한다.
abstract final class AppTextStyles {
  static const String fontFamily = 'Pretendard';
  static const double letterSpacingRatio = -0.012;

  static const TextStyle display32Bold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 42 / 32,
    letterSpacing: 32 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle title24Bold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    letterSpacing: 24 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading20Bold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 28 / 20,
    letterSpacing: 20 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading20Regular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 28 / 20,
    letterSpacing: 20 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading20Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 28 / 20,
    letterSpacing: 20 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle body16Bold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 22 / 16,
    letterSpacing: 16 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle body16SemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 22 / 16,
    letterSpacing: 16 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle body16SemiBoldMultiline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    letterSpacing: 16 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle body16Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 22 / 16,
    letterSpacing: 16 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle body14Bold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 20 / 14,
    letterSpacing: 14 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle body14SemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 14 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle body14SemiBoldMultiline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 22 / 14,
    letterSpacing: 14 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle body14Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    letterSpacing: 14 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle body14MediumMultiline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 22 / 14,
    letterSpacing: 14 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption12SemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 12 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption12SemiBoldMultiline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 18 / 12,
    letterSpacing: 12 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption12Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 12 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption10Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 14 / 10,
    letterSpacing: 10 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption10SemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 14 / 10,
    letterSpacing: 10 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle title28Bold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 38 / 28,
    letterSpacing: 28 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle body16BoldMultiline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 24 / 16,
    letterSpacing: 16 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle body16RegularMultiline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: 16 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle body14RegularMultiline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 22 / 14,
    letterSpacing: 14 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption12MediumMultiline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 18 / 12,
    letterSpacing: 12 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption12RegularMultiline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 18 / 12,
    letterSpacing: 12 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading18Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 26 / 18,
    letterSpacing: 18 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle body14BoldMultiline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 22 / 14,
    letterSpacing: 14 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption12BoldMultiline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 18 / 12,
    letterSpacing: 12 * letterSpacingRatio,
    color: AppColors.textPrimary,
  );

  /// 개발자 콘솔의 로그·본문용 고정폭 글꼴. 글자 폭을 맞추기 위해 Pretendard와
  /// 공통 자간 규칙(-1.2%)에서 제외한다.
  static const TextStyle monospace12Regular = TextStyle(
    fontFamily: 'Menlo',
    fontFamilyFallback: ['monospace', 'Courier'],
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 18 / 12,
    color: AppColors.textPrimary,
  );
}
