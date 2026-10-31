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
  static const double buttonLoadingIndicatorSize = 20;
  static const double screenLoadingIndicatorSize = 40;
  static const double minimumTapTarget = 48;
  static const double stepCardHeight = 69.4;
  static const double stepProgressBarHeight = 5.246;
  static const double stepProgressBarHorizontalInset = 30.56;
  static const double stageIndicatorDotSize = 10;
  static const double stageConnectorThickness = 2;
  static const double generationGlowSize = 349;
  // 생성 중 화면 구체 영역. 단계별 구체 이미지 세 장 중 가장 큰 폭과 높이다.
  static const double generationOrbWidth = 326;
  static const double generationOrbHeight = 294;
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
  // 정렬된 이미지의 가장 큰 표정 콘텐츠 높이 0.906 × 300 ≈ 272가 인사 카드와 겹치지 않는 최소 영역 높이다.
  static const double homeCharacterHeight = 272;
  // 홈 캐릭터 이미지 정사각형 한 변. Figma 393폭 기준이다.
  static const double homeCharacterIllustrationSize = 300;
  // 홈 캐릭터 콘텐츠의 가로 중심. 옛 left 43 + 보이는 중심 146이다.
  static const double homeCharacterCenterX = 189;
  // 모든 캐릭터 이미지의 바닥 그림자 기준선. 이미지 한 변에 곱한 값이
  // 이미지 맨 위에서 바닥 기준선까지의 거리다.
  static const double characterGroundFraction = 0.9663;
  static const double homeGlowWidth = editResultGlowWidth;
  static const double homeGlowHeight = editResultGlowHeight;
  // 홈 일러스트 왼쪽 위를 원점으로 한 빛 번짐의 위치.
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

  // 버그 제보 화면. 디자인 시안이 없어 기존 입력 상자 비율에 맞춰 정한 값이다.
  static const double bugReportContentMinHeight = 200;
  static const double bugReportAttachmentSize = 88;

  // 닉네임 변경 화면. Figma 393폭 프레임 기준 값이다.
  static const double nicknameHelperMascotWidth = 168;
  static const double nicknameHelperBubbleMinHeight = 76;
  // 마스코트 칸과 말풍선 칸의 폭 비율.
  static const int nicknameHelperMascotFlex = 168;
  static const int nicknameHelperBubbleFlex = 177;
  // 빛 번짐 중심의 세로 위치. 헤더 위쪽 가장자리에서 캐릭터·말풍선 줄 중심까지의 거리다.
  static const double nicknameGlowCenterOffsetY = 152;

  // 캐릭터 생성 흐름 일러스트와 빛 번짐 크기. Figma 393폭 프레임 기준 값이다.
  // 이름 입력 캐릭터 한 변과 바닥 기준선(상자 위쪽 기준). 옛 보이는 바닥 240 × 상자 배율 1.0447에서 환산했다.
  static const double characterNamingIllustrationSize = 310;
  static const double characterNamingBaselineY = 250.7;
  static const double characterNamingIllustrationHeight = 267;
  static const double namingGlowSize = 472;
  static const double welcomeCharacterSize = 500;
  static const double welcomeGlowSize = 789.3;
  // 가입 결과 캐릭터 중심 오프셋. 옛 보이는 영역 중심에 새 콘텐츠 중심·기준선을 맞춰 환산했다.
  static const double welcomeCharacterOffsetX = 104.6;
  static const double welcomeCharacterOffsetY = 24;
  static const double welcomeGlowOffsetX = 54.5;
  static const double welcomeGlowOffsetY = 73;
  // 수정 결과 캐릭터 한 변과 중심 오프셋. 옛 보이는 영역 중심에 새 콘텐츠 중심·기준선을 맞춰 환산했다.
  static const double editResultCharacterSize = 371;
  static const double editResultCharacterOffsetX = 3.5;
  static const double editResultGlowWidth = 660;
  static const double editResultGlowHeight = 569;
  static const double editResultCharacterOffsetY = 17;
  static const double editResultGlowOffsetY = 23.5;
  static const double dialogHorizontalInset = 16;
  static const double dialogIllustrationWidth = 267.494;
  static const double dialogIllustrationHeight = 270;
  // 수정 확인 팝업 캐릭터 한 변과 바닥 기준선(상자 위쪽 기준). 옛 보이는 바닥 244에서 환산했다.
  static const double dialogIllustrationSize = 272;
  static const double dialogCharacterBaselineY = 244;
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

  // 통화 화면. Figma 393폭 프레임 기준 값이다.
  // 배경 캐릭터는 시안 상자(730.6x797, 왼쪽 -69, 위 142)의 가로 중심과 바닥에 맞춘다.
  // 이미지 한 변은 가장 큰 표정 콘텐츠 높이 비율(0.906)로 시안 높이 797을 나눈 값이다.
  static const double callBackgroundCharacterSize = 880;
  static const double callBackgroundCharacterCenterX = 296.3;
  static const double callBackgroundCharacterGroundY = 939;
  static const double callSlideToAnswerHeight = 92;
  static const double callSlideHandleSize = 68;
  static const double callControlButtonSize = 80;
  // 통화 버튼 원 안에서 글리프를 가운데 놓는 상자.
  static const double callControlIconBoxSize = 40;
  // 슬라이더 손잡이 원 안에서 글리프를 가운데 놓는 상자.
  static const double callSlideHandleIconBoxSize = 40;
  // 통화 안내 카드 버튼 높이. 글자 줄 높이 22 + 위아래 여백 16이다.
  static const double callCardButtonHeight = 54;
  static const double callLimitInfoChipHeight = 44;
  // 통화 화면 배치. 시안(393x852) 값에서 위는 상태 표시줄 59, 아래는 홈 인디케이터 34를 뺀
  // 안전 영역 기준 거리다. 뒤로가기는 아이콘(left 16, top 76) 둘레 48 탭 영역의 왼쪽 위다.
  static const double callBackButtonLeftOffset = 4;
  static const double callBackButtonTopOffset = 5;
  static const double callIdentityHeaderTopOffset = 45;
  static const double callSlideToAnswerHorizontalInset = 30;
  static const double callSlideToAnswerBottomOffset = 39;
  static const double callControlsHorizontalInset = 31;
  // 컨트롤 줄 아래쪽(버튼 80 + 간격 12 + 문구 16) 기준이다.
  static const double callControlsBottomOffset = 32;
}
