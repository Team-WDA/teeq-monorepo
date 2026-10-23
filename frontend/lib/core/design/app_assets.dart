/// 번들 에셋 경로. 경로 문자열은 이 파일에서만 정의한다.
abstract final class AppAssets {
  static const String _icons = 'assets/icons';
  static const String _images = 'assets/images';

  static const String arrowBackIcon = '$_icons/arrow_back.svg';
  static const String checkIcon = '$_icons/check.svg';
  static const String closeIcon = '$_icons/close.svg';
  static const String sparkleIcon = '$_icons/sparkle.svg';
  static const String appleLogoIcon = '$_icons/apple_logo.svg';
  static const String googleLogoIcon = '$_icons/google_logo.svg';
  static const String profileSoftLimeIcon = '$_icons/profile_soft_lime.png';
  static const String heartSoftLimeIcon = '$_icons/heart_soft_lime.png';
  static const String sparklesSoftLimeIcon = '$_icons/sparkles_soft_lime.png';
  static const String stageInProgressRingIcon =
      '$_icons/stage_in_progress_ring.png';

  // 홈·마이 화면 아이콘. SVG는 단색이라 ColorFilter로 색을 바꾸고, wandIcon만 색이 고정된 PNG다.
  static const String homeTabIcon = '$_icons/home_tab.svg';
  static const String myTabIcon = '$_icons/my_tab.svg';
  static const String callIcon = '$_icons/call.svg';
  static const String wandIcon = '$_icons/wand.png';
  static const String mailIcon = '$_icons/mail.svg';
  static const String lockIcon = '$_icons/lock.svg';
  static const String documentIcon = '$_icons/document.svg';
  static const String chevronRightIcon = '$_icons/chevron_right.svg';
  static const String pencilIcon = '$_icons/pencil.svg';

  static const String glowSmall = '$_images/welcome_glow_small.svg';
  static const String glowMedium = '$_images/welcome_glow_medium.svg';
  static const String glowLarge = '$_images/welcome_glow_large.svg';
  static const String glowIntroductionTop =
      '$_images/introduction_glow_top.png';
  static const String glowIntroductionBottom =
      '$_images/introduction_glow_bottom.png';

  static const String teeqCharactersIllustration =
      '$_images/teeq_characters.png';

  // 캐릭터 생성 단계별 구체 일러스트.
  static const String generationOrbStageOne =
      '$_images/generation_orb_stage_one.png';
  static const String generationOrbStageTwo =
      '$_images/generation_orb_stage_two.png';
  static const String generationOrbStageThree =
      '$_images/generation_orb_stage_three.png';

  // 캐릭터 생성 흐름의 캐릭터 일러스트. characterWelcome은 이미 최종 방향이라 화면에서 회전하지 않는다.
  static const String characterNaming = '$_images/character_naming.png';
  static const String characterWelcome = '$_images/character_welcome.png';
  static const String characterEditPrompt =
      '$_images/character_edit_prompt.png';
  static const String characterEditResult =
      '$_images/character_edit_result.png';

  // 캐릭터 생성 흐름의 빛 번짐. 블러 번짐 영역까지 포함한 이미지다.
  static const String glowGeneration = '$_images/glow_generation.png';
  static const String glowNaming = '$_images/glow_naming.png';
  static const String glowWelcome = '$_images/glow_welcome.png';
  static const String glowEdit = '$_images/glow_edit.png';

  // 홈·마이 화면 이미지. 홈 빛 번짐은 캐릭터 수정 결과 화면의 빛 번짐과 같은 원본이라 그 이미지를 쓴다.
  static const String brandLogo = '$_images/brand_logo.svg';
  static const String defaultAvatarIllustration =
      '$_images/default_avatar_illustration.png';
  static const String homeCharacterWink = '$_images/home_character_wink.png';
  static const String glowHome = glowEdit;

  // 피드백 플로우 마스코트와 빛 번짐. 확정 전 임시 에셋이다.
  static const String teeqBunnyWink = '$_images/teeq_bunny_wink.png';
  static const String teeqBunnyJoyfulJump =
      '$_images/teeq_bunny_joyful_jump.png';
  static const String teeqBunnyCelebration =
      '$_images/teeq_bunny_celebration.png';
  static const String feedbackGlowEllipse =
      '$_images/feedback_glow_ellipse.png';
  static const String closingGlow = '$_images/closing_glow.png';

  // 피드백 플로우 아이콘.
  static const String feedbackStarFilledIcon =
      '$_icons/feedback_star_filled.svg';
  static const String feedbackStarEmptyIcon = '$_icons/feedback_star_empty.svg';
  static const String outlineConversationIcon =
      '$_icons/outline_conversation.svg';
  static const String outlineHeartIcon = '$_icons/outline_heart.svg';
  static const String outlineClockIcon = '$_icons/outline_clock.svg';
  static const String outlineSparkleIcon = '$_icons/outline_sparkle.svg';
  static const String radioCircleIcon = '$_icons/radio_circle.svg';
  static const String radioCircleCheckedIcon =
      '$_icons/radio_circle_checked.svg';
}
