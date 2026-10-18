/// 번들 에셋 경로. 경로 문자열은 이 파일에서만 정의한다.
abstract final class AppAssets {
  static const String _icons = 'assets/icons';
  static const String _images = 'assets/images';

  static const String arrowBackIcon = '$_icons/arrow_back.svg';
  static const String checkIcon = '$_icons/check.svg';
  static const String closeIcon = '$_icons/close.svg';
  static const String sparkleIcon = '$_icons/sparkle.svg';
  static const String appleLogoIcon = '$_icons/apple_logo.svg';
  static const String profileSoftLimeIcon = '$_icons/profile_soft_lime.png';
  static const String heartSoftLimeIcon = '$_icons/heart_soft_lime.png';
  static const String sparklesSoftLimeIcon = '$_icons/sparkles_soft_lime.png';
  static const String stageInProgressRingIcon =
      '$_icons/stage_in_progress_ring.png';

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
}
