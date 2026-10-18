/// 번들 에셋 경로. 경로 문자열은 이 파일에서만 정의한다.
abstract final class AppAssets {
  static const String _icons = 'assets/icons';
  static const String _images = 'assets/images';

  static const String arrowBackIcon = '$_icons/arrow_back.svg';
  static const String checkIcon = '$_icons/check.svg';
  static const String sparkleIcon = '$_icons/sparkle.svg';
  static const String appleLogoIcon = '$_icons/apple_logo.svg';
  static const String profileSoftLimeIcon = '$_icons/profile_soft_lime.png';
  static const String heartSoftLimeIcon = '$_icons/heart_soft_lime.png';
  static const String sparklesSoftLimeIcon = '$_icons/sparkles_soft_lime.png';

  static const String glowSmall = '$_images/welcome_glow_small.svg';
  static const String glowMedium = '$_images/welcome_glow_medium.svg';
  static const String glowLarge = '$_images/welcome_glow_large.svg';
  static const String glowIntroductionTop =
      '$_images/introduction_glow_top.png';
  static const String glowIntroductionBottom =
      '$_images/introduction_glow_bottom.png';

  static const String teeqCharactersIllustration =
      '$_images/teeq_characters.png';
}
