import 'package:flutter/painting.dart';

/// 디자인 토큰: 모서리 반경.
abstract final class AppRadius {
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 24;

  static const BorderRadius borderRadiusSm = BorderRadius.all(
    Radius.circular(radiusSm),
  );
  static const BorderRadius borderRadiusMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );
  static const BorderRadius borderRadiusLg = BorderRadius.all(
    Radius.circular(radiusLg),
  );
}
