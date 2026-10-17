import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_text_styles.dart';

void main() {
  const styleWeights = <String, (TextStyle, double, FontWeight)>{
    'display': (AppTextStyles.display, 32, FontWeight.w700),
    'heading': (AppTextStyles.heading, 20, FontWeight.w700),
    'label16': (AppTextStyles.label16, 16, FontWeight.w700),
    'label14': (AppTextStyles.label14, 14, FontWeight.w700),
    'paragraph16': (AppTextStyles.paragraph16, 16, FontWeight.w600),
    'paragraph14': (AppTextStyles.paragraph14, 14, FontWeight.w600),
    'caption12': (AppTextStyles.caption12, 12, FontWeight.w600),
  };

  styleWeights.forEach((name, expected) {
    final (style, fontSize, fontWeight) = expected;

    test('$name 스타일은 크기·굵기·공통 규칙을 따른다', () {
      expect(style.fontFamily, 'Pretendard');
      expect(style.fontSize, fontSize);
      expect(style.fontWeight, fontWeight);
      expect(style.height, 1.4);
      expect(style.letterSpacing, closeTo(fontSize * -0.012, 1e-9));
      expect(style.color, AppColors.textPrimary);
    });
  });
}
