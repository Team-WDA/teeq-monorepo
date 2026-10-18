/// 레이아웃 상수: 화면 여백, 거터, 컨트롤 크기, 글자 배율 상한.
abstract final class AppLayout {
  static const double gutter = 20;
  static const double horizontalMargin = 24;
  static const double buttonHeight = 48;
  static const double actionButtonHeight = 52;
  static const double inputFieldHeight = 44;
  static const double outlinedInputHeight = 48;
  static const double hintTagHeight = 32;
  static const double consentRowHeight = 40;
  static const double checkboxSize = 24;
  static const double iconSize = 24;
  static const double smallIconSize = 20;
  static const double minimumTapTarget = 48;
  static const double stepCardHeight = 69.4;
  static const double maxTextScaleFactor = 1.2;

  // 시작 화면 빛 번짐 배치. Figma 393폭 프레임 기준 값이며 일러스트 왼쪽 위를 원점으로 한다.
  static const double figmaFrameWidth = 393;
  static const double glowSmallSize = 114;
  static const double glowMediumSize = 220;
  static const double glowLargeSize = 249;
  static const double glowSmallLeft = 276;
  static const double glowSmallTop = 40;
  static const double glowMediumLeft = -55;
  static const double glowMediumTop = 0;
  static const double glowLargeLeft = 196;
  static const double glowLargeTop = 91;

  // 온보딩 시작 화면 빛 번짐 배치. Figma 393폭 프레임 기준 값이며 본문 왼쪽 위를 원점으로 한다.
  static const double glowIntroductionTopWidth = 473;
  static const double glowIntroductionTopHeight = 490;
  static const double glowIntroductionTopLeft = 73;
  static const double glowIntroductionTopTop = 160;
  static const double glowIntroductionBottomWidth = 503;
  static const double glowIntroductionBottomHeight = 501;
  static const double glowIntroductionBottomLeft = -309;
  static const double glowIntroductionBottomTop = 512;
}
