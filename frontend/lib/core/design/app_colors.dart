import 'package:flutter/painting.dart';

/// 디자인 토큰: 색상. 라이트 테마 전용이며 위젯에서는 이 값으로만 색을 참조한다.
abstract final class AppColors {
  static const Color background = Color(0xFFFDFDFD);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6C6C6C);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFABABAB);
  static const Color disabled = Color(0xFFD1D1D1);
  static const Color borderSubtle = Color(0xFFECEAE0);
  static const Color accent = Color(0xFFBBFF00);
  static const Color accentStrong = Color(0xFF95CA00);
  static const Color accentSoft = Color(0xFFE7FFA3);
  static const Color accentSurface = Color(0xFFFAFFED);
  static const Color scrim = Color(0x80000000);
}
