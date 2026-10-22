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
  static const double stepProgressBarHeight = 5.246;
  static const double stepProgressBarHorizontalInset = 30.56;
  static const double stageIndicatorDotSize = 10;
  static const double stageConnectorThickness = 2;
  static const double generationGlowSize = 349;
  static const double maxTextScaleFactor = 1.2;

  // 피드백 위젯. Figma 393폭 프레임 기준 값이다.
  static const double feedbackChoiceHeight = 44;
  static const double memoryNotApplicableRowHeight = 44;
  static const double feedbackStarSize = 32;
  static const double feedbackStarDisplaySize = 20;
  static const double feedbackStarDisplayGap = 4;
  static const double feedbackReasonInputHeight = 66;
  static const double startReasonRowHeight = 32;
  static const double summaryRowHeight = 32;
  static const double summaryValueWidth = 116;

  // 통화 마무리·필수 피드백 시트·피드백 완료·상세 초대 시트. Figma 393폭 프레임 기준 값이다.
  static const double closingMascotWidth = 271;
  static const double closingMascotTopOffset = 217;
  static const double closingMascotToTitleGap = 35;
  static const double closingGlowSize = 674.4;
  // 마스코트 위쪽 가장자리에서 빛 번짐 중심까지의 세로 거리 146.5를 빛 번짐 위쪽 위치로 바꾼 값이다.
  static const double closingGlowTopOffset = 146.5 - closingGlowSize / 2;
  static const double completionMascotSize = 265;
  static const double completionMascotTopOffset = 78;
  static const double requiredSheetTopOffset = 134;
  static const double requiredSheetContentTopInset = 30;
  static const double requiredSheetMascotWidth = 84;
  static const double invitationSheetHeight = 474;
  static const double invitationSheetHorizontalInset = 36;
  static const double invitationSheetTopInset = 48;
  // 장식 영역은 본문 폭(345) 기준이며 폭에 비례해 줄어든다. 아래 버튼과 겹치는 8은 뺀 높이다.
  static const double invitationDecorationHeight = 118;
  static const double invitationMascotWidth = 180;
  static const double invitationMascotOffsetX = 180;
  static const double invitationMascotOffsetY = 8;
  static const double invitationGlowWidth = 459.8;
  static const double invitationGlowHeight = 199.8;
  static const double invitationGlowOffsetX = -39.9;
  static const double invitationGlowOffsetY = 47.1;

  // 상세 피드백 화면과 완료 화면. Figma 393폭 프레임 기준 값이다.
  static const double detailedFeedbackHeaderMinHeight = 96;
  static const double detailedFeedbackHeaderTextMaxWidth = 225;
  // 헤더 마스코트 자리("버니 반")는 이미지 없이 크기만 잡아 둔다. 본문 시작선보다 위로 튀어나오는 높이가 56이다.
  static const double detailedFeedbackMascotSlotWidth = 127.75;
  static const double detailedFeedbackMascotSlotHeight = 176;
  static const double detailedFeedbackMascotSlotOverhang = 56;
  static const double detailedCompletionMascotTopOffset = 115;

  // 공용 바텀시트 드래그 핸들. 시트 위쪽 가장자리 기준 값이다.
  static const double sheetHandleWidth = 36;
  static const double sheetHandleHeight = 4;
  static const double sheetHandleTopOffset = 16;

  // 홈·마이 화면. Figma 393폭 프레임 기준 값이다.
  // 탭 바 전체 높이 88에서 홈 인디케이터 영역 34를 뺀 본문 높이다.
  static const double tabBarContentHeight = 54;
  static const double tabBarHorizontalInset = 20;
  static const double greetingCardHeight = 136;
  static const double greetingDotSize = 14;
  static const double brandLogoWidth = 77.255;
  static const double brandLogoHeight = 28.998;
  // 스플래시 화면 중앙에 놓는 브랜드 로고. 네이티브 시작 화면의 로고와 같은 크기다.
  static const double splashLogoWidth = 118;
  static const double splashLogoHeight = 44.294;
  static const double homeCharacterWidth = 297;
  static const double homeCharacterHeight = 255.576;
  static const double homeGlowWidth = editResultGlowWidth;
  static const double homeGlowHeight = editResultGlowHeight;
  // 홈 일러스트 왼쪽 위를 원점으로 한 캐릭터와 빛 번짐의 위치.
  static const double homeCharacterOffsetX = 43;
  static const double homeGlowOffsetX = -174;
  static const double homeGlowOffsetY = -115;
  static const double profileCardHeight = 104;
  static const double avatarSize = 72;
  static const double avatarIllustrationSize = 43.2;
  static const double avatarEditBadgeSize = 28;
  static const double avatarEditIconSize = 16;
  static const double avatarGroupWidth = 76;
  static const double avatarEditBadgeLeft = 48;
  static const double avatarEditBadgeTop = 46;
  static const double settingsSectionLabelHeight = 20;
  static const double settingsRowHeight = 52;
  static const double textButtonHeight = 44;

  // 닉네임 변경 화면. Figma 393폭 프레임 기준 값이다.
  static const double nicknameHelperMascotWidth = 168;
  static const double nicknameHelperBubbleMinHeight = 76;
  // 마스코트 칸과 말풍선 칸의 폭 비율.
  static const int nicknameHelperMascotFlex = 168;
  static const int nicknameHelperBubbleFlex = 177;
  // 빛 번짐 중심의 세로 위치. 헤더 위쪽 가장자리에서 캐릭터·말풍선 줄 중심까지의 거리다.
  static const double nicknameGlowCenterOffsetY = 152;

  // 캐릭터 생성 흐름 일러스트와 빛 번짐 크기. Figma 393폭 프레임 기준 값이다.
  static const double characterNamingIllustrationWidth = 310.275;
  static const double characterNamingIllustrationHeight = 267;
  static const double namingGlowSize = 472;
  static const double welcomeCharacterSize = 552.396;
  static const double welcomeGlowSize = 789.3;
  static const double welcomeCharacterOffsetX = 123.2;
  static const double welcomeCharacterOffsetY = 70.3;
  static const double welcomeGlowOffsetX = 54.5;
  static const double welcomeGlowOffsetY = 73;
  static const double editResultCharacterWidth = 353;
  static const double editResultCharacterHeight = 366.776;
  static const double editResultGlowWidth = 660;
  static const double editResultGlowHeight = 569;
  static const double editResultCharacterOffsetY = 46.4;
  static const double editResultGlowOffsetY = 23.5;
  static const double dialogHorizontalInset = 16;
  static const double dialogIllustrationWidth = 267.494;
  static const double dialogIllustrationHeight = 270;
  static const double dialogCloseIconSize = 24;
  // 좌우 여백 안쪽 본문 폭. 여백 안에 놓이는 장식의 배율 기준이다.
  static const double designContentWidth =
      figmaFrameWidth - 2 * horizontalMargin;
  // 수정 팝업 카드 안쪽 폭. 팝업 좌우 여백과 카드 안쪽 여백을 뺀 값이다.
  static const double dialogContentWidth =
      figmaFrameWidth - 2 * dialogHorizontalInset - 2 * horizontalMargin;

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
