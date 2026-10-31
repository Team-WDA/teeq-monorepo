import 'package:flutter/painting.dart';

/// 디자인 토큰: 색상. 라이트 테마 전용이며 위젯에서는 이 값으로만 색을 참조한다.
abstract final class AppColors {
  static const Color background = Color(0xFFFDFDFD);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6C6C6C);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFABABAB);
  static const Color neutralSurface = Color(0xFFD1D1D1);
  static const Color borderSubtle = Color(0xFFECEAE0);
  static const Color accent = Color(0xFFBBFF00);
  static const Color accentStrong = Color(0xFF95CA00);
  static const Color accentSoft = Color(0xFFE7FFA3);
  static const Color accentSurface = Color(0xFFFAFFED);
  static const Color scrim = Color(0x80000000);
  static const Color scrimSoft = Color(0x5C000000);
  static const Color documentCardSurface = Color(0xFFF7F7F5);
  static const Color tabBarBackground = Color(0xFFF7F7F7);
  static const Color destructiveSurface = Color(0xFFFFF6F5);
  static const Color destructiveText = Color(0xFFFF3B30);

  // 통화 화면. 어두운 배경 위에 그리는 색이다.
  // 화면 바탕(시안 프레임 채움이 text-primary 변수라 같은 값이다). 캐릭터 정보를 불러오는 동안에도 보인다.
  static const Color callScreenBackground = Color(0xFF1A1A1A);
  static const Color textOnDarkSubtle = Color(0x80FFFFFF);
  static const Color callBackgroundScrim = Color(0xD92C2C2C);
  static const Color callSlideTrack = Color(0x73D9D9D9);
}
