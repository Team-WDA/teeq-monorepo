import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_text_styles.dart';

void main() {
  // 이름 → (스타일, 글자 크기, 굵기, 줄 높이 px)
  const styleSpecifications = <String, (TextStyle, double, FontWeight, double)>{
    'display32Bold': (AppTextStyles.display32Bold, 32, FontWeight.w700, 42),
    'title24Bold': (AppTextStyles.title24Bold, 24, FontWeight.w700, 32),
    'heading20Bold': (AppTextStyles.heading20Bold, 20, FontWeight.w700, 28),
    'body16Bold': (AppTextStyles.body16Bold, 16, FontWeight.w700, 22),
    'body16SemiBold': (AppTextStyles.body16SemiBold, 16, FontWeight.w600, 22),
    'body16SemiBoldMultiline': (
      AppTextStyles.body16SemiBoldMultiline,
      16,
      FontWeight.w600,
      24,
    ),
    'body16Medium': (AppTextStyles.body16Medium, 16, FontWeight.w500, 22),
    'body14Bold': (AppTextStyles.body14Bold, 14, FontWeight.w700, 20),
    'body14SemiBold': (AppTextStyles.body14SemiBold, 14, FontWeight.w600, 20),
    'body14SemiBoldMultiline': (
      AppTextStyles.body14SemiBoldMultiline,
      14,
      FontWeight.w600,
      22,
    ),
    'body14Medium': (AppTextStyles.body14Medium, 14, FontWeight.w500, 20),
    'body14MediumMultiline': (
      AppTextStyles.body14MediumMultiline,
      14,
      FontWeight.w500,
      22,
    ),
    'caption12SemiBold': (
      AppTextStyles.caption12SemiBold,
      12,
      FontWeight.w600,
      16,
    ),
    'caption12SemiBoldMultiline': (
      AppTextStyles.caption12SemiBoldMultiline,
      12,
      FontWeight.w600,
      18,
    ),
    'caption12Medium': (AppTextStyles.caption12Medium, 12, FontWeight.w500, 16),
    'caption10Medium': (AppTextStyles.caption10Medium, 10, FontWeight.w500, 14),
    'caption10SemiBold': (
      AppTextStyles.caption10SemiBold,
      10,
      FontWeight.w600,
      14,
    ),
    'title28Bold': (AppTextStyles.title28Bold, 28, FontWeight.w700, 38),
    'body16BoldMultiline': (
      AppTextStyles.body16BoldMultiline,
      16,
      FontWeight.w700,
      24,
    ),
    'body16RegularMultiline': (
      AppTextStyles.body16RegularMultiline,
      16,
      FontWeight.w400,
      24,
    ),
    'body14RegularMultiline': (
      AppTextStyles.body14RegularMultiline,
      14,
      FontWeight.w400,
      22,
    ),
    'caption12MediumMultiline': (
      AppTextStyles.caption12MediumMultiline,
      12,
      FontWeight.w500,
      18,
    ),
    'caption12RegularMultiline': (
      AppTextStyles.caption12RegularMultiline,
      12,
      FontWeight.w400,
      18,
    ),
  };

  styleSpecifications.forEach((name, specification) {
    final (style, fontSize, fontWeight, lineHeightPixels) = specification;

    test('$name 스타일은 크기·굵기·줄 높이 px·자간·색을 따른다', () {
      expect(style.fontFamily, 'Pretendard');
      expect(style.fontSize, fontSize);
      expect(style.fontWeight, fontWeight);
      expect(style.height! * fontSize, closeTo(lineHeightPixels, 1e-9));
      expect(style.letterSpacing, closeTo(fontSize * -0.012, 1e-9));
      expect(style.color, AppColors.textPrimary);
    });
  });

  const singleAndMultilinePairs = <(String, TextStyle, TextStyle)>[
    (
      'body16SemiBold',
      AppTextStyles.body16SemiBold,
      AppTextStyles.body16SemiBoldMultiline,
    ),
    (
      'body14SemiBold',
      AppTextStyles.body14SemiBold,
      AppTextStyles.body14SemiBoldMultiline,
    ),
    (
      'caption12SemiBold',
      AppTextStyles.caption12SemiBold,
      AppTextStyles.caption12SemiBoldMultiline,
    ),
  ];

  for (final (name, single, multiline) in singleAndMultilinePairs) {
    test('$name 한 줄용과 여러 줄용은 크기·굵기가 같고 줄 높이만 다르다', () {
      expect(multiline.fontSize, single.fontSize);
      expect(multiline.fontWeight, single.fontWeight);
      expect(multiline.height, greaterThan(single.height!));
    });
  }

  test('monospace12Regular는 고정폭 글꼴이고 공통 자간 규칙에서 제외된다', () {
    const style = AppTextStyles.monospace12Regular;

    expect(style.fontFamily, 'Menlo');
    expect(style.fontFamilyFallback, ['monospace', 'Courier']);
    expect(style.fontSize, 12);
    expect(style.fontWeight, FontWeight.w400);
    expect(style.height! * 12, closeTo(18, 1e-9));
    expect(style.letterSpacing, isNull);
    expect(style.color, AppColors.textPrimary);
  });
}
