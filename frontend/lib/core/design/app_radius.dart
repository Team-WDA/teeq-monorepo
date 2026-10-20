import 'package:flutter/painting.dart';

/// 디자인 토큰: 모서리 반경.
abstract final class AppRadius {
  static const double radiusHandle = 2;
  static const double radiusXs = 6;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusChip = 16;
  static const double radiusLg = 24;

  static const BorderRadius borderRadiusHandle = BorderRadius.all(
    Radius.circular(radiusHandle),
  );
  static const BorderRadius borderRadiusXs = BorderRadius.all(
    Radius.circular(radiusXs),
  );
  static const BorderRadius borderRadiusSm = BorderRadius.all(
    Radius.circular(radiusSm),
  );
  static const BorderRadius borderRadiusMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );
  static const BorderRadius borderRadiusChip = BorderRadius.all(
    Radius.circular(radiusChip),
  );
  static const BorderRadius borderRadiusLg = BorderRadius.all(
    Radius.circular(radiusLg),
  );
}
